//
//  RecoverLostSaleManager.swift
//  screenshot
//
//  Created by Jonathan Rose on 6/20/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import CoreData
import MessageUI

protocol RecoverLostSaleManagerDelegate:class {
    func recoverLostSaleManager(_ manager:RecoverLostSaleManager, returnedFrom product:Product, timeSinceLeftApp:TimeInterval)
}

class RecoverLostSaleManager: NSObject, MFMailComposeViewControllerDelegate {
    private var timeLeftApp:Date?
    private var clickOnProductObjectId:NSManagedObjectID?

    weak var delegate:RecoverLostSaleManagerDelegate?
    weak var presentingVC:UIViewController?

    private let maxTime:TimeInterval = 120
    private let minTime:TimeInterval = 5
    private var didTapToDismiss = false
    private var sendAction:UIAlertAction?
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: .UIApplicationDidBecomeActive, object: nil)

    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func applicationDidBecomeActive() {
        if let date = timeLeftApp, abs(date.timeIntervalSinceNow) < maxTime, abs(date.timeIntervalSinceNow) > minTime {
            if let objectId = clickOnProductObjectId {
                if let product = DataModel.sharedInstance.mainMoc().productWith(objectId: objectId) {
                    self.timeLeftApp = nil
                    if UIViewController.canPresentMail() {
                        self.delegate?.recoverLostSaleManager(self, returnedFrom: product, timeSinceLeftApp: abs(date.timeIntervalSinceNow) )
                    }
                }
            }
        }
    }
    
    public func didClick(on product:Product){
        self.clickOnProductObjectId = product.objectID
        timeLeftApp = Date.init()
    }
    
    private func showEmailSentAlert(in viewController:UIViewController, email:String) {
        let alert = UIAlertController.init(title: nil, message: "Email sent to \(email) !", preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "generic.ok".localized, style: .default, handler: { (a) in
        }))
        
        viewController.present(alert, animated: true)
    
}
    
    public func presetRecoverAlertViewFor(product:Product, in viewController:UIViewController, rect:CGRect, view:UIView, timeSinceLeftApp:TimeInterval){
        
        let color = RecoveryLostSalePopupViewController.ABTestColor()
        let headline = RecoveryLostSalePopupViewController.ABTestHeadline()
        let button = RecoveryLostSalePopupViewController.ABTestButton()
        Analytics.trackFeatureRecoveryAppeared(product: product, secondsSinceLeftApp: Int(round(timeSinceLeftApp)), abTestColor: color.hexString(), abTestHeadline: headline, abTestButton: button )

        self.presentingVC = viewController

        let vc = RecoveryLostSalePopupViewController.init(emailProductAction: {
            self.clickOnProductObjectId = nil

            Analytics.trackFeatureRecoveryEmailPrompt(product: product)
            var email = AnalyticsUser.current.email
            if email == nil {
                email = UserAccountManager.shared.email
            }
            if email == nil {
                email = UserDefaults.standard.string(forKey: UserDefaultsKeys.email)
            }
            
            if let email = email {
                Analytics.trackFeatureRecoveryEmailSent(product: product)
                let _ = NetworkingPromise.sharedInstance.sendProductEmailWithRetry(product: product, email: email )
                
                self.showEmailSentAlert(in: viewController, email:email)
            }else{
                let alert = UIAlertController.init(title: nil, message: "Email:", preferredStyle: .alert)
                alert.addTextField(configurationHandler: { (textField) in
                    textField.placeholder = "email"
                    textField.addTarget(self, action: #selector(self.textChange(_:)), for: .editingChanged)

                })

                let sendAction = UIAlertAction.init(title: "generic.send".localized, style: .default, handler: { (a) in
                    if let textFields = alert.textFields, let textField = textFields.first, let email = textField.text {
                        if email.lengthOfBytes(using: .utf8) > 0 {
                            let _ = NetworkingPromise.sharedInstance.sendProductEmailWithRetry(product: product, email: email )
                            self.showEmailSentAlert(in: viewController, email:email)
                        }
                    }
                })
                sendAction.isEnabled = false
                alert.addAction(sendAction)
                self.sendAction = sendAction
                alert.addAction(UIAlertAction.init(title: "generic.cancel".localized, style: .cancel, handler: { (a) in

                }))
                
                viewController.dismiss(animated: true, completion: {
                    viewController.present(alert, animated: true)
                })
            }
            
        }, dismissAction: {
            self.clickOnProductObjectId = nil
            viewController.dismiss(animated: true, completion: nil)
        })
        vc.ABTestColor = color
        vc.ABTestHeadline = headline
        vc.ABTestButton = button
        vc.modalPresentationStyle = .popover

        vc.popoverPresentationController?.backgroundColor = vc.view.backgroundColor
        vc.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        vc.popoverPresentationController?.delegate = self
        vc.popoverPresentationController?.sourceRect = rect
        vc.popoverPresentationController?.sourceView = view
        
        viewController.present(vc, animated: true) {
            
        }
    }
    
    @objc func textChange(_ sender:Any){
        func isValid(email:String?) -> Bool {
            let form = FormRow.Email()
            form.value = email
            return form.isValid()
        }
        if let textField = sender as? UITextField{
            self.sendAction?.isEnabled = isValid(email: textField.text)
        }
    }
    
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        if result == .sent {
            let product:Product? = {
                if let clickOnProductObjectId = self.clickOnProductObjectId {
                    return DataModel.sharedInstance.mainMoc().productWith(objectId:clickOnProductObjectId )
                }
                return nil
            }()
            Analytics.trackFeatureRecoveryEmailSent(product: product)
        }
        self.clickOnProductObjectId = nil
        if let presentingVC  = self.presentingVC {
            presentingVC.dismiss(animated: true, completion: nil)
        }else{
            controller.dismiss(animated: true, completion: nil)
        }
    }
    
    func stringFromFile(named:String) -> String?{
        if let filepath = Bundle.main.path(forResource: named, ofType: nil) {
            do {
                let contents = try String(contentsOfFile: filepath)
                return contents
            } catch {
                // contents could not be loaded
            }
        } else {
            
        }
        return nil
    }
//    func stringWith(template:String, replacements:[String:String?]) -> String{
//        var toReturn = template
//        for (key, value) in replacements {
//            if let range = toReturn.range(of: "{{\(key)}}"), let value = value {
//                toReturn = toReturn.replacingCharacters(in: range, with: value)
//            }
//        }
//        return toReturn
//    }
//    func htmlEmailForProducts(products:[Product])  -> String {
//        var toReturn = ""
//        if let header = stringFromFile(named: "productEmailheader.html"), let footer = stringFromFile(named: "productEmailfooter.html"), let item = stringFromFile(named: "productEmailitem.html") {
//            
//            toReturn.append(header)
//            for p in products {
//                let itemString = stringWith(template: item, replacements: ["brand":p.calculatedDisplayTitle, "title":p.productTitle(), "offer":p.offer, "price":p.price, "imageURL":p.imageURL])
//                toReturn.append(itemString)
//            }
//            toReturn.append(footer)
//            
//        }
//        return toReturn
//    }
    
}

extension RecoverLostSaleManager :UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        // only block the first tap
        if didTapToDismiss {
            return true
        }
        Analytics.trackFeatureRecoveryDismissBlocked(product: nil)
        didTapToDismiss = true
        return false
    }
}



