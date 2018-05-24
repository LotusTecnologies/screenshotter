//
//  ProductPriceAlertController.swift
//  screenshot
//
//  Created by Corey Werner on 5/24/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import CoreData

class ProductPriceAlertController {
    private var productObjectId:NSManagedObjectID?
    
    func priceAlertAction(_ button: LoadingButton?, on product: Product) -> UIAlertController? {
        if let button = button {
            if button.isLoading {
                return nil
            }
        }
        self.productObjectId = product.objectID

        switch PermissionsManager.shared.permissionStatus(for: .push) {
        case .authorized:
            togglePriceAlert(product: product)
            
        case .undetermined:
            requestPermission()
            
        default:
            return PermissionsManager.shared.deniedAlertController(for: .push)
        }
            
        return nil
    }
    
    private func togglePriceAlert(product:Product) {
        
        let hasPriceAlerts =  product.hasPriceAlerts
        if hasPriceAlerts {
            Analytics.trackProductPriceAlertUnsubscribed(product: product)
            product.untrack().catch { (error) in
                let e = error as NSError
                Analytics.trackProductPriceAlertUnsubscribedError(product: product, domain: e.domain, code: e.code, localizedDescription: e.localizedDescription)
            }
        }
        else {
            Analytics.trackProductPriceAlertSubscribed(product: product)
            product.track().catch { (error) in
                let e = error as NSError
                Analytics.trackProductPriceAlertSubscribedError(product: product, domain: e.domain, code: e.code, localizedDescription: e.localizedDescription)

            }
        }
    }
    
    private func requestPermission() {
        PermissionsManager.shared.requestPermission(for: .push) { [weak self] granted in
            if granted, let strongSelf = self {
                NotificationCenter.default.addObserver(strongSelf, selector: #selector(strongSelf.applicationDidRegisterForRemoteNotifications(_:)), name: .applicationDidRegisterForRemoteNotifications, object: nil)
            }
        }
    }
    
    @objc private func applicationDidRegisterForRemoteNotifications(_ notification: Notification) {
        NotificationCenter.default.removeObserver(self, name: .applicationDidRegisterForRemoteNotifications, object: nil)
        if let objectId = self.productObjectId, let product = DataModel.sharedInstance.mainMoc().productWith(objectId: objectId){
            togglePriceAlert(product: product)
        }
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
