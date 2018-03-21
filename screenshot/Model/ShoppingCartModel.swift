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
                print("populateVariants dict:\(dict)")
                guard dict.count > 0 else {
                    return Promise(value: false)
                }
                if let errorString = dict["error"] as? String {
                    let error = NSError(domain: "Craze", code: 30, userInfo: [NSLocalizedDescriptionKey : "populateVariants getAvailableVariants returned error:\(errorString)"])
                    return Promise(error: error)
                }
                return self.saveVariantsFromDictionary(productOID: productOID, dict: dict)
            }.then { didSaveVariants -> Promise<(Product, Bool)> in // Must be on main queue.
                print("populateVariants final then clause didSaveVariants:\(didSaveVariants)")
                if let product = dataModel.mainMoc().object(with: productOID) as? Product {
                    return Promise(value: (product, didSaveVariants))
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
                let items = cart.items as? Set<CartItem>,
                let item = items.first(where: { $0.sku == sku }) {
                cartItem = item
            } else {
                cartItem = CartItem(context: managedObjectContext)
            }
            cartItem.color = variantToCopy.color
            cartItem.imageURL = variantToCopy.imageURLs?.components(separatedBy: ",").first
            cartItem.price = variantToCopy.price
            cartItem.size = variantToCopy.size
            cartItem.sku = variantToCopy.sku
            cartItem.url = variantToCopy.url
            cartItem.productDescription = variantToCopy.product?.productDescription
            cartItem.quantity = quantity
            cartItem.dateModified = NSDate()
            cartItem.product = variantToCopy.product
            cartItem.cart = cart
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
                    let items = purchaseJsonObject["items"] as? [[String : Any]]
                    print("ShoppingCartModel checkout successfully got \(items?.count ?? 0) items from cart with remoteId:\(remoteId)")
                    return NetworkingPromise.sharedInstance.clearCart(remoteId: remoteId).then { isCleared -> Promise<[String : Any]> in
                        print("clearCart returned isCleared:\(isCleared)")
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
                        var didChange = false
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
                                        didChange = true
                                    }
                                    let price = self.parseFloat(item["price"])
                                    let salePrice = self.parseFloat(item["sale_price"])
                                    let retailPrice = self.parseFloat(item["retail_price"])
                                    print("price:\(String(describing: price))  salePrice:\(String(describing: salePrice))  retailPrice:\(String(describing: retailPrice))")
                                    if let toPayPrice = price ?? salePrice ?? retailPrice,
                                      cartItem.price != toPayPrice {
                                        cartItem.price = toPayPrice
                                        errorMask.insert(.price)
                                        (cartItem.product?.availableVariants as? Set<Variant>)?.first { $0.sku == sku }?.price = toPayPrice
                                        didChange = true
                                    }
//                                    if let color = item["color"] as? String,
//                                      cartItem.color != color {
//                                        cartItem.color = color
//                                        errorMask.insert(.color)
//                                        didChange = true
//                                    }
//                                    if let size = item["size"] as? String,
//                                      cartItem.size != size {
//                                        cartItem.size = size
//                                        errorMask.insert(.size)
//                                        didChange = true
//                                    }
                                    if cartItem.errorMask != errorMask.rawValue {
                                        cartItem.errorMask = errorMask.rawValue
                                        didChange = true
                                    }
                                    errorDict[sku] = nil  // Clear unavailable.
                                    print("errorMask:\(errorMask.rawValue) price:\(cartItem.price)")
                                }
                            }
                        }
                        // Save the unavailables.
                        errorDict.keys.forEach { sku in
                            if let cartItem = cartItems.first(where:{ $0.sku == sku }),
                                let errorMask = errorDict[sku],
                                cartItem.errorMask != errorMask.rawValue {
                                cartItem.errorMask = errorMask.rawValue
                                didChange = true
                            }
                        }
                        let isErrorFree = cartItems.first(where: {$0.errorMask != 0}) == nil
                        if didChange {
                            managedObjectContext.saveIfNeeded()
                        }
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
    
    func hostedUrl() -> Promise<URL> {
        return firstly {
            return retrieveCartRemoteId()
            }.then { remoteId -> Promise<URL> in
                if !remoteId.isEmpty,
                  let returnSite = "\(Constants.shoppableThankYou)?remoteId=\(remoteId)&from=return".addingPercentEncoding(withAllowedCharacters: .alphanumerics),
                  let orderComplete = "\(Constants.shoppableThankYou)?remoteId=\(remoteId)&from=complete".addingPercentEncoding(withAllowedCharacters: .alphanumerics),
                  let publisherCheckout = Constants.shoppablePublisherCheckout.addingPercentEncoding(withAllowedCharacters: .alphanumerics),
                  let url = URL(string: "\(Constants.shoppableHosted)/checkout?cart=\(remoteId)&apiToken=\(Constants.shoppableToken)&campaign=screenshop&noiframe=0&publisherCheckout=\(publisherCheckout)&returnToSite=\(returnSite)&orderComplete=\(orderComplete)") {
                    print("hostedUrl succeeded to form url:\(url)")
                    return Promise(value: url)
                } else {
                    print("hostedUrl failed to form url for remoteId:\(remoteId)")
                    let error = NSError(domain: "Craze", code: 48, userInfo: [NSLocalizedDescriptionKey : "hostedUrl failed to form url"])
                    return Promise(error: error)
                }
        }
    }
    
    // TODO: GMK determine if 'from' matters whether Shoppable's hosted checkout redirects to returnToSite or orderComplete url.
    func hostedCompleted(remoteId: String, from: String) {
        print("hostedCompleted remoteId:\(remoteId)  from:\(from)")
        let dataModel = DataModel.sharedInstance
        dataModel.performBackgroundTask { managedObjectContext in
            if let cart = dataModel.retrieveCart(managedObjectContext: managedObjectContext, remoteId: remoteId) {
                cart.isPastOrder = true
                cart.dateSubmitted = NSDate()
                // Write to items without changing anything, so the cartItemFrc is updated.
                (cart.items?.sortedArray(using: []) as? [CartItem])?.forEach { $0.errorMask = $0.errorMask }
                managedObjectContext.saveIfNeeded()
                print("hostedCompleted cart:\(cart)")
            } else {
                print("hostedCompleted failed to retrieve cart")
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
                        managedObjectContext.saveIfNeeded()
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
                if let dictPrice = self.parseFloat(dict["price"]) ?? self.parseFloat(dict["retail_price"]) {
                    rootProduct.fallbackPrice = dictPrice
                }
                print("populateVariants altImageURLs:\(rootProduct.altImageURLs ?? "-")")
                
                var hasVariants = false
                let colors = dict["colors"] as? [[String : Any]]
                colors?.forEach { color in
                    let colorString = color["color"] as? String
                    let colorSalePrice = self.parseFloat(color["sale_price"])
                    let colorRetailPrice = self.parseFloat(color["retail_price"])
                    let colorImageURLs = (color["images"] as? [String])?.joined(separator: ",")
                    print(" colorString:\(colorString ?? "-")  colorSalePrice:\(String(describing: colorSalePrice))  colorRetailPrice:\(String(describing: colorRetailPrice))  colorImageURLs:\(colorImageURLs ?? "-")")
                    let sizes = color["sizes"] as? [[String : Any]]
                    sizes?.forEach { size in
                        if let sku = size["id"] as? String,
                          !sku.isEmpty {
                            let sizePrice = self.parseFloat(size["price"])
                            let sizeRetailPrice = self.parseFloat(size["retail_price"])
                            let variant = dataModel.saveVariant(managedObjectContext: managedObjectContext,
                                                                product: rootProduct,
                                                                color: colorString,
                                                                size: size["size"] as? String,
                                                                price: sizePrice ?? sizeRetailPrice ?? colorSalePrice ?? colorRetailPrice ?? rootProduct.fallbackPrice,
                                                                sku: sku,
                                                                url: size["url"] as? String,
                                                                imageURLs: colorImageURLs)
                            hasVariants = true
                            print("  sizeString:\(variant.size ?? "-")  sku:\(variant.sku ?? "-")  sizePrice:\(String(describing: sizePrice))  sizeRetailPrice:\(String(describing: sizeRetailPrice))  price:\(variant.price)  imageURLs:\(variant.imageURLs ?? "-")")
                        }
                    }
                }
                rootProduct.hasVariants = hasVariants
                managedObjectContext.saveIfNeeded()
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
    
    func retrieveCartRemoteId() -> Promise<String> {
        let dataModel = DataModel.sharedInstance
        return Promise { fulfill, reject in
            dataModel.performBackgroundTask { managedObjectContext in
                if let cart = dataModel.retrieveAddableCart(managedObjectContext: managedObjectContext),
                  let remoteId = cart.remoteId,
                  !remoteId.isEmpty {
                    fulfill(remoteId)
                } else {
                    print("retrieveCartRemoteId failed")
                    let error = NSError(domain: "Craze", code: 47, userInfo: [NSLocalizedDescriptionKey : "retrieveCartRemoteId failed"])
                    reject(error)
                }
            }
        }
    }
    
    func parseFloat(_ anyValueOptional: Any?) -> Float? {
        if let anyValue = anyValueOptional,
          let float = anyValue as? Float {
            return float
        }
        return nil
    }
    
}


extension CartItem {
    
    struct ErrorMaskOptions : OptionSet {
        let rawValue: Int16
        static let none         = ErrorMaskOptions(rawValue: 0)
        static let unavailable  = ErrorMaskOptions(rawValue: 1 << 0)
        static let quantity     = ErrorMaskOptions(rawValue: 1 << 1)
        static let price        = ErrorMaskOptions(rawValue: 1 << 2)
//        static let color        = ErrorMaskOptions(rawValue: 1 << 3)
//        static let size         = ErrorMaskOptions(rawValue: 1 << 4)
    }
    
}


extension Product {
    
    func track() -> Promise<Bool> {
        // TODO: GMK, Handle push notification permissions.
        guard let pushTokenData = UserDefaults.standard.object(forKey: UserDefaultsKeys.deviceToken) as? NSData else {
            let error = NSError(domain: "Craze", code: 70, userInfo: [NSLocalizedDescriptionKey : "No pushToken"])
            print("Product.track error:\(error)")
            return Promise(error: error)
        }
        guard let partNumber = self.partNumber,
          !partNumber.isEmpty else {
            let error = NSError(domain: "Craze", code: 71, userInfo: [NSLocalizedDescriptionKey : "No partNumber"])
            print("Product.track error:\(error)")
            return Promise(error: error)
        }
        let productOID = objectID
        return NetworkingPromise.sharedInstance.registerPriceAlert(partNumber: partNumber, lastPrice: self.fallbackPrice, pushToken: pushTokenData.description, outOfStock: !self.hasVariants)
            .then { networkSucceeded -> Promise<Bool> in
                let dataModel = DataModel.sharedInstance
                return Promise { fulfill, reject in
                    dataModel.performBackgroundTask { managedObjectContext in
                        if let product = managedObjectContext.object(with: productOID) as? Product {
                            product.hasPriceAlerts = networkSucceeded
                            fulfill(true)
                        } else {
                            let error = NSError(domain: "Craze", code: 72, userInfo: [NSLocalizedDescriptionKey : "Product.track failed to extract product with OID:\(productOID)"])
                            print("Product.track error:\(error)")
                            reject(error)
                        }
                    }
                }
        }
    }
    
    func untrack() -> Promise<Bool> {
        return Promise(value: true)
    }
    
}
