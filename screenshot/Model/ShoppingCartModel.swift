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
                return partNumber.isEmpty ? Promise(value: NSDictionary()) : NetworkingPromise.sharedInstance.getAvailableVariants(partNumber: partNumber)
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
    
    public func update(variant: Variant, quantity: Int16) {
        let variantOID = variant.objectID
        let dataModel = DataModel.sharedInstance
        dataModel.performBackgroundTask { managedObjectContext in
            guard let cart = dataModel.retrieveOrCreateAddableCart(managedObjectContext: managedObjectContext) else {
                print("Failed to retrieve addable cart")
                return
            }
            guard let variantToCopy = managedObjectContext.object(with: variantOID) as? Variant else {
                print("Failed to retrieve variant with OID:\(variantOID)")
                return
            }
            let cartItem: CartItem
            if let sku = variantToCopy.sku,
                !sku.isEmpty,
                let item = cart.items?.filtered(using: NSPredicate(format: "sku == %@", sku)).firstObject as? CartItem {
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
            cartItem.product = variantToCopy.product
            cartItem.cart = cart
            dataModel.saveMoc(managedObjectContext: managedObjectContext)
        }
    }
    
    public func update(cartItem: CartItem, quantity: Int16) {
        let cartItemOID = cartItem.objectID
        let dataModel = DataModel.sharedInstance
        dataModel.performBackgroundTask { managedObjectContext in
            do {
                guard let cartItemToUpdate = managedObjectContext.object(with: cartItemOID) as? CartItem else {
                    print("On update, failed to retrieve cartItem with OID:\(cartItemOID)")
                    return
                }
                try cartItemToUpdate.validateForUpdate()
                cartItemToUpdate.quantity = quantity
                try managedObjectContext.save()
            } catch {
                dataModel.receivedCoreDataError(error: error)
                print("update cartItem:\(cartItemOID) results with error:\(error)")
            }
        }
    }
    
    public func remove(item: CartItem) {
        let cartItemOID = item.objectID
        let dataModel = DataModel.sharedInstance
        dataModel.performBackgroundTask { managedObjectContext in
            guard let cartItem = managedObjectContext.object(with: cartItemOID) as? CartItem else {
                print("ShoppingCartModel failed to retrieve cartItem with OID:\(cartItemOID)")
                return
            }
            do {
                try cartItem.validateForUpdate()
                managedObjectContext.delete(cartItem)
                dataModel.saveMoc(managedObjectContext: managedObjectContext)
            } catch {
                dataModel.receivedCoreDataError(error: error)
                print("ShoppingCartModel remove item with OID:\(cartItemOID) results with error:\(error)")
            }
        }
    }
    
    public func checkout() -> Promise<Bool> {
        // Get cart purchase data. Error if cart not previously created.
        let dataModel = DataModel.sharedInstance
        return firstly {
            dataModel.retrieveForCheckout()
        }
        // Wait for network to clear cart, or get new (cart) remoteId if not previously available.
            .then { purchaseJsonObject, cartOID -> Promise<[String : Any]> in
                if let remoteId = purchaseJsonObject["id"] as? String,
                  !remoteId.isEmpty {
                    let items = purchaseJsonObject["items"] as? [[String : Any]]
                    print("ShoppingCartModel checkout successfully got \(items?.count ?? 0) items from cart with remoteId:\(remoteId)")
                    return NetworkingPromise.sharedInstance.clearCart(remoteId: remoteId).then { dict -> Promise<[String : Any]> in
                        print("clearCart returned dict:\(dict)")
                        if let code = dict["code"] as? Int,
                          code >= 200,
                          code < 300 {
                            return Promise(value: purchaseJsonObject)
                        } else {
                            print("ShoppingCartModel clearCart failed to extract code from dict:\(dict)")
                            let error = NSError(domain: "Craze", code: 44, userInfo: [NSLocalizedDescriptionKey : "ShoppingCartModel clearCart failed to extract code"])
                            return Promise(error: error)
                        }
                    }
                } else {
                    return NetworkingPromise.sharedInstance.createCart().then { dict -> Promise<[String : Any]> in
                        if let cartInfo = dict["cart"] as? [String : Any],
                          let remoteId = cartInfo["id"] as? String,
                          !remoteId.isEmpty {
                            DataModel.sharedInstance.add(remoteId: remoteId, toCartOID: cartOID)
                            var completeJsonObject = purchaseJsonObject
                            completeJsonObject["id"] = remoteId
                            let items = completeJsonObject["items"] as? [[String : Any]]
                            print("ShoppingCartModel checkout finally got \(items?.count ?? 0) items from cart with remoteId:\(remoteId)")
                            return Promise(value: completeJsonObject)
                        } else {
                            print("ShoppingCartModel checkout failed to extract remoteId from dict:\(dict)")
                            let error = NSError(domain: "Craze", code: 40, userInfo: [NSLocalizedDescriptionKey : "ShoppingCartModel checkout failed to extract remoteId"])
                            return Promise(error: error)
                        }
                    }
                }
        }
        // Wait for network to add items to remoteId.
            .then { jsonObject -> Promise<[String : Any]> in
                return NetworkingPromise.sharedInstance.checkoutCart(jsonObject: jsonObject)
        }
        // Process cart checkout network response.
            .then { dict -> Promise<Bool> in
                return Promise { fulfill, reject in
                    guard let cart = dict["cart"] as? [String : Any],
                      let remoteId = cart["id"] as? String,
                      //let total = cart["total"] as? Float,
                      let merchants = dict["merchants"] as? [[String : Any]],
                      merchants.count > 0,
                      !remoteId.isEmpty else {
                        print("ShoppingCartModel clearCart failed to extract code or merchants from dict:\(dict)")
                        let error = NSError(domain: "Craze", code: 45, userInfo: [NSLocalizedDescriptionKey : "ShoppingCartModel clearCart failed to extract cart id and total"])
                        reject(error)
                        return
                    }
                    dataModel.performBackgroundTask { managedObjectContext in
                        guard let cartItems = dataModel.retrieveItems(managedObjectContext: managedObjectContext, remoteId: remoteId),
                          cartItems.count > 0 else {
                            print("ShoppingCartModel clearCart failed to retrieve items for cart remoteId:\(remoteId)")
                            let error = NSError(domain: "Craze", code: 46, userInfo: [NSLocalizedDescriptionKey : "ShoppingCartModel clearCart failed to retrieve items"])
                            reject(error)
                            return
                        }
                        // Start with all cartItems errorMask as unavailable.
                        cartItems.forEach { $0.errorMask = (1 << 0) } // unavailable
                        merchants.forEach { merchant in
                            let items = merchant["items"] as? [[String : Any]]
                            items?.forEach { item in
                                if let sku = item["sku"] as? String,
                                  !sku.isEmpty,
                                  let cartItem = cartItems.first(where: {$0.sku == sku}) {
                                    cartItem.errorMask = 0 // Is available.
                                    if let qty = item["qty"] as? Int16,
                                      cartItem.quantity != qty {
                                        cartItem.quantity = qty
                                        cartItem.errorMask |= (1 << 1) // qty
                                    }
                                    if let price = item["price"] as? Float,
                                      cartItem.retailPrice != price {
                                        cartItem.retailPrice = price
                                        cartItem.errorMask |= (1 << 2) // price
                                    }
                                    if let color = item["color"] as? String,
                                      cartItem.color != color {
                                        cartItem.color = color
                                        cartItem.errorMask |= (1 << 3) // color
                                    }
                                    if let size = item["size"] as? String,
                                      cartItem.size != size {
                                        cartItem.size = size
                                        cartItem.errorMask |= (1 << 4) // size
                                    }
                                    print("errorMask:\(cartItem.errorMask) retailPrice:\(cartItem.retailPrice)")
                                }
                            }
                        }
                        let isErrorFree = cartItems.first(where: {$0.errorMask != 0}) == nil
                        dataModel.saveMoc(managedObjectContext: managedObjectContext)
                        fulfill(isErrorFree)
                    }
                }
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
                        if let sku = size["id"] as? String,
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
        NetworkingPromise.sharedInstance.createCart().then { dict -> Void in
            guard let cartInfo = dict["cart"] as? [String : Any],
              let remoteId = cartInfo["id"] as? String else {
                print("addRemoteId failed to extract remoteId for cartOID:\(cartOID)")
                return
            }
            DataModel.sharedInstance.add(remoteId: remoteId, toCartOID: cartOID)
        }
    }
    
}
