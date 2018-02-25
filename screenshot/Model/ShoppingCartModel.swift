//
//  ShoppingCartModel.swift
//  screenshot
//
//  Created by Gershon Kagan on 2/22/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import PromiseKit
import CoreData

class ShoppingCartModel {
    
    static let shared = ShoppingCartModel()
    
    func populateVariants(productOID: NSManagedObjectID, partNumber: String) {
        firstly {
            return NetworkingPromise.getAvailableVariants(partNumber: partNumber)
            }.then { dict -> Void in
                print("populateVariants dict:\(dict)")
                if let errorString = dict["error"] as? String {
                    print("populateVariants error. errorString:\(errorString)")
                    return
                }
                let dataModel = DataModel.sharedInstance
                dataModel.performBackgroundTask { managedObjectContext in
                    guard let rootProduct = managedObjectContext.object(with: productOID) as? Product else {
                        print("populateVariants failed to fetch product:\(productOID)")
                        return
                    }
                    rootProduct.altImageURLs = (dict["alt_images"] as? [String])?.joined(separator: ",")
                    print("populateVariants altImageURLs:\(rootProduct.altImageURLs ?? "-")")
                    guard let colors = dict["colors"] as? [[String : Any]] else {
                        print("populateVariants failed to extract colors for partNumber:\(partNumber)")
                        return
                    }
                    var hasVariants = false
                    colors.forEach { color in
                        let colorString = color["color"] as? String
                        let colorRetailPrice = color["retail_price"] as? Float
                        let colorImageURLs = (color["images"] as? [String])?.joined(separator: ",")
                        print(" partNumber:\(partNumber)  colorString:\(colorString ?? "-")  colorRetailPrice:\(String(describing: colorRetailPrice))  colorImageURLs:\(colorImageURLs ?? "-")")
                        if let sizes = color["sizes"] as? [[String : Any]] {
                            sizes.forEach { size in
                                let variant = dataModel.saveVariant(managedObjectContext: managedObjectContext,
                                                                    product: rootProduct,
                                                                    color: colorString,
                                                                    size: size["size"] as? String,
                                                                    retailPrice: size["retail_price"] as? Float ?? colorRetailPrice ?? rootProduct.retailPrice,
                                                                    sku: size["merchant_sku"] as? String,
                                                                    upc: size["upc"] as? String,
                                                                    imageURLs: colorImageURLs)
                                hasVariants = true
                                print("  partNumber:\(partNumber)  colorString:\(variant.color ?? "-")  sizeString:\(variant.size ?? "-")  sku:\(variant.sku ?? "-")  upc:\(variant.upc ?? "-")  retailPrice:\(variant.retailPrice)  imageURLs:\(variant.imageURLs ?? "-")")
                            }
                        }
                    }
                    rootProduct.hasVariants = hasVariants
                    dataModel.saveMoc(managedObjectContext: managedObjectContext)
                }
            }.catch { error in
                print("populateVariants partNumber:\(partNumber)  error:\(error)")
        }
    }
    
}
