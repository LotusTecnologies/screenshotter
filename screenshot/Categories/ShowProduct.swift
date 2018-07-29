//
//  ShowProduct.swift
//  screenshot
//
//  Created by Jonathan Rose on 3/14/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit

extension UIViewController {
    func presentProduct(_ product: Product, atLocation location: Analytics.AnalyticsProductOpenedFromPage) {
        Analytics.trackTappedOnProduct(product, atLocation: location)
        
        OpenWebPage.presentProduct(product, fromViewController: self)
    }
}

extension ProductDetailViewController {
    
    static func present(with id: String) {
        print("ProductViewController present id:\(id)")
        let dataModel = DataModel.sharedInstance
        
        if let product = dataModel.retrieveProduct(managedObjectContext: dataModel.mainMoc(), id: id) {
            AssetSyncModel.sharedInstance.addSubShoppable(fromProduct: product).then(on: .main) { (shoppable) -> Void in
                present(product: product)
            }
        }
    }
    
    static func present(imageURL: String) {
        print("ProductViewController present imageURL:\(imageURL)")
        let dataModel = DataModel.sharedInstance
        
        if let product = dataModel.retrieveProduct(managedObjectContext: dataModel.mainMoc(), imageURL: imageURL) {
            AssetSyncModel.sharedInstance.addSubShoppable(fromProduct: product).then(on: .main) { (shoppable) -> Void in
                present(product: product)
            }
        }
    }
    
    static func present(product: Product) {
        let burrowViewController = ProductDetailViewController()
        burrowViewController.product = product
        burrowViewController.shoppable = product.shoppable
        burrowViewController.uuid = UUID().uuidString
        let navigationController = ModalNavigationController(rootViewController: burrowViewController)
        AppDelegate.shared.window?.rootViewController?.present(navigationController, animated: true, completion: nil)
    }

}
