//
//  ProductPriceAlertController.swift
//  screenshot
//
//  Created by Corey Werner on 5/24/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class ProductPriceAlertController {
    weak private var product: Product?
    weak private var button: UIButton?
    private var loadingButton: LoadingButton? {
        return button as? LoadingButton
    }
    
    func priceAlertAction(_ button: UIButton, on product: Product) -> UIAlertController? {
        self.button = button
        self.product = product
        
        switch PermissionsManager.shared.permissionStatus(for: .push) {
        case .authorized:
            togglePriceAlert()
            
        case .undetermined:
            requestPermission()
            
        default:
            return PermissionsManager.shared.deniedAlertController(for: .push)
        }
            
        return nil
    }
    
    private func togglePriceAlert() {
        guard let product = product else {
            return
        }
        
        if loadingButton?.isLoading ?? false {
            return
        }
        
        loadingButton?.isLoading = true
        
        let hasPriceAlerts =  product.hasPriceAlerts
        if hasPriceAlerts {
            Analytics.trackProductPriceAlertUnsubscribed(product: product)
        }
        else {
            Analytics.trackProductPriceAlertSubscribed(product: product)
        }
        
        (product.hasPriceAlerts ? product.untrack() : product.track())
            .then { [weak button] isTracking -> Void in
                button?.isSelected = isTracking
            }
            .catch { error in
                let e = error as NSError
            
                if hasPriceAlerts {
                    Analytics.trackProductPriceAlertUnsubscribedError(product: product, domain: e.domain, code: e.code, localizedDescription: e.localizedDescription)
                }
                else {
                    Analytics.trackProductPriceAlertSubscribedError(product: product, domain: e.domain, code: e.code, localizedDescription: e.localizedDescription)
                }
            }
            .always { [weak self] in
                self?.loadingButton?.isLoading = false
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
        togglePriceAlert()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
