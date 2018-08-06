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
    
    static func create(productOID: NSManagedObjectID, completion: @escaping (ProductDetailViewController?) -> Void) {
        if let product = DataModel.sharedInstance.mainMoc().object(with: productOID) as? Product {
            create(product: product, completion: completion)
        } else {
            DispatchQueue.main.async {
                completion(nil)
            }
            Analytics.trackError(type: nil, domain: "Craze", code: 113, localizedDescription: "No product at OID:\(productOID)")
        }
    }
    
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
    
    static func create(productId: String, startedLoadingFromServer:(()->()), completion: @escaping (ProductDetailViewController?) -> Void) {
        let dataModel = DataModel.sharedInstance
        if let product = dataModel.retrieveProduct(managedObjectContext: dataModel.mainMoc(), id: productId) {
            create(product: product, completion: completion)
        } else {
            startedLoadingFromServer()
            NetworkingPromise.sharedInstance.getProductInfo(productId: productId).then { (dict) -> Void in
                print(("product info: \(dict)"))
                DataModel.sharedInstance.performBackgroundTask({ (context) in
                    if let price = dict["price"] as? String,
                        let imageURL = dict["imageUrl"] as? String,
                        let productDescription = dict["productDescription"] as? String,
                        let offer = dict["offer"] as? String,
                        let floatPriceNumber = dict["floatPrice"] as? NSNumber
                        
                    {
                        let floatPrice = floatPriceNumber.floatValue
                        let originalPrice = dict["originalPrice"] as? String
                        var floatOriginalPrice:Float =  0
                        if let p =  dict["floatOriginalPrice"] as? NSNumber {
                            floatOriginalPrice = p.floatValue
                        }
                        let categories = dict["categories"] as? String
                        let brand = dict["brand"] as? String
                        let merchant = dict["merchant"] as? String
                        let partNumber = dict["partNumber"] as? String
                        let id = dict["id"] as? String
                        let color = dict["color"] as? String
                        let sku = dict["sku"] as? String
                        let fallbackPriceNumber =  dict["fallbackPrice"] as? NSNumber
                        let fallbackPrice = fallbackPriceNumber?.floatValue ?? 0.0
                        var optionsMask = ProductsOptionsMask.global.rawValue
                        if let option = dict["optionsMask"] as? NSNumber {
                            optionsMask = option.intValue
                        }
                        let _ = DataModel.sharedInstance.saveProduct(managedObjectContext: context,
                                                                           shoppable: nil, order: 0,
                                                                           productDescription: productDescription,
                                                                           price: price,
                                                                           originalPrice: originalPrice,
                                                                           floatPrice: floatPrice,
                                                                           floatOriginalPrice: floatOriginalPrice,
                                                                           categories: categories,
                                                                           brand: brand,
                                                                           offer: offer,
                                                                           imageURL: imageURL,
                                                                           merchant: merchant,
                                                                           partNumber:  partNumber,
                                                                           id: id,
                                                                           color:  color,
                                                                           sku: sku,
                                                                           fallbackPrice: fallbackPrice,
                                                                           optionsMask: Int32(optionsMask))
                        
                        
                        context.saveIfNeeded()
                        if let id = id {
                            DispatchQueue.main.async {
                                if let product = dataModel.retrieveProduct(managedObjectContext: DataModel.sharedInstance.mainMoc(), id: id) {
                                    create(product: product, completion: completion)
                                }
                            }
                        }
                    }
                })
            }.catch { (error) in
                DispatchQueue.main.async {
                    completion(nil)
                }
                Analytics.trackError(type: nil, domain: "Craze", code: 113, localizedDescription: "No product id:\(productId)")
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
