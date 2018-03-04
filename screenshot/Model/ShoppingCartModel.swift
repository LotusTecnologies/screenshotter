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
    
    func populateVariants(productOID: NSManagedObjectID) -> Promise<Product> {
        let dataModel = DataModel.sharedInstance
        return firstly {
            return deleteVariantsIfOld(productOID: productOID)
            }.then { partNumber -> Promise<NSDictionary> in
                return partNumber.isEmpty ? Promise(value: NSDictionary()) : NetworkingPromise.getAvailableVariants(partNumber: partNumber)
            }.then { dict -> Promise<Bool> in
                print("populateVariants dict:\(dict)")
                guard dict.count > 0 else {
                    return Promise(value: false)
                }
                if let errorString = dict["error"] as? String {
                    let error = NSError(domain: "Craze", code: 30, userInfo: [NSLocalizedDescriptionKey : "populateVariants getAvailableVariants returned error:\(errorString)"])
                    return Promise(error: error)
                }
                return self.saveVariantsFromDictionary(productOID: productOID, dict: dict)
            }.then { didSaveVariants -> Promise<Product> in // Must be on main queue.
                print("populateVariants final then clause didSaveVariants:\(didSaveVariants)")
                if let product = dataModel.mainMoc().object(with: productOID) as? Product {
                    return Promise(value: product)
                } else {
                    let error = NSError(domain: "Craze", code: 32, userInfo: [NSLocalizedDescriptionKey : "populateVariants failed to fetch a third time product:\(productOID)"])
                    print("populateVariants catch error:\(error)")
                    return Promise(error: error)
                }
        }
    }
    
    func getAddableCart() -> Promise<Cart> {
        let dataModel = DataModel.sharedInstance
        return firstly {
            return dataModel.retrieveOrCreateAddableCart()
            }.then { cartOID -> Promise<Cart> in // Must be on main thread.
                guard let cart = dataModel.mainMoc().object(with: cartOID) as? Cart else {
                    let error = NSError(domain: "Craze", code: 34, userInfo: [NSLocalizedDescriptionKey : "getAddableCart failed to instantiate cart from objectID:\(cartOID)"])
                    return Promise(error: error)
                }
                if let remoteId = cart.remoteId,
                  !remoteId.isEmpty {
                    // Do nothing.
                } else {
                    // Return the cart right away, but also kick off networking to request a remoteId.
                    self.addRemoteId(cartOID: cartOID)
                }
                return Promise(value: cart)
        }
    }
    
    // MARK: Helper
    
    // Deletes variants if older than, say, an hour.
    // Returns the partNumber if new variants should be fetched from Shoppable server.
    func deleteVariantsIfOld(productOID: NSManagedObjectID) -> Promise<String> {
        let dataModel = DataModel.sharedInstance
        return Promise { fulfill, reject in
            dataModel.performBackgroundTask { managedObjectContext in
                guard let rootProduct = managedObjectContext.object(with: productOID) as? Product else {
                    let error = NSError(domain: "Craze", code: 28, userInfo: [NSLocalizedDescriptionKey : "populateVariants failed to fetch product:\(productOID)"])
                    reject(error)
                    return
                }
                guard let partNumber = rootProduct.partNumber else {
                    let error = NSError(domain: "Craze", code: 29, userInfo: [NSLocalizedDescriptionKey : "populateVariants no partNumber for rootProduct:\(rootProduct)"])
                    reject(error)
                    return
                }
                if let variants = rootProduct.availableVariants as? Set<Variant>,
                  let firstVariant = variants.first {
                    if let dateModified = firstVariant.dateModified as Date?,
                        -dateModified.timeIntervalSinceNow <= 60 * 60 {
                        print("populateVariants variant <= an hour old. variant:\(firstVariant)")
                        fulfill("")
                    } else {
                        // Delete the old variants.
                        print("populateVariants variant > an hour old. Deleting:\(variants.count)")
                        variants.forEach {managedObjectContext.delete($0)}
                        rootProduct.hasVariants = false
                        dataModel.saveMoc(managedObjectContext: managedObjectContext)
                    }
                } else {
                    print("populateVariants no previous variants")
                }
                fulfill(partNumber)
            }
        }
    }
    
    // Returns a Bool as to whether new variants were saved.
    func saveVariantsFromDictionary(productOID: NSManagedObjectID, dict: NSDictionary) -> Promise<Bool> {
        let dataModel = DataModel.sharedInstance
        return Promise { fulfill, reject in
            dataModel.performBackgroundTask { managedObjectContext in
                guard let rootProduct = managedObjectContext.object(with: productOID) as? Product else {
                    let error = NSError(domain: "Craze", code: 31, userInfo: [NSLocalizedDescriptionKey : "populateVariants failed to fetch a second time product:\(productOID)"])
                    reject(error)
                    return
                }
                
                rootProduct.altImageURLs = (dict["alt_images"] as? [String])?.joined(separator: ",")
                rootProduct.detailedDescription = dict["description"] as? String
                rootProduct.name = dict["name"] as? String
                rootProduct.url = dict["url"] as? String
                print("populateVariants altImageURLs:\(rootProduct.altImageURLs ?? "-")")
                
                var hasVariants = false
                let colors = dict["colors"] as? [[String : Any]]
                colors?.forEach { color in
                    let colorString = color["color"] as? String
                    let colorRetailPrice = color["retail_price"] as? Float
                    let colorImageURLs = (color["images"] as? [String])?.joined(separator: ",")
                    print(" colorString:\(colorString ?? "-")  colorRetailPrice:\(String(describing: colorRetailPrice))  colorImageURLs:\(colorImageURLs ?? "-")")
                    let sizes = color["sizes"] as? [[String : Any]]
                    sizes?.forEach { size in
                        if let sku = size["merchant_sku"] as? String ?? size["id"] as? String,
                          !sku.isEmpty {
                            let variant = dataModel.saveVariant(managedObjectContext: managedObjectContext,
                                                                product: rootProduct,
                                                                color: colorString,
                                                                size: size["size"] as? String,
                                                                retailPrice: size["retail_price"] as? Float ?? colorRetailPrice ?? rootProduct.retailPrice,
                                                                sku: sku,
                                                                url: size["url"] as? String,
                                                                imageURLs: colorImageURLs)
                            hasVariants = true
                            print("  colorString:\(variant.color ?? "-")  sizeString:\(variant.size ?? "-")  sku:\(variant.sku ?? "-")  retailPrice:\(variant.retailPrice)  imageURLs:\(variant.imageURLs ?? "-")")
                        }
                    }
                }
                rootProduct.hasVariants = hasVariants
                dataModel.saveMoc(managedObjectContext: managedObjectContext)
                return fulfill(hasVariants)
            }
        }
    }
    
    func addRemoteId(cartOID: NSManagedObjectID) {
        NetworkingPromise.createCart().then { dict -> Void in
            guard let cartInfo = dict["cart"] as? [String : Any],
              let remoteId = cartInfo["id"] as? String else {
                print("addRemoteId failed to extract remoteId for cartOID:\(cartOID)")
                return
            }
            DataModel.sharedInstance.add(remoteId: remoteId, toCartOID: cartOID)
        }
    }
    
}


extension Cart {
    
    // TODO: GMK better error solution than print, return.
    public func update(variant: Variant, quantity: Int16) {
        let cartOID = self.objectID
        let variantOID = variant.objectID
        let dataModel = DataModel.sharedInstance
        dataModel.performBackgroundTask { managedObjectContext in
            guard let cart = managedObjectContext.object(with: cartOID) as? Cart else {
                print("Failed to retrieve cart with cartOID:\(cartOID)")
                return
            }
            guard let variantToCopy = managedObjectContext.object(with: variantOID) as? Variant else {
                print("Failed to retrieve variant with variantOID:\(variantOID)")
                return
            }
            let cartItem: CartItem
            if let sku = variantToCopy.sku,
              !sku.isEmpty,
              let item = cart.locateItem(sku: sku) {
                cartItem = item
            } else {
                cartItem = CartItem(context: managedObjectContext)
            }
            cartItem.color = variantToCopy.color
            cartItem.imageURL = variantToCopy.imageURLs?.components(separatedBy: ",").first
            cartItem.retailPrice = variantToCopy.retailPrice
            cartItem.size = variantToCopy.size
            cartItem.sku = variantToCopy.sku
            cartItem.url = variantToCopy.url
            cartItem.productDescription = variantToCopy.product?.productDescription
            cartItem.quantity = quantity
            cartItem.dateModified = NSDate()
            cartItem.cart = cart
            dataModel.saveMoc(managedObjectContext: managedObjectContext)
        }
    }
    
    // TODO: GMK better error solution than print, return.
    public func remove(item: CartItem) {
        let cartOID = self.objectID
        let cartItemOID = item.objectID
        let dataModel = DataModel.sharedInstance
        dataModel.performBackgroundTask { managedObjectContext in
            guard let cartItem = managedObjectContext.object(with: cartItemOID) as? CartItem else {
                print("Cart.remove failed to retrieve cartItem with cartItemOID:\(cartItemOID)")
                return
            }
            guard let itemCartOID = cartItem.cart?.objectID,
              itemCartOID == cartOID else {
                print("Cart.remove item.cart oid mismatched cartOID:\(cartOID)")
                return
            }
            managedObjectContext.delete(cartItem)
            dataModel.saveMoc(managedObjectContext: managedObjectContext)
        }
    }
    
    func locateItem(sku: String) -> CartItem? {
        return items?.filtered(using: NSPredicate(format: "sku == %@", sku)).firstObject as? CartItem
    }
    
}
