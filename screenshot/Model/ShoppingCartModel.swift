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
    
    func populateVariants(productOID: NSManagedObjectID) -> Promise<(Product, Bool)> {
        let dataModel = DataModel.sharedInstance
        return firstly {
            return deleteVariantsIfOld(productOID: productOID)
            }.then { partNumber -> Promise<NSDictionary> in
                return partNumber.isEmpty ? Promise(value: NSDictionary()) : NetworkingPromise.sharedInstance.getAvailableVariants(partNumber: partNumber)
            }.then { dict -> Promise<Bool> in
                guard dict.count > 0 else {
                    return Promise(value: false)
                }
                if let errorString = dict["error"] as? String {
                    let error = NSError(domain: "Craze", code: 30, userInfo: [NSLocalizedDescriptionKey : "populateVariants getAvailableVariants returned error:\(errorString)"])
                    return Promise(error: error)
                }
                return self.saveVariantsFromDictionary(productOID: productOID, dict: dict)
            }.then { didSaveVariants -> Promise<(Product, Bool)> in // Must be on main queue.
                if let product = dataModel.mainMoc().object(with: productOID) as? Product {
                    return Promise(value: (product, didSaveVariants))
                } else {
                    let error = NSError(domain: "Craze", code: 32, userInfo: [NSLocalizedDescriptionKey : "populateVariants failed to fetch a third time product:\(productOID)"])
                    print("populateVariants catch error:\(error)")
                    return Promise(error: error)
                }
            }.catch(execute: { (error) in
                
            })
    }
    
    func checkStock(screenshotOID: NSManagedObjectID) {
        let dataModel = DataModel.sharedInstance
        dataModel.partNumbers(screenshotOID: screenshotOID)
        //
            .then { partNumbers -> Promise<([[String : Any]], [String])> in
                return NetworkingPromise.sharedInstance.checkStock(partNumbers: partNumbers)
        }
        //
            .then { variantInfo, outOfStocks -> Void in
                dataModel.performBackgroundTask { managedObjectContext in
                    dataModel.markOutOfStock(managedObjectContext: managedObjectContext, partNumbers: outOfStocks)
                    variantInfo.forEach { dict in
                        if let partNumber = dict["part_number"] as? String,
                          let rootProduct = dataModel.retrieveProduct(managedObjectContext: managedObjectContext, partNumber: partNumber) {
                            dataModel.deleteVariants(managedObjectContext: managedObjectContext, product: rootProduct)
                            let _ = dataModel.saveVariantsFromDictionary(managedObjectContext: managedObjectContext, rootProduct: rootProduct, dict: dict as NSDictionary, shouldSave: false)
                        }
                    }
                    managedObjectContext.saveIfNeeded()
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
            var wasCreated = false
            if let sku = variantToCopy.sku,
                !sku.isEmpty,
                let items = cart.items as? Set<CartItem>,
                let item = items.first(where: { $0.sku == sku }) {
                cartItem = item
            } else {
                wasCreated = true
                cartItem = CartItem(context: managedObjectContext)
            }
            let oldColor = cartItem.color
            let oldSize = cartItem.size
            let oldQuantity = cartItem.quantity
            
            cartItem.color = variantToCopy.color
            cartItem.imageURL = variantToCopy.imageURLs?.components(separatedBy: ",").first
            cartItem.price = variantToCopy.price
            cartItem.size = variantToCopy.size
            cartItem.sku = variantToCopy.sku
            cartItem.url = variantToCopy.url
            cartItem.productDescription = variantToCopy.product?.productDescription
            cartItem.quantity = quantity
            cartItem.dateModified = Date()
            cartItem.product = variantToCopy.product
            cartItem.cart = cart
            
            if (oldColor == nil && cartItem.color != nil) || (oldSize == nil && cartItem.size != nil) || (oldColor != nil && cartItem.color != nil && oldColor! != cartItem.color!) || (oldSize != nil && cartItem.size != nil && oldSize! != cartItem.size!){
                Analytics.trackProductVariantChanged(cartItem: cartItem, fromSize: oldSize, fromColor: oldColor)
            }
            if oldQuantity != quantity {
                Analytics.trackProductQuantityChanged(cartItem: cartItem, from: Int(oldQuantity))
            }
            if wasCreated {
                Analytics.trackProductAddedToCart(cartItem: cartItem)
            }
            managedObjectContext.saveIfNeeded()
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
                managedObjectContext.saveIfNeeded()
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
                    return NetworkingPromise.sharedInstance.clearCart(remoteId: remoteId).then { isCleared -> Promise<[String : Any]> in
                        return Promise(value: purchaseJsonObject)
                    }
                } else {
                    return NetworkingPromise.sharedInstance.createCart().then { dict -> Promise<[String : Any]> in
                        if let cartInfo = dict["cart"] as? [String : Any],
                          let remoteId = cartInfo["id"] as? String,
                          !remoteId.isEmpty {
                            DataModel.sharedInstance.add(remoteId: remoteId, toCartOID: cartOID)
                            var completeJsonObject = purchaseJsonObject
                            completeJsonObject["id"] = remoteId
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
                return NetworkingPromise.sharedInstance.validateCart(jsonObject: jsonObject)
        }
        // Process cart validation network response.
            .then { dict -> Promise<Bool> in
                return Promise { fulfill, reject in
                    guard let cart = dict["cart"] as? [String : Any],
                      let remoteId = cart["id"] as? String,
                      //let total = self.parseFloat(cart["total"]),
                      !remoteId.isEmpty else {
                        print("ShoppingCartModel validateCart failed to extract cart id from dict:\(dict)")
                        let error = NSError(domain: "Craze", code: 45, userInfo: [NSLocalizedDescriptionKey : "ShoppingCartModel validateCart failed to extract cart id"])
                        reject(error)
                        return
                    }
                    let merchants = dict["merchants"] as? [[String : Any]] ?? []
                    dataModel.performBackgroundTask { managedObjectContext in
                        guard let cartItems = dataModel.retrieveItems(managedObjectContext: managedObjectContext, remoteId: remoteId),
                          cartItems.count > 0 else {
                            print("ShoppingCartModel validateCart failed to retrieve items for cart remoteId:\(remoteId)")
                            let error = NSError(domain: "Craze", code: 46, userInfo: [NSLocalizedDescriptionKey : "ShoppingCartModel validateCart failed to retrieve items"])
                            reject(error)
                            return
                        }
                        // Start with all cartItems errorMask as unavailable.
                        var errorDict: [String : CartItem.ErrorMaskOptions] = [:]
                        cartItems.forEach { cartItem in
                            if let sku = cartItem.sku {
                                errorDict[sku] = CartItem.ErrorMaskOptions.unavailable
                            }
                        }
                        merchants.forEach { merchant in
                            let items = merchant["items"] as? [[String : Any]]
                            items?.forEach { item in
                                if let sku = item["sku"] as? String,
                                  !sku.isEmpty,
                                  let cartItem = cartItems.first(where: {$0.sku == sku}) {
                                    var errorMask = CartItem.ErrorMaskOptions.none
                                    if let qty = item["qty"] as? Int16,
                                      cartItem.quantity != qty {
                                        cartItem.quantity = qty
                                        errorMask.insert(.quantity)
                                    }
                                    if let toPayPrice = dataModel.parseFloat(item["price"]) ?? dataModel.parseFloat(item["sale_price"]) ?? dataModel.parseFloat(item["retail_price"]),
                                      cartItem.price != toPayPrice {
                                        cartItem.price = toPayPrice
                                        errorMask.insert(.price)
                                        (cartItem.product?.availableVariants as? Set<Variant>)?.first { $0.sku == sku }?.price = toPayPrice
                                    }
                                    if cartItem.errorMask != errorMask.rawValue {
                                        cartItem.errorMask = errorMask.rawValue
                                    }
                                    errorDict[sku] = nil  // Clear unavailable.
                                }
                            }
                        }
                        // For the unavailables.
                        errorDict.keys.forEach { sku in
                            if let cartItem = cartItems.first(where:{ $0.sku == sku }) {
                                // Mark the CartItem as unavailable.
                                if let errorMask = errorDict[sku],
                                  cartItem.errorMask != errorMask.rawValue {
                                    cartItem.errorMask = errorMask.rawValue
                                }
                                // Force next populateVariants to refresh.
                                if let rootProduct = cartItem.product {
                                    dataModel.deleteVariants(managedObjectContext: managedObjectContext, product: rootProduct)
                                }
                            }
                        }
                        // Save subtotal and shippingTotal to Cart object.
                        if let cartObject = dataModel.retrieveCart(managedObjectContext: managedObjectContext, remoteId: remoteId) {
                            cartObject.subtotal =  dataModel.parseFloat(cart["subtotal"])
                                                ?? cartItems.filter({ $0.errorMask & CartItem.ErrorMaskOptions.unavailable.rawValue == 0 }).reduce(0, { $0 + $1.price })
                            cartObject.shippingTotal = dataModel.parseFloat(cart["shipping_total"]) ?? 0
                        } else {
                            print("Failed to update subtotal and shippingTotal for cart remoteId:\(remoteId)")
                        }
                        
                        let isErrorFree = cartItems.first(where: {$0.errorMask != 0}) == nil
                        managedObjectContext.saveIfNeeded()
                        fulfill(isErrorFree)
                    }
                }
        }
    }
    
    public func clearErrorMasks() {
        let dataModel = DataModel.sharedInstance
        dataModel.performBackgroundTask { managedObjectContext in
            guard let cart = dataModel.retrieveAddableCart(managedObjectContext: managedObjectContext) else {
                print("clearErrorMasks failed to retrieve cart")
                return
            }
            guard let items = cart.items as? Set<CartItem>,
              items.count > 0 else {
                print("clearErrorMasks failed to retrieve cart items")
                return
            }
            items.forEach { $0.errorMask = CartItem.ErrorMaskOptions.none.rawValue }
            managedObjectContext.saveIfNeeded()
        }
    }
    
    func checkoutCompleted(remoteId: String, cardOID: NSManagedObjectID, orderNumber: String) {
        let dataModel = DataModel.sharedInstance
        dataModel.performBackgroundTask { managedObjectContext in
            if let cart = dataModel.retrieveCart(managedObjectContext: managedObjectContext, remoteId: remoteId) {
                cart.orderNumber = orderNumber
                cart.isPastOrder = true
                let now = Date()
                cart.dateSubmitted = now
                // Write to items without changing anything, so the cartItemFrc is updated.
                (cart.items?.sortedArray(using: []) as? [CartItem])?.forEach { $0.errorMask = $0.errorMask }
                if let card = managedObjectContext.object(with: cardOID) as? Card {
                    if card.isSaved {
                        card.dateLastSuccessfulUse = now
                    } else {
                        card.delete()
                    }
                }
                managedObjectContext.saveIfNeeded()
            } else {
                print("checkoutCompleted failed to retrieve cart")
            }
        }
    }
    
    func nativeCheckout(card: Card, cvv: String, shippingAddress: ShippingAddress) -> Promise<(String, String)> {
        // Get cart remoteId, or error.
        var rememberRemoteId = ""
        let cardOID = card.objectID
        let dataModel = DataModel.sharedInstance
        return firstly {
            dataModel.retrieveForNativeCheckout()
            }
            // Wait for network to return response for processing nativeCheckout.
            .then { remoteId -> Promise<[[String : Any]]> in
                rememberRemoteId = remoteId
                return NetworkingPromise.sharedInstance.nativeCheckout(remoteId: remoteId, card: card, cvv: cvv, shippingAddress: shippingAddress)
            }
            // Extract values from response and save to DB.
            .then { nativeCheckoutResponseDict -> Promise<(String,String)> in
                let orderNumbersSet = Set<String>(nativeCheckoutResponseDict.compactMap { $0["number"] as? String })
                let orderNumber = orderNumbersSet.joined(separator: ",")
                self.checkoutCompleted(remoteId: rememberRemoteId, cardOID: cardOID, orderNumber: orderNumber)
                return Promise(value: (orderNumber, rememberRemoteId))
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
                if let dateModified = rootProduct.dateCheckedStock as Date?,
                    -dateModified.timeIntervalSinceNow <= 60 * 60 {
                    fulfill("")
                } else {
                    // Delete the old variants.
                    dataModel.deleteVariants(managedObjectContext: managedObjectContext, product: rootProduct, shouldUpdateDateChecked: false)
                    managedObjectContext.saveIfNeeded()
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
                let hasVariants = dataModel.saveVariantsFromDictionary(managedObjectContext: managedObjectContext, rootProduct: rootProduct, dict: dict)
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


extension CartItem {
    
    struct ErrorMaskOptions : OptionSet {
        let rawValue: Int16
        static let none         = ErrorMaskOptions(rawValue: 0)
        static let unavailable  = ErrorMaskOptions(rawValue: 1 << 0)
        static let quantity     = ErrorMaskOptions(rawValue: 1 << 1)
        static let price        = ErrorMaskOptions(rawValue: 1 << 2)
    }
    
}


extension Product {
    
    // Returns the new value of hasPriceAlerts as determined by the network.
    func track() -> Promise<Bool> {
        guard PermissionsManager.shared.hasPermission(for: .push) else {
            let error = NSError(domain: "Craze", code: 70, userInfo: [NSLocalizedDescriptionKey : "Product.track No push permissions"])
            print("error:\(error)")
            return Promise(error: error)
        }
        guard let pushTokenData = UserDefaults.standard.object(forKey: UserDefaultsKeys.deviceToken) as? NSData else {
            let error = NSError(domain: "Craze", code: 71, userInfo: [NSLocalizedDescriptionKey : "Product.track No pushToken"])
            print("error:\(error)")
            return Promise(error: error)
        }
        guard let partNumber = self.partNumber,
          !partNumber.isEmpty else {
            let error = NSError(domain: "Craze", code: 72, userInfo: [NSLocalizedDescriptionKey : "Product.track No partNumber"])
            print("error:\(error)")
            return Promise(error: error)
        }
        let productOID = objectID
        return NetworkingPromise.sharedInstance.registerPriceAlert(partNumber: partNumber, lastPrice: self.fallbackPrice, pushToken: pushTokenData.description, outOfStock: !self.hasVariants)
            .then { networkSucceeded -> Promise<Bool> in
                return self.priceAlertDB(productOID: productOID, networkSucceeded: networkSucceeded, successValue: true)
        }
    }
    
    // Returns the new value of hasPriceAlerts as determined by the network.
    func untrack() -> Promise<Bool> {
        guard let pushTokenData = UserDefaults.standard.object(forKey: UserDefaultsKeys.deviceToken) as? NSData else {
            let error = NSError(domain: "Craze", code: 73, userInfo: [NSLocalizedDescriptionKey : "Product.untrack No pushToken"])
            print("error:\(error)")
            return Promise(error: error)
        }
        guard let partNumber = self.partNumber,
            !partNumber.isEmpty else {
                let error = NSError(domain: "Craze", code: 74, userInfo: [NSLocalizedDescriptionKey : "Product.untrack No partNumber"])
                print("error:\(error)")
                return Promise(error: error)
        }
        let productOID = objectID
        return NetworkingPromise.sharedInstance.deregisterPriceAlert(partNumber: partNumber, pushToken: pushTokenData.description)
            .then { networkSucceeded -> Promise<Bool> in
                return self.priceAlertDB(productOID: productOID, networkSucceeded: networkSucceeded, successValue: false)
        }
    }
    
    fileprivate func priceAlertDB(productOID: NSManagedObjectID, networkSucceeded: Bool, successValue: Bool) -> Promise<Bool> {
        guard networkSucceeded else {
            let error = NSError(domain: "Craze", code: 75, userInfo: [NSLocalizedDescriptionKey : "Product.priceAlertDB Failed network for product with OID:\(productOID)"])
            print("error:\(error)")
            return Promise(error: error)
        }
        return Promise { fulfill, reject in
            DataModel.sharedInstance.performBackgroundTask { managedObjectContext in
                if let product = managedObjectContext.object(with: productOID) as? Product {
                    product.hasPriceAlerts = successValue
                    managedObjectContext.saveIfNeeded()
                    fulfill(successValue)
                } else {
                    let error = NSError(domain: "Craze", code: 76, userInfo: [NSLocalizedDescriptionKey : "Product.priceAlertDB Failed to extract product with OID:\(productOID)"])
                    print("error:\(error)")
                    reject(error)
                }
            }
        }
    }
    
}
