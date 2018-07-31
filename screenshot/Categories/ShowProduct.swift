//
//  ShowProduct.swift
//  screenshot
//
//  Created by Jonathan Rose on 3/14/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit
import CoreData

extension UIViewController {
    func presentProduct(_ product: Product, atLocation location: Analytics.AnalyticsProductOpenedFromPage) {
        Analytics.trackTappedOnProduct(product, atLocation: location)
        
        OpenWebPage.presentProduct(product, fromViewController: self)
    }
}

extension ProductDetailViewController {
    
    static func present(productOID: NSManagedObjectID) {
        if let product = DataModel.sharedInstance.mainMoc().object(with: productOID) as? Product {
            AssetSyncModel.sharedInstance.addSubShoppable(fromProduct: product).then(on: .main) { shoppable -> Void in
                present(shoppable: shoppable, product: product)
                }.catch { error in
                    Analytics.trackError(type: nil, domain: "Craze", code: 112, localizedDescription: "addSubShoppable error:\(error)")
            }
        } else {
            Analytics.trackError(type: nil, domain: "Craze", code: 113, localizedDescription: "No product at OID:\(productOID)")
        }
    }
    
    static func present(with id: String) {
        let dataModel = DataModel.sharedInstance
        if let product = dataModel.retrieveProduct(managedObjectContext: dataModel.mainMoc(), id: id) {
            AssetSyncModel.sharedInstance.addSubShoppable(fromProduct: product).then(on: .main) { shoppable -> Void in
                present(shoppable: shoppable, product: product)
            }
        }
    }
    
    static func present(imageURL: String) {
        let dataModel = DataModel.sharedInstance
        if let product = dataModel.retrieveProduct(managedObjectContext: dataModel.mainMoc(), imageURL: imageURL) {
            AssetSyncModel.sharedInstance.addSubShoppable(fromProduct: product).then(on: .main) { shoppable -> Void in
                present(shoppable: shoppable, product: product)
            }
        }
    }
    
    static func present(shoppable: Shoppable, product: Product) {
        let burrowViewController = ProductDetailViewController()
        burrowViewController.product = product
        burrowViewController.shoppable = shoppable
        burrowViewController.uuid = UUID().uuidString
        let _ = burrowViewController.view
        let navigationController = ModalNavigationController(rootViewController: burrowViewController)
        if let rootVC = AppDelegate.shared.window?.rootViewController {
            rootVC.present(navigationController, animated: true, completion: nil)
        } else {
            Analytics.trackError(type: nil, domain: "Craze", code: 114, localizedDescription: "rootViewController initially unavailable")
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.100) {
                if let rootVC = AppDelegate.shared.window?.rootViewController {
                    rootVC.present(navigationController, animated: true, completion: nil)
                } else {
                    Analytics.trackError(type: nil, domain: "Craze", code: 115, localizedDescription: "rootViewController finally unavailable")
                }
            }
        }
    }

}
