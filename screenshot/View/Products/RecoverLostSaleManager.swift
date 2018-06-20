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

    private let timeout:TimeInterval = 30
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: .UIApplicationDidBecomeActive, object: nil)

    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func applicationDidBecomeActive() {
        if let data = timeLeftApp, abs(data.timeIntervalSinceNow) < timeout {
            if let objectId = clickOnProductObjectId {
                if let product = DataModel.sharedInstance.mainMoc().productWith(objectId: objectId) {
                    clickOnProductObjectId = nil
                    self.delegate?.recoverLostSaleManager(self, returnedFrom: product)
                }
            }
        }
    }
    public func didClick(on product:Product){
        self.clickOnProductObjectId = product.objectID
        timeLeftApp = Date.init()
    }
    public func presetRecoverAlertViewFor(product:Product, in viewController:UIViewController){
        let alert = UIAlertController.init(title: "product.sale_recovery.alert.title".localized, message: "product.sale_recovery.alert.message".localized, preferredStyle: .alert)
        let body =  self.htmlEmailForProducts(products: [product])

        Analytics.trackFeatureRecoveryAppeared()
        self.presentingVC = viewController
        alert.addAction(UIAlertAction.init(title: "product.sale_recovery.alert.email_me".localized, style: .default, handler: { (a) in
            Analytics.trackFeatureRecoveryEmailPresented()
            let recipient = AnalyticsUser.current.email ?? ""
            let dateFormatter = DateFormatter.init()
            dateFormatter.timeStyle = .none
            dateFormatter.dateStyle = .medium
            let subject = "product.sale_recovery.email.subject".localized(withFormat: dateFormatter.string(from: Date()))
            viewController.presentMail(recipient: recipient, gmailMessage: body, subject: subject, message: body, isHTML:true, delegate:self)
        }))
        alert.addAction(UIAlertAction.init(title: "generic.no_thanks".localized, style: .cancel, handler: { (a) in
            
        }))
        viewController.present(alert, animated: true, completion: nil)
    }
    
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        if result == .sent {
            Analytics.trackFeatureRecoveryEmailSent()
        }
        
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
