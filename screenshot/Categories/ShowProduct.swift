//
//  ShowProduct.swift
//  screenshot
//
//  Created by Jonathan Rose on 3/14/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

extension UIViewController {
    @discardableResult func presentProduct(_ product: Product, atLocation location: AnalyticsTrackers.Location) -> ProductViewController? {
        AnalyticsTrackers.standard.trackTappedOnProduct(product, atLocation: location)
        
        if product.partNumber != nil {
            let productViewController = ProductViewController(productOID: product.objectID)
            productViewController.title = product.displayTitle
            productViewController.setup(with: product)
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
            let productViewController = ProductViewController(productOID: product.objectID)
            productViewController.title = product.displayTitle
            productViewController.setup(with: product)
            
            let navigationController = ModalNavigationController(rootViewController: productViewController)
            AppDelegate.shared.window?.rootViewController?.present(navigationController, animated: true, completion: nil)
        }
    }
}
