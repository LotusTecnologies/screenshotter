//
//  ShowProduct.swift
//  screenshot
//
//  Created by Jonathan Rose on 3/14/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
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
    
    static func present(with id: String) {
        print("ProductViewController present id:\(id)")
        let dataModel = DataModel.sharedInstance
        
        if let product = dataModel.retrieveProduct(managedObjectContext: dataModel.mainMoc(), id: id) {
            AssetSyncModel.sharedInstance.addSubShoppable(fromProduct: product).then(on: .main) { (shoppable) -> Void in
                let burrowViewController = ProductDetailViewController()
                burrowViewController.product = product
                burrowViewController.shoppable = product.shoppable
                let navigationController = ModalNavigationController(rootViewController: burrowViewController)
                AppDelegate.shared.window?.rootViewController?.present(navigationController, animated: true, completion: nil)
            }
        }
    }
    
    static func present(imageURL: String) {
        print("ProductViewController present imageURL:\(imageURL)")
        let dataModel = DataModel.sharedInstance
        
        if let product = dataModel.retrieveProduct(managedObjectContext: dataModel.mainMoc(), imageURL: imageURL) {
            AssetSyncModel.sharedInstance.addSubShoppable(fromProduct: product).then(on: .main) { (shoppable) -> Void in
                let burrowViewController = ProductDetailViewController()
                burrowViewController.product = product
                burrowViewController.shoppable = product.shoppable
                let navigationController = ModalNavigationController(rootViewController: burrowViewController)
                AppDelegate.shared.window?.rootViewController?.present(navigationController, animated: true, completion: nil)
            }
        }
    }

}
