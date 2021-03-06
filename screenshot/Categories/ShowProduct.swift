//
//  ShowProduct.swift
//  screenshot
//
//  Created by Jonathan Rose on 3/14/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit
import PromiseKit

extension UIViewController {
    func presentProduct(_ product: Product, atLocation location: Analytics.AnalyticsProductOpenedFromPage) {
        Analytics.trackTappedOnProduct(product, atLocation: location)
        
        OpenWebPage.presentProduct(product, fromViewController: self)
    }
}

extension ProductDetailViewController {
    
    static func create(product: Product, completion: @escaping (ProductDetailViewController?) -> Void) {
        AssetSyncModel.sharedInstance.addSubShoppable(fromProduct: product).then(on: .main) { shoppable -> Void in
            let burrowViewController = ProductDetailViewController()
            burrowViewController.product = product
            burrowViewController.shoppable = shoppable
            burrowViewController.uuid = UUID().uuidString
            let _ = burrowViewController.view
            completion(burrowViewController)
        }.catch { error in
            DispatchQueue.main.async {
                completion(nil)
            }
            Analytics.trackError(type: nil, domain: "Craze", code: 112, localizedDescription: "addSubShoppable error:\(error)")
        }
    }
    
    static func create(productId: String, startedLoadingFromServer: () -> (), completion: @escaping (ProductDetailViewController?) -> Void) {
        let dataModel = DataModel.sharedInstance
        if let product = dataModel.retrieveProduct(managedObjectContext: dataModel.mainMoc(), id: productId) {
            create(product: product, completion: completion)
        } else {
            startedLoadingFromServer()
            NetworkingPromise.sharedInstance.getProductInfo(productId: productId).then { dict -> Promise<Product> in
                print(("product info: \(dict)"))
                return dataModel.mainSafeOrphanedProduct(serverDict: dict)
                }.then { product -> Void in
                    create(product: product, completion: completion)
                }.catch { error in
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    Analytics.trackError(type: nil, domain: "Craze", code: 113, localizedDescription: "No product id:\(productId) error:\(error)")
            }
        }
    }
    
    static func create(imageURL: String, completion: @escaping (ProductDetailViewController?) -> Void) {
        let dataModel = DataModel.sharedInstance
        if let product = dataModel.retrieveProduct(managedObjectContext: dataModel.mainMoc(), imageURL: imageURL) {
            create(product: product, completion: completion)
        } else {
            DispatchQueue.main.async {
                completion(nil)
            }
            Analytics.trackError(type: nil, domain: "Craze", code: 113, localizedDescription: "No product imageURL:\(imageURL)")
        }
    }
    
}

extension AppDelegate {
    
    static func presentModally(viewController: UIViewController) {
        let navigationController = ModalNavigationController(rootViewController: viewController)
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
