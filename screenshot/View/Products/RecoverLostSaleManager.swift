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
import PromiseKit

protocol RecoverLostSaleManagerDelegate:class {
    func recoverLostSaleManager(_ manager:RecoverLostSaleManager, returnedFrom product:Product, timeSinceLeftApp:Int)
}

class RecoverLostSaleManager: NSObject, MFMailComposeViewControllerDelegate {
    private var timeLeftApp:Date?
    private var clickOnProductObjectId:NSManagedObjectID?

    
    weak var delegate:RecoverLostSaleManagerDelegate?
    weak var presentingVC:UIViewController?

    private let maxTime:TimeInterval = 120
    private let minTime:TimeInterval = 10

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
                        self.delegate?.recoverLostSaleManager(self, returnedFrom: product, timeSinceLeftApp: Int(round( abs(date.timeIntervalSinceNow) )))
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
        let alert = UIAlertController.init(title: "product.sale_recovery.alert.email_sent.title".localized, message: "product.sale_recovery.alert.email_sent.body".localized, preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "generic.ok".localized, style: .default, handler: { (a) in
        }))
        
        viewController.present(alert, animated: true)
    
}
    
    public func presetRecoverAlertViewFor(product:Product, in viewController:UIViewController, rect:CGRect, view:UIView, timeSinceLeftApp:Int?, reason:Analytics.AnalyticsFeatureRecoveryAppearedReason){
        
        guard let _ = product.price, let _ = product.imageURL, let _ = product.calculatedDisplayTitle, let _ = product.offer else {
            //lacking required properties of product
            return
        }
        let abtest = RecoveryLostSalePopupViewController.ABTest.init(seed: AnalyticsUser.current.randomSeed)

//        let abtest = RecoveryLostSalePopupViewController.ABTest.init(seed: UUID.init().toRandomSeed())
        
        Analytics.trackFeatureRecoveryAppeared(product: product, secondsSinceLeftApp: timeSinceLeftApp, abTestColor: abtest.backgroundColor.hexString(), abTestHeadline: abtest.headlineText, abTestButton: abtest.buttonText, reason: reason )

        self.presentingVC = viewController

        let vc = RecoveryLostSalePopupViewController.init(abTest:abtest, emailProductAction: {
            self.clickOnProductObjectId = nil

            var email = AnalyticsUser.current.email
            if email == nil {
                email = UserAccountManager.shared.email
            }
            if email == nil {
                email = UserDefaults.standard.string(forKey: UserDefaultsKeys.email)
            }
            
            if let email = email {
                Analytics.trackFeatureRecoveryEmailPrompt(product: product, hasEmail: true)
                Analytics.trackFeatureRecoveryEmailSent(product: product)
                NetworkingPromise.sharedInstance.sendProductEmailWithRetry(product: product, email: email ).then(execute: { (dict) -> Void in
                    print("send email: \(dict)")
                }).catch(execute: { (e) in
                    if case let PMKURLError.badResponse(_, data, _) = e, let d = data, let errorString = String.init(data: d, encoding: .utf8) {
                        print("error sending email: \(errorString)")
                    }

                    print("error sending email: \(e)")
                })
                viewController.dismiss(animated: true, completion: {
                    self.showEmailSentAlert(in: viewController, email:email)
                })
            }else{
                Analytics.trackFeatureRecoveryEmailPrompt(product: product, hasEmail: false)
                let alert = UIAlertController.init(title: "product.sale_recovery.alert.email_sent.title".localized, message: "product.sale_recovery.alert.email_sent.body".localized, preferredStyle: .alert)
                alert.addTextField(configurationHandler: { (textField) in
                    textField.placeholder = "generic.email".localized
                    textField.keyboardType = .emailAddress
                    textField.addTarget(self, action: #selector(self.textChange(_:)), for: .editingChanged)
                })

                let sendAction = UIAlertAction.init(title: "generic.send".localized, style: .default, handler: { (a) in
                    if let textFields = alert.textFields, let textField = textFields.first, let email = textField.text {
                        if email.lengthOfBytes(using: .utf8) > 0 {
                            NetworkingPromise.sharedInstance.sendProductEmailWithRetry(product: product, email: email ).then(execute: { (dict) -> Void in
                                print("send email: \(dict)")
                            }).catch(execute: { (e) in
                                print("error sending email: \(e)")
                            })
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
//        vc.view.layer.shadowOffset = CGSizeMake(50, 50);
//        vc.view.layer.shadowColor = [[UIColor blackColor] CGColor];

        vc.modalPresentationStyle = .popover

        vc.popoverPresentationController?.backgroundColor = vc.view.backgroundColor
        vc.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        vc.popoverPresentationController?.delegate = self
        vc.popoverPresentationController?.sourceRect = rect.insetBy(dx: 20, dy: 20)
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
    
}

extension RecoverLostSaleManager :UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {

        return true
        
    }
}



