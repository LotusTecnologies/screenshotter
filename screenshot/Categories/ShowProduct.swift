//
//  ShowProduct.swift
//  screenshot
//
//  Created by Jonathan Rose on 3/14/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

extension UIViewController {
    @discardableResult func presentProduct(_ product: Product, atLocation location: Analytics.AnalyticsProductOpenedFromPage) -> ProductViewController? {
        Analytics.trackTappedOnProduct(product, atLocation: location)
        
        if product.isSupportingUSC {
            let productViewController = ProductViewController(product: product)
            navigationController?.pushViewController(productViewController, animated: true)
            return productViewController
        }
        else {
            OpenWebPage.presentProduct(product, fromViewController: self)
        }
        
        return nil
    }
}

extension ProductViewController {
    static func present(with partNumber: String) {
        print("ProductViewController present partNumber:\(partNumber)")
        let dataModel = DataModel.sharedInstance
        
        if let product = dataModel.retrieveProduct(managedObjectContext: dataModel.mainMoc(), partNumber: partNumber) {
            Analytics.trackProductPriceAlertOpened(product: product)
            
            if UIApplication.isUSC {
                let productViewController = ProductViewController(product: product)
                let navigationController = ModalNavigationController(rootViewController: productViewController)
                AppDelegate.shared.window?.rootViewController?.present(navigationController, animated: true, completion: nil)
            }else{
                if let vc = AppDelegate.shared.window?.rootViewController {
                    OpenWebPage.presentProduct(product, fromViewController: vc)
                }
            }
        }
    }
}
