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

class RecoverLostSaleManager: NSObject {
    private var timeLeftApp:Date?
    private var clickOnProductObjectId:NSManagedObjectID?
    var productCollectionViewManager = ProductCollectionViewManager()

    
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
                    self.delegate?.recoverLostSaleManager(self, returnedFrom: product, timeSinceLeftApp: Int(round( abs(date.timeIntervalSinceNow) )))
                }
            }
        }
    }
    
    public func didClick(on product:Product){
        let _ = AssetSyncModel.sharedInstance.addSubShoppable(fromProduct: product)
        self.clickOnProductObjectId = product.objectID
        timeLeftApp = Date.init()
    }
    
    private func showEmailSentAlert(in viewController:UIViewController, email:String) {
        let alert = UIAlertController.init(title: "product.sale_recovery.alert.email_sent.title".localized, message: "product.sale_recovery.alert.email_sent.body".localized, preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "generic.ok".localized, style: .default, handler: { (a) in
        }))
        
        viewController.present(alert, animated: true)
    
    }
    
    var isPresented = false
    
    public func presetRecoverAlertViewFor(product:Product, in viewController:UIViewController, rect:CGRect, view:UIView, timeSinceLeftApp:Int?){
        let productObjectId = product.objectID
        let productFloatPrice = product.floatPrice
        guard let _ = product.price, productFloatPrice != 0, let productImageURL = product.imageURL, let _ = product.calculatedDisplayTitle, let _ = product.offer else {
            //lacking required properties of product
            return
        }
        let screenshot = product.screenshot ?? product.shoppable?.screenshot

        if let shoppable = (screenshot?.shoppables as? Set<Shoppable>)?.first(where: {$0.imageUrl == productImageURL}) {
            if let products = (shoppable.products as? Set<Product>)?.filter({ $0.floatPrice != 0 && $0.floatPrice < productFloatPrice && $0.isSimmilar(product) }).prefix(10), products.count >= 3 {
                Analytics.trackFeatureLowerPricesAppeared(product: product, secondsSinceLeftApp: timeSinceLeftApp)
                let vc = SimilarItemsPopupViewController.init(dismissAction: {
                    let product = DataModel.sharedInstance.mainMoc().productWith(objectId: productObjectId)
                    Analytics.trackFeatureLowerPricesDismiss(product: product)
                    self.isPresented = false
                    viewController.dismiss(animated: true, completion: nil)
                })
                self.presentingVC = viewController
                vc.products = Array(products).sorted{ $0.order < $1.order }
                vc.modalPresentationStyle = .popover
                
                vc.popoverPresentationController?.backgroundColor = vc.view.backgroundColor
                vc.popoverPresentationController?.permittedArrowDirections = [.up, .down]
                vc.popoverPresentationController?.delegate = self
                vc.popoverPresentationController?.sourceRect = rect.insetBy(dx: 20, dy: 20)
                vc.popoverPresentationController?.sourceView = view
                
                viewController.present(vc, animated: true)
                
                
            }else{
                Analytics.trackFeatureLowerPricesDidNotAppear(product: product, secondsSinceLeftApp: timeSinceLeftApp, reason: .notEnoughCheaperProducts)
            }
        }else{
            Analytics.trackFeatureLowerPricesDidNotAppear(product: product, secondsSinceLeftApp: timeSinceLeftApp, reason: .notLoadedYet)
        }
       
    }
    
}

extension RecoverLostSaleManager :UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        self.isPresented = false
        var product:Product? = nil
        if let clickOnProductObjectId = self.clickOnProductObjectId {
            product = DataModel.sharedInstance.mainMoc().productWith(objectId: clickOnProductObjectId)
        }

        Analytics.trackFeatureLowerPricesDismiss(product: product)
        return true
        
    }
}



