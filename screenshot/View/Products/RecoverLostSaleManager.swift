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
    func recoverLostSaleManager(_ manager:RecoverLostSaleManager, returnedFrom product:Product)
}

class RecoverLostSaleManager: NSObject, MFMailComposeViewControllerDelegate {
    private var timeLeftApp:Date?
    private var clickOnProductObjectId:NSManagedObjectID?

    weak var delegate:RecoverLostSaleManagerDelegate?
    weak var presentingVC:UIViewController?

    private let maxTime:TimeInterval = 120
    private let minTime:TimeInterval = 10

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: .UIApplicationDidBecomeActive, object: nil)

    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func applicationDidBecomeActive() {
        if let data = timeLeftApp, abs(data.timeIntervalSinceNow) < maxTime, abs(data.timeIntervalSinceNow) > minTime {
            if let objectId = clickOnProductObjectId {
                if let product = DataModel.sharedInstance.mainMoc().productWith(objectId: objectId) {
                    self.timeLeftApp = nil
                    if UIViewController.canPresentMail() {
                        self.delegate?.recoverLostSaleManager(self, returnedFrom: product)
                    }
                }
            }
        }
    }
    
    public func didClick(on product:Product){
        self.clickOnProductObjectId = product.objectID
        timeLeftApp = Date.init()
    }
    public func presetRecoverAlertViewFor(product:Product, in viewController:UIViewController, rect:CGRect, view:UIView){
        let body =  self.htmlEmailForProducts(products: [product])
        
        Analytics.trackFeatureRecoveryAppeared(product: product)
        self.presentingVC = viewController

        let vc = RecoveryLostSalePopupViewController.init(emailProductAction: {
            Analytics.trackFeatureRecoveryEmailPresented(product: product)
            let recipient = AnalyticsUser.current.email ?? ""
            let dateFormatter = DateFormatter.init()
            dateFormatter.timeStyle = .none
            dateFormatter.dateStyle = .medium
            let subject = "product.sale_recovery.email.subject".localized(withFormat: dateFormatter.string(from: Date()))
            viewController.dismiss(animated: true, completion: {
                viewController.presentMail(recipient: recipient, gmailMessage: body, subject: subject, message: body, isHTML:true, delegate:self, noEmailErrorMessage: "email.setup.message.reminder".localized, attachLogs:false)
            })
        }, dismissAction: {
            self.clickOnProductObjectId = nil
            viewController.dismiss(animated: true, completion: nil)
        })
        vc.view.backgroundColor = .crazeRed
        vc.modalPresentationStyle = .popover

        vc.popoverPresentationController?.backgroundColor = .crazeRed
        vc.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        vc.popoverPresentationController?.delegate = self
        vc.popoverPresentationController?.sourceRect = rect
        vc.popoverPresentationController?.sourceView = view
        
        viewController.present(vc, animated: true) {
            
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
    func stringWith(template:String, replacements:[String:String?]) -> String{
        var toReturn = template
        for (key, value) in replacements {
            if let range = toReturn.range(of: "{{\(key)}}"), let value = value {
                toReturn = toReturn.replacingCharacters(in: range, with: value)
            }
        }
        return toReturn
    }
    func htmlEmailForProducts(products:[Product])  -> String {
        var toReturn = ""
        if let header = stringFromFile(named: "productEmailheader.html"), let footer = stringFromFile(named: "productEmailfooter.html"), let item = stringFromFile(named: "productEmailitem.html") {
            
            toReturn.append(header)
            for p in products {
                let itemString = stringWith(template: item, replacements: ["brand":p.calculatedDisplayTitle, "title":p.productTitle(), "offer":p.offer, "price":p.price, "imageURL":p.imageURL])
                toReturn.append(itemString)
            }
            toReturn.append(footer)
            
        }
        return toReturn
    }
    
}

extension RecoverLostSaleManager :UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}



