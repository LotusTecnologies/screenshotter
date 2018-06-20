//
//  DataModel.swift
//  screenshot
//
//  Created by Gershon Kagan on 8/9/17.
//  Copyright (c) 2017 crazeapp. All rights reserved.
//

import UIKit
import CoreData
import PromiseKit
import SwiftKeychainWrapper

class DataModel: NSObject {
    
    public static let sharedInstance = DataModel()
    public static func setup() {
        let _ = DataModel.sharedInstance
    }
    
    
    public let persistentContainer = NSPersistentContainer(name: "Model")
    
    func mainMoc() -> NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    
    
    // See https://stackoverflow.com/questions/42733574/nspersistentcontainer-concurrency-for-saving-to-core-data . Go Rose!
    let dbQ:OperationQueue = {
       let queue = OperationQueue.init()
        queue.maxConcurrentOperationCount = 1
        queue.name = "Core data queue"
        queue.isSuspended = true
        return queue
    }()
    func sqlFileUrl() -> URL {
        return NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("Model.sqlite")
    }
    
    func deleteDatabase() -> Promise<Bool> {
        let sqliteURL = self.sqlFileUrl()
        return Promise.init(resolvers: { (fulfill, reject) in
            do {
                try self.persistentContainer.persistentStoreCoordinator.destroyPersistentStore(at: sqliteURL, ofType: NSSQLiteStoreType, options: [:])
                fulfill(true)
            }catch{
                reject(error)
            }
        })
    }
    
    func loadStore(multipleAttempts:Int) -> Promise<Bool>{
        return loadingStore(attempt: 1, maxTries: multipleAttempts)
    }
    
    private func loadingStore(attempt:Int, maxTries:Int) -> Promise<Bool>{
        return Promise.init(resolvers: { (fulfill, reject) in
            if attempt > maxTries {
                let error = NSError.init(domain: "Craze", code: -100, userInfo: [NSLocalizedDescriptionKey:"max load store attempts exceeded"])
                reject(error)
            }else{
                self.loadStore(sync: true).then(execute: { (success) -> (Void) in
                    fulfill(success)
                }).catch(execute: { (error) in
                    self.loadingStore(attempt: attempt + 1, maxTries: maxTries).then(execute: { (success) -> (Void) in
                        fulfill(success)
                    }).catch(execute: { (error) in
                        reject(error)
                    })
                })
            }
        })
    }
    
    func loadStore(sync:Bool) -> Promise<Bool>{
        let sqliteURL = self.sqlFileUrl()

        let storeInfo = NSPersistentStoreDescription.init(url: sqliteURL)
        storeInfo.shouldAddStoreAsynchronously = !sync
        self.persistentContainer.persistentStoreDescriptions = [storeInfo]
        return Promise.init(resolvers: { (fulfill, reject) in
            self.persistentContainer.loadPersistentStores { (storeDescription, error) in
                if let error = error as NSError? {
                    print("loadPersistentStores error:\(error)")
                    self.receivedCoreDataError(error:error)

                    reject(error)
                } else {
                    self.persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
                    let lastDbVersionMigrated = UserDefaults.standard.integer(forKey: UserDefaultsKeys.lastDbVersionMigrated)
                    if lastDbVersionMigrated != Constants.currentMomVersion {
                        self.postDbMigration(from: lastDbVersionMigrated, to: Constants.currentMomVersion, container: self.persistentContainer)
                        UserDefaults.standard.set(Constants.currentMomVersion, forKey: UserDefaultsKeys.lastDbVersionMigrated)
                    }
                    MatchstickModel.shared.prepareMatchsticks()
                    self.dbQ.isSuspended = false
                    
                    fulfill(true)
                }
            }
        })
       
    }
    
    func storeNeedsMigration() -> Bool {
        let sqliteURL = self.sqlFileUrl()
        do{

            let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: sqliteURL, options: nil)
            let model = self.persistentContainer.managedObjectModel
            return !model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
        }catch{
            self.receivedCoreDataError(error:error) // this will log. 

        }
        return false
    }
    
}
extension DataModel {
    func receivedCoreDataError(error:Error) {
        let error = error as NSError
        if error.domain == NSSQLiteErrorDomain && error.code == 13{ // disk full  see https://sqlite.org/c3ref/c_abort.html
            Analytics.trackError(type: .noHardDriveSpace, domain: error.domain, code: error.code, localizedDescription: error.localizedDescription)
            DispatchQueue.main.async {
                AppDelegate.shared.presentLowDiskSpaceWarning()
            }
        }else{
            Analytics.trackError(type: nil, domain: error.domain, code: error.code, localizedDescription: error.localizedDescription)
        }
    }
}

extension DataModel {
    
    // Save a new Screenshot to Core Data.
    func saveScreenshot(managedObjectContext: NSManagedObjectContext,
                        assetId: String,
                        createdAt: Date?,
                        isRecognized: Bool,
                        source: ScreenshotSource,
                        isHidden: Bool,
                        imageData: Data?,
                        uploadedImageURL: String?,
                        syteJsonString: String?) -> Screenshot {
        let screenshotToSave = Screenshot(context: managedObjectContext)
        screenshotToSave.assetId = assetId
        screenshotToSave.createdAt = createdAt
        screenshotToSave.isRecognized = isRecognized
        screenshotToSave.source = source
        screenshotToSave.isHidden = isHidden
        screenshotToSave.isNew = true
        screenshotToSave.imageData = imageData
        screenshotToSave.uploadedImageURL = uploadedImageURL
        screenshotToSave.syteJson = syteJsonString

        screenshotToSave.lastModified = Date()
        do {
            try managedObjectContext.save()
        } catch {
            self.receivedCoreDataError(error: error)
            print("Failed to saveScreenshot")
        }
        return screenshotToSave
    }
    
    
    func retrieveAllAssetIds(managedObjectContext: NSManagedObjectContext) -> Set<String> {
        return retrieveAssetIds(managedObjectContext: managedObjectContext, predicate: nil)
    }
    
    func retrieveCompleteAssetIds(managedObjectContext: NSManagedObjectContext) -> Set<String> {
        return retrieveAssetIds(managedObjectContext: managedObjectContext, predicate: NSPredicate(format: "isRecognized != nil"))
    }
    
    func retrieveHiddenAssetIds(managedObjectContext: NSManagedObjectContext) -> Set<String> {
        return retrieveAssetIds(managedObjectContext: managedObjectContext, predicate: NSPredicate(format: "isHidden == TRUE"))
    }
 
    
    func retrieveAssetIds(assetIds:[String], managedObjectContext: NSManagedObjectContext) -> Set<String> {
        let predicate = NSPredicate(format: "assetId IN %@", assetIds)
        return retrieveAssetIds(managedObjectContext: managedObjectContext, predicate: predicate)
    }
    
    func retrieveAssetIds(managedObjectContext: NSManagedObjectContext, predicate: NSPredicate?) -> Set<String> {
        let fetchRequest:NSFetchRequest<Screenshot> = Screenshot.fetchRequest()
        fetchRequest.predicate = predicate
        fetchRequest.includesSubentities = false
        
        var assetIdsSet = Set<String>()
        do {
            let results = try managedObjectContext.fetch(fetchRequest)
            for result in results {
                if let assetId = result.assetId {
                    assetIdsSet.insert(assetId)
                }
            }
            
         
        } catch {
            self.receivedCoreDataError(error: error)
            print("retrieveAssetIds results with error:\(error)")
        }
        return assetIdsSet
    }
    
    func retrieveScreenshot(managedObjectContext: NSManagedObjectContext, assetId: String) -> Screenshot? {
        let fetchRequest: NSFetchRequest<Screenshot> = Screenshot.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "assetId == %@", assetId)
        fetchRequest.sortDescriptors = nil //[NSSortDescriptor(key: "createdAt", ascending: false)]
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try managedObjectContext.fetch(fetchRequest)
            return results.first
        } catch {
            self.receivedCoreDataError(error: error)
            print("retrieveScreenshot assetId:\(assetId) results with error:\(error)")
        }
        return nil
    }
    
    public func hideFromProductBar(_ productObjectIDs: [NSManagedObjectID]) {
        performBackgroundTask { (managedObjectContext) in
            do {
                productObjectIDs.forEach { productObjectId in
                    if let product = managedObjectContext.object(with: productObjectId) as? Product {
                        do{
                            try product.validateForUpdate()
                            product.hideFromProductBar = true
                        } catch{

                        }
                        
                        
                    }
                }
                try managedObjectContext.save()
            } catch {
                self.receivedCoreDataError(error: error)
                print("hideFromProductBar productObjectIDs catch error:\(error)")
            }
        }
    }
    
    public func hide(screenshotOIDArray: [NSManagedObjectID], kind:Analytics.AnalyticsScreenshotDeletedKind) {
        performBackgroundTask { (managedObjectContext) in
            do {
                screenshotOIDArray.forEach { screenshotOID in
                    if let screenshot = managedObjectContext.object(with: screenshotOID) as? Screenshot {
                        Analytics.trackScreenshotDeleted(screenshot: screenshot, kind: kind)
                        do{
                            try screenshot.validateForUpdate()
                            screenshot.isHidden = true
                            screenshot.hideWorkhorse()
                            UserAccountManager.shared.deleteScreenshot(screenshot: screenshot)
                        } catch{
                            
                        }
                    }
                }
                let request:NSFetchRequest<Screenshot> = Screenshot.fetchRequest()
                request.predicate = NSPredicate(format: "isHidden == FALSE AND isRecognized == TRUE AND sourceString != %@", ScreenshotSource.shuffle.rawValue)
                if let count =  try? managedObjectContext.count(for: request) {
                    if count == 0{
                        //convert from different enums
                        let kind:Analytics.AnalyticsScreenshotDeletedAllKind = (kind == .single) ? .single : .multi
                        Analytics.trackScreenshotDeletedAll(amountJustDeleted: screenshotOIDArray.count, kind:kind)
                    }
                }

                try managedObjectContext.save()
            } catch {
                self.receivedCoreDataError(error: error)
                print("hide screenshotOIDArray catch error:\(error)")
            }
            
        }
    }
    
    // Save a new Shoppable to Core Data.
    func saveShoppable(managedObjectContext: NSManagedObjectContext,
                       screenshot: Screenshot,
                       label: String?,
                       offersURL: String?,
                       relatedImagesURL: String?,
                       b0x: Double,
                       b0y: Double,
                       b1x: Double,
                       b1y: Double,
                       optionsMask: ProductsOptionsMask) -> Shoppable {
        let shoppableToSave = Shoppable(context: managedObjectContext)
        shoppableToSave.screenshot = screenshot
        let spellingMap = ["Bodypart" : "Body Part",
                           "Cufflings" : "Cufflinks",
                           "GlovesAndMitten" : "Gloves/Mittens",
                           "Neclesses" : "Necklaces",
                           "NightMorning" : "Nightgowns",
                           "NonFashion_HeadPhone" : "Headphones",
                           "NonFashion_PhoneCover" : "Phone Covers",
                           "NonFashion_Suitcases" : "Suitcases",
                           "PouchBag" : "Pouch Bags",
                           "Scarfs" : "Scarves",
                           "SocksAndTights" : "Socks/Tights",
                           "SportShoes" : "Sport Shoes",
                           "Vestes" : "Vests",
                           "WalletsPurses" : "Wallets/Purses"]
        if let label = label, let correctedSpelling = spellingMap[label] {
            shoppableToSave.label = correctedSpelling
        } else {
            shoppableToSave.label = label
        }
        let priorityMap = ["Dresses" : "01", "Jumpsuits" : "02", "NightMorning" : "03", "Swimwear" : "04",
                           "Shirts" : "05", "Trousers" : "06", "Shorts" : "07", "Skirts" : "08",
                           "Jackets" : "09", "Coats" : "10", "Vestes" : "11", "Backpacks" : "12",
                           "Bags" : "13", "PouchBag" : "14", "WalletsPurses" : "15", "Shoes" : "16",
                           "Boots" : "17", "SportShoes" : "18", "Scarfs" : "19", "Belts" : "20",
                           "Bracelets" : "21", "Neclesses" : "22", "Earrings" : "23", "Rings" : "24",
                           "Cufflings" : "25", "Sunglasses" : "26", "Hats" : "27", "Ties" : "28",
                           "Makeup" : "29", "NonFashion_Suitcases" : "30", "GlovesAndMitten" : "31", "SocksAndTights" : "32",
                           // Not ordered by Molly
            "Bodypart" : "33", "NonFashion_PhoneCover" : "34", "NonFashion_HeadPhone" : "35", "Underwear" : "36", "Watches" : "37"]
        if let label = label, let priorityOrder = priorityMap[label] {
            shoppableToSave.order = priorityOrder
        } else {
            shoppableToSave.order = shoppableToSave.label
        }
        shoppableToSave.relatedImagesURLString = relatedImagesURL
        shoppableToSave.offersURL = offersURL
        shoppableToSave.b0x = b0x
        shoppableToSave.b0y = b0y
        shoppableToSave.b1x = b1x
        shoppableToSave.b1y = b1y
        shoppableToSave.addProductFilter(managedObjectContext: managedObjectContext, optionsMask: optionsMask)
        return shoppableToSave
    }
    
    func retrieveShoppable(managedObjectContext: NSManagedObjectContext, objectId: NSManagedObjectID) -> Shoppable? {
        let fetchRequest: NSFetchRequest<Shoppable> = Shoppable.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "SELF == %@", objectId)
        fetchRequest.sortDescriptors = nil
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try managedObjectContext.fetch(fetchRequest)
            return results.first
        } catch {
            self.receivedCoreDataError(error: error)
            print("retrieveShoppable objectId:\(objectId) results with error:\(error)")
        }
        return nil
    }
    
    // Save a new Product to Core Data.
    func saveProduct(managedObjectContext: NSManagedObjectContext,
                     shoppable: Shoppable?,
                     order: Int16,
                     productDescription: String?,
                     price: String?,
                     originalPrice: String?,
                     floatPrice: Float,
                     floatOriginalPrice: Float,
                     categories: String?,
                     brand: String?,
                     offer: String?,
                     imageURL: String?,
                     merchant: String?,
                     partNumber: String?,
                     color: String?,
                     sku: String?,
                     fallbackPrice: Float,
                     optionsMask: Int32) -> Product {
        let productToSave = Product(context: managedObjectContext)
        productToSave.shoppable = shoppable
        productToSave.order = order
        productToSave.productDescription = productDescription
        productToSave.price = price
        productToSave.originalPrice = originalPrice
        productToSave.floatPrice = floatPrice
        productToSave.floatOriginalPrice = floatOriginalPrice
        productToSave.categories = categories
        productToSave.brand = brand
        productToSave.offer = offer
        productToSave.imageURL = imageURL
        productToSave.merchant = merchant
        productToSave.partNumber = partNumber
        productToSave.color = color
        productToSave.sku = sku
        productToSave.fallbackPrice = fallbackPrice
        productToSave.optionsMask = optionsMask
        productToSave.dateRetrieved = Date()
        return productToSave
    }
    
    func retrieveProduct(managedObjectContext: NSManagedObjectContext, partNumber: String) -> Product? {
        let fetchRequest: NSFetchRequest<Product> = Product.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "partNumber == %@", partNumber)
        fetchRequest.sortDescriptors = nil //[NSSortDescriptor(key: "createdAt", ascending: false)]
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try managedObjectContext.fetch(fetchRequest)
            return results.first
        } catch {
            self.receivedCoreDataError(error: error)
            print("retrieveProduct partNumber:\(partNumber) results with error:\(error)")
        }
        return nil
    }
    
    func deleteVariants(managedObjectContext: NSManagedObjectContext, product: Product, shouldUpdateDateChecked: Bool = true) {
        if shouldUpdateDateChecked {
            product.dateCheckedStock = Date()
        }
        if product.hasVariants {
            let variants = product.availableVariants as? Set<Variant>
            variants?.forEach { managedObjectContext.delete($0) }
            product.hasVariants = false
        }
    }
    
    func partNumbers(screenshotOID: NSManagedObjectID) -> Promise<[String]> {
        return Promise { fulfill, reject in
            self.performBackgroundTask { managedObjectContext in
                let fetchRequest: NSFetchRequest<NSDictionary> = NSFetchRequest(entityName: "Product")
                fetchRequest.resultType = .dictionaryResultType
                fetchRequest.returnsObjectsAsFaults = false
                fetchRequest.includesSubentities = false
                fetchRequest.returnsDistinctResults = true
                fetchRequest.propertiesToFetch = ["partNumber"]
                fetchRequest.fetchLimit = 600
                let optionsMaskInt = ProductsOptionsMask.global.rawValue
                let anHourAgo = NSDate(timeIntervalSinceNow: -60 * 60)
                fetchRequest.predicate = NSPredicate(format: "shoppable.screenshot == %@ AND (optionsMask & %d) == %d AND ( dateCheckedStock == nil || dateCheckedStock < %@ )", screenshotOID, optionsMaskInt, optionsMaskInt, anHourAgo)
                fetchRequest.sortDescriptors = nil
                
                do {
                    let results = try managedObjectContext.fetch(fetchRequest)
                    let partNumbers = results.compactMap { $0["partNumber"] as? String }
                    if partNumbers.count > 0 {
                        fulfill(partNumbers)
                        return
                    }
                } catch {
                    self.receivedCoreDataError(error: error)
                    print("partNumbers results with error:\(error)")
                }
                let error = NSError(domain: "Craze", code: 78, userInfo: [NSLocalizedDescriptionKey : "No partNumbers to check."])
                reject(error)
            }
        }
    }
    
    func markOutOfStock(managedObjectContext: NSManagedObjectContext, partNumbers: [String]) {
        guard partNumbers.count > 0 else {
            return
        }
        
        let fetchRequest: NSFetchRequest<Product> = Product.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "partNumber IN %@", partNumbers)
        
        do {
            let results = try managedObjectContext.fetch(fetchRequest)
            results.forEach { deleteVariants(managedObjectContext: managedObjectContext, product: $0) }
            managedObjectContext.saveIfNeeded()
        } catch {
            self.receivedCoreDataError(error: error)
            print("markOutOfStock results with error:\(error)")
        }
    }
    
    func parseFloat(_ anyValueOptional: Any?) -> Float? {
        if anyValueOptional == nil {
            return nil
        } else if let floatVal = anyValueOptional as? Float {
            return floatVal
        } else if let intVal = anyValueOptional as? Int {
            return Float(intVal)
        } else if let stringVal = anyValueOptional as? String {
            return Float(stringVal)
        } else if let nsNumber = anyValueOptional as? NSNumber {
            return nsNumber.floatValue
        } else if let anyValue = anyValueOptional {
            print("parseFloat received anyValueOptional:\(String(describing: anyValueOptional))  anyValue:\(anyValue) type:\(type(of: anyValueOptional))")
        }
        return nil
    }

    // Save a new Variant to Core Data.
    func saveVariant(managedObjectContext: NSManagedObjectContext,
                     product: Product,
                     color: String?,
                     size: String?,
                     price: Float,
                     sku: String,
                     url: String?,
                     imageURLs: String?) -> Variant {
        let variantToSave = Variant(context: managedObjectContext)
        variantToSave.product = product
        variantToSave.color = color
        variantToSave.size = size
        variantToSave.price = price
        variantToSave.sku = sku
        variantToSave.url = url
        variantToSave.imageURLs = imageURLs
        return variantToSave
    }
    
    func saveVariantsFromDictionary(managedObjectContext: NSManagedObjectContext, rootProduct: Product, dict: NSDictionary, shouldSave: Bool = true) -> Bool {
        rootProduct.altImageURLs = (dict["alt_images"] as? [String])?.joined(separator: ",")
        rootProduct.detailedDescription = dict["description"] as? String
        rootProduct.name = dict["name"] as? String
        rootProduct.url = dict["url"] as? String
        if let dictPrice = self.parseFloat(dict["price"]) ?? self.parseFloat(dict["discount_price"]) ?? self.parseFloat(dict["retail_price"]) {
            rootProduct.fallbackPrice = dictPrice
        }
        
        var hasVariants = false
        let colors = dict["colors"] as? [[String : Any]]
        colors?.forEach { color in
            let colorString = color["color"] as? String
            let colorPrice = self.parseFloat(color["sale_price"]) ?? self.parseFloat(color["retail_price"]) ?? rootProduct.fallbackPrice
            let colorImageURLs = (color["images"] as? [String])?.joined(separator: ",")
            let sizes = color["sizes"] as? [[String : Any]]
            sizes?.forEach { size in
                if let sku = size["id"] as? String,
                    !sku.isEmpty {
                    let _ = self.saveVariant(managedObjectContext: managedObjectContext,
                                             product: rootProduct,
                                             color: colorString,
                                             size: size["size"] as? String,
                                             price: self.parseFloat(size["price"])
                                                ?? self.parseFloat(size["discount_price"])
                                                ?? self.parseFloat(size["retail_price"])
                                                ?? colorPrice,
                                             sku: sku,
                                             url: size["url"] as? String,
                                             imageURLs: colorImageURLs)
                    hasVariants = true
                    if rootProduct.sku == sku,
                        let updatedColor = colorString,
                        !updatedColor.isEmpty,
                        rootProduct.color != updatedColor {
                        rootProduct.color = updatedColor
                    }
                }
            }
        }
        rootProduct.hasVariants = hasVariants
        rootProduct.dateCheckedStock = Date()
        if shouldSave {
            managedObjectContext.saveIfNeeded()
        }
        return hasVariants
    }
    
    func retrieveAddableCart(managedObjectContext: NSManagedObjectContext) -> Cart? {
        let fetchRequest: NSFetchRequest<Cart> = Cart.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isPastOrder == FALSE")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateModified", ascending: false)]
        fetchRequest.fetchBatchSize = 1
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try managedObjectContext.fetch(fetchRequest)
            if let mostRecentAddableCart = results.first {
                return mostRecentAddableCart
            }
        } catch {
            self.receivedCoreDataError(error: error)
            print("retrieveAddableCart results with error:\(error)")
        }
        return nil
    }
    
    func retrieveCart(managedObjectContext: NSManagedObjectContext, remoteId: String) -> Cart? {
        let fetchRequest: NSFetchRequest<Cart> = Cart.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "remoteId == %@", remoteId)
        fetchRequest.sortDescriptors = nil
        fetchRequest.fetchBatchSize = 1
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try managedObjectContext.fetch(fetchRequest)
            if let cart = results.first {
                return cart
            }
        } catch {
            self.receivedCoreDataError(error: error)
            print("retrieveAddableCart results with error:\(error)")
        }
        return nil
    }
    
    func retrieveOrCreateAddableCart(managedObjectContext: NSManagedObjectContext) -> Cart? {
        if let mostRecentAddableCart = retrieveAddableCart(managedObjectContext: managedObjectContext) {
            return mostRecentAddableCart
        } else {
            do {
                let cartToSave = Cart(context: managedObjectContext)
                cartToSave.dateModified = Date()
                try managedObjectContext.save()
                // Return quickly; add remoteId leisurely.
                ShoppingCartModel.shared.addRemoteId(cartOID: cartToSave.objectID)
                return cartToSave
            } catch {
                self.receivedCoreDataError(error: error)
                print("retrieveOrCreateAddableCart results with error:\(error)")
            }
            return nil
        }
    }

    func retrieveItems(managedObjectContext: NSManagedObjectContext, remoteId: String) -> [CartItem]? {
        let fetchRequest: NSFetchRequest<CartItem> = CartItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "cart.remoteId == %@", remoteId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateModified", ascending: false)]

        do {
            let results = try managedObjectContext.fetch(fetchRequest)
            return results
        } catch {
            self.receivedCoreDataError(error: error)
            print("retrieveItems results with error:\(error)")
        }
        return nil
    }
    
    // Errors if cart not previously created. Okay if cart has no remoteId.
    func retrieveForCheckout() -> Promise<([String : Any], NSManagedObjectID)> {
        return Promise { fulfill, reject in
            performBackgroundTask { (managedObjectContext) in
                guard let cart = self.retrieveAddableCart(managedObjectContext: managedObjectContext),
                  let items = cart.items?.sortedArray(using: []) as? [CartItem],
                  items.count > 0 else {
                    let error = NSError(domain: "Craze", code: 38, userInfo: [NSLocalizedDescriptionKey : "No cart with cartItems before checkout."])
                    reject(error)
                    return
                }
                var purchaseItems: [[String : Any]] = []
                for item in items {
                    let quantity = item.quantity
                    if let sku = item.sku,
                        !sku.isEmpty,
                        quantity > 0 {
                        purchaseItems.append(["sku" : sku, "qty" : quantity])
                    }
                }
                guard purchaseItems.count > 0 else {
                    let error = NSError(domain: "Craze", code: 39, userInfo: [NSLocalizedDescriptionKey : "No cartItems with sku and positive quantity to checkout."])
                    reject(error)
                    return
                }
                fulfill((["id" : cart.remoteId ?? "", "items" : purchaseItems], cart.objectID))
            }
        }
    }
    
    // Errors if cart has no remoteId.
    func retrieveForNativeCheckout() -> Promise<String> {
        return Promise { fulfill, reject in
            performBackgroundTask { (managedObjectContext) in
                if let cart = self.retrieveAddableCart(managedObjectContext: managedObjectContext),
                  let remoteId = cart.remoteId,
                  !remoteId.isEmpty {
                    fulfill(remoteId)
                } else {
                    let error = NSError(domain: "Craze", code: 80, userInfo: [NSLocalizedDescriptionKey : "nativeCheckout with no remoteId"])
                    reject(error)
                }
            }
        }
    }
    
    func add(remoteId: String, toCartOID: NSManagedObjectID) {
        performBackgroundTask { (managedObjectContext) in
            do {
                guard let cart = managedObjectContext.object(with: toCartOID) as? Cart,
                  cart.remoteId == nil else {
                        return
                }
                cart.remoteId = remoteId
                try managedObjectContext.save()
            } catch {
                DataModel.sharedInstance.receivedCoreDataError(error: error)
                print("add remoteId:\(remoteId) toCartOID:\(toCartOID) results with error:\(error)")
            }
        }
    }
    
    func saveMatchstick(managedObjectContext: NSManagedObjectContext,
                        remoteId: String,
                        imageUrl: String,
                        syteJson: String,
                        trackingInfo: String?) -> Matchstick {
        let matchstickToSave = Matchstick(context: managedObjectContext)
        matchstickToSave.remoteId = remoteId
        matchstickToSave.imageUrl = imageUrl
        matchstickToSave.syteJson = syteJson
        matchstickToSave.receivedAt = Date()
        matchstickToSave.trackingInfo = trackingInfo
        return matchstickToSave
    }
    
    func addImageDataToMatchstick(managedObjectContext: NSManagedObjectContext, imageUrl: String, imageData: Data) {
        let fetchRequest: NSFetchRequest<Matchstick> = Matchstick.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "imageUrl == %@", imageUrl)
        fetchRequest.sortDescriptors = nil
        
        do {
            let results = try managedObjectContext.fetch(fetchRequest)
            for matchstick in results {
                matchstick.imageData = imageData
                matchstick.receivedAt = Date()
            }
            try managedObjectContext.save()
        } catch {
            self.receivedCoreDataError(error: error)
            print("addImageDataToMatchstick imageUrl:\(imageUrl) results with error:\(error)")
        }
    }
    
    func retrieveMatchstickImageUrlsWithNoData(managedObjectContext: NSManagedObjectContext) -> [String] {
        let fetchRequest: NSFetchRequest<Matchstick> = Matchstick.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "imageData == nil")
        fetchRequest.sortDescriptors = nil
        
        do {
            let results = try managedObjectContext.fetch(fetchRequest)
            if let imageUrls = results.compactMap({$0.imageUrl}).compactMap({$0.copy()}) as? [String] {
                return imageUrls
            }
        } catch {
            self.receivedCoreDataError(error: error)
            print("retrieveMatchstickImageUrlsWithNoData results with error:\(error)")
        }
        return []
    }
    
    func deleteMatchstick(managedObjectContext: NSManagedObjectContext, imageUrl: String) {
        let fetchRequest: NSFetchRequest<Matchstick> = Matchstick.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "imageUrl == %@", imageUrl)
        fetchRequest.sortDescriptors = nil
        
        do {
            let results = try managedObjectContext.fetch(fetchRequest)
            results.forEach { managedObjectContext.delete($0) }
            managedObjectContext.saveIfNeeded()
        } catch {
            self.receivedCoreDataError(error: error)
            print("deleteMatchstick imageUrl:\(imageUrl) results with error:\(error)")
        }
    }
    
    // Returns a Promise of the saved Card that should be used only on the main thread.
    func saveCard(fullName: String,
                  number: String,
                  displayNumber: String,
                  brand: String,
                  expirationMonth: Int16,
                  expirationYear: Int16,
                  street: String,
                  city: String,
                  country: String,
                  zipCode: String,
                  state: String?,
                  email: String?,
                  phone: String,
                  isSaved: Bool) -> Promise<Card> {
        return Promise<NSManagedObjectID> { fulfill, reject in
            performBackgroundTask { (managedObjectContext) in
                let cardToSave = Card(context: managedObjectContext)
                cardToSave.fullName = fullName
                cardToSave.displayNumber = displayNumber
                cardToSave.brand = brand
                cardToSave.expirationMonth = expirationMonth
                cardToSave.expirationYear = expirationYear
                cardToSave.street = street
                cardToSave.city = city
                cardToSave.country = country
                cardToSave.zipCode = zipCode
                cardToSave.state = state
                cardToSave.email = email
                cardToSave.phone = phone
                cardToSave.isSaved = isSaved
                let now = Date()
                cardToSave.dateAdded = now
                cardToSave.dateModified = now
                do {
                    try managedObjectContext.save()
                    let key = cardToSave.cardNumberKeychainKey()
                    DispatchQueue.global(qos: .utility).async {
                        KeychainWrapper.standard.set(number, forKey: key)
                    }
                    fulfill(cardToSave.objectID)
                } catch {
                    DataModel.sharedInstance.receivedCoreDataError(error: error)
                    reject(error)
                }
            }
            }.then { cardOID -> Promise<Card> in // Defaults to executing on main thread. Good.
                guard let savedCard = self.mainMoc().object(with: cardOID) as? Card else {
                    let error = NSError(domain: "Craze", code: 90, userInfo: [NSLocalizedDescriptionKey: "Cannot retrieve recent savedCard oid:\(cardOID)"])
                    return Promise(error: error)
                }
                return Promise(value: savedCard)
        }
    }

    // Must be run from main thread!!
    func hasSavedCards() -> Bool {
        let fetchRequest: NSFetchRequest<Card> = Card.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isSaved == TRUE")
        fetchRequest.sortDescriptors = nil
        fetchRequest.fetchLimit = 1
        fetchRequest.includesSubentities = false
        fetchRequest.includesPropertyValues = false
        
        do {
            let count = try mainMoc().count(for: fetchRequest)
            return count > 0
        } catch {
            self.receivedCoreDataError(error: error)
            print("hasSavedCards results with error:\(error)")
        }
        return false
    }

    // Must be run from main thread!!
    func hasShippingAddresses() -> Bool {
        let fetchRequest: NSFetchRequest<ShippingAddress> = ShippingAddress.fetchRequest()
        fetchRequest.predicate = nil
        fetchRequest.sortDescriptors = nil
        fetchRequest.fetchLimit = 1
        fetchRequest.includesSubentities = false
        fetchRequest.includesPropertyValues = false
        
        do {
            let count = try mainMoc().count(for: fetchRequest)
            return count > 0
        } catch {
            self.receivedCoreDataError(error: error)
            print("hasShippingAddresses results with error:\(error)")
        }
        return false
    }
    
    var selectedCardURL: URL? {
        set {
            UserDefaults.standard.set(newValue, forKey: "checkoutPrimaryCardURL")
            UserDefaults.standard.synchronize()
        }
        get {
            return UserDefaults.standard.url(forKey: "checkoutPrimaryCardURL")
        }
    }
    
    var selectedShippingAddressURL: URL? {
        set {
            UserDefaults.standard.set(newValue, forKey: "checkoutPrimaryAddressURL")
            UserDefaults.standard.synchronize()
        }
        get {
            return UserDefaults.standard.url(forKey: "checkoutPrimaryAddressURL")
        }
    }

    // Returns a Promise of the saved ShippingAddress that should be used only on the main thread.
    func saveShippingAddress(firstName: String?,
                             lastName: String?,
                             street: String,
                             city: String,
                             country: String,
                             zipCode: String,
                             state: String?,
                             phone: String) -> Promise<ShippingAddress> {
        return Promise<NSManagedObjectID> { fulfill, reject in
            performBackgroundTask { (managedObjectContext) in
                let shippingAddressToSave = ShippingAddress(context: managedObjectContext)
                shippingAddressToSave.firstName = firstName
                shippingAddressToSave.lastName = lastName
                shippingAddressToSave.street = street
                shippingAddressToSave.city = city
                shippingAddressToSave.country = country
                shippingAddressToSave.zipCode = zipCode
                shippingAddressToSave.state = state
                shippingAddressToSave.phone = phone
                let now = Date()
                shippingAddressToSave.dateAdded = now
                shippingAddressToSave.dateModified = now
                do {
                    try managedObjectContext.save()
                    fulfill(shippingAddressToSave.objectID)
                } catch {
                    DataModel.sharedInstance.receivedCoreDataError(error: error)
                    reject(error)
                }
            }
            }.then { shippingAddressOID -> Promise<ShippingAddress> in // Defaults to executing on main thread. Good.
                guard let savedShippingAddress = self.mainMoc().object(with: shippingAddressOID) as? ShippingAddress else {
                    let error = NSError(domain: "Craze", code: 91, userInfo: [NSLocalizedDescriptionKey: "Cannot retrieve recent savedShippingAddress oid:\(shippingAddressOID)"])
                    return Promise(error: error)
                }
                return Promise(value: savedShippingAddress)
        }
    }

    func saveShippingAddress(fullName: String,
                             street: String,
                             city: String,
                             country: String,
                             zipCode: String,
                             state: String?,
                             phone: String) -> Promise<ShippingAddress> {
        let tuple = NetworkingPromise.sharedInstance.divideByLastSpace(fullName: fullName)
        return saveShippingAddress(firstName: tuple.0,
                                   lastName: tuple.1,
                                   street: street,
                                   city: city,
                                   country: country,
                                   zipCode: zipCode,
                                   state: state,
                                   phone: phone)
    }
    
    func deleteTemporaryCards(managedObjectContext: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Card> = Card.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isSaved == FALSE")
        fetchRequest.sortDescriptors = nil
        
        do {
            let results = try managedObjectContext.fetch(fetchRequest)
            for card in results {
                if card.objectID.uriRepresentation() == selectedCardURL {
                    selectedCardURL = nil
                }
                
                managedObjectContext.delete(card)
            }
            try managedObjectContext.save()
        } catch {
            self.receivedCoreDataError(error: error)
            print("deleteTemporaryCards results with error:\(error)")
        }
    }
    
    func deleteAllTemporaryCards() {
        performBackgroundTask { (managedObjectContext) in
            self.deleteTemporaryCards(managedObjectContext: managedObjectContext)
        }
    }
    
    // See: https://stackoverflow.com/questions/42733574/nspersistentcontainer-concurrency-for-saving-to-core-data
    // I thought dataModel.persistentContainer.performBackgroundTask ran against a single internal serial queue.
    // But it only runs against a private queue, and each call may have its own private queue running in parallel.
    // Thanks for still getting it wrong, Apple. So here is what I thought Apple would be doing.
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        self.dbQ.addOperation(AsyncOperation.init(timeout: nil, completion: { (completion) in
            let managedObjectContext = self.persistentContainer.newBackgroundContext()
            managedObjectContext.perform {
                block(managedObjectContext)
                completion()
            }
            
        }))
    }
    
    public func favorite(toFavorited: Bool, productOIDs: [NSManagedObjectID]) {
        performBackgroundTask { (managedObjectContext) in
            let fetchRequest: NSFetchRequest<Product> = Product.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "SELF IN %@", productOIDs)
            fetchRequest.sortDescriptors = nil
            
            do {
                let results = try managedObjectContext.fetch(fetchRequest)
                for product in results {
                    product.isFavorite = toFavorited
                    if toFavorited {
                        product.track()
                    }else{
                        product.untrack()
                    }
                    if toFavorited == false {
                        product.dateViewed  = nil
                    }
                    if toFavorited {
                        let now = Date()
                        product.dateFavorited = now
                        product.dateSortProductBar = product.getSortDateForProductBar()
                        product.hideFromProductBar = false
                        if let screenshot = product.shoppable?.screenshot {
                            screenshot.addToFavorites(product)
                            if let favoritesCount = screenshot.favorites?.count {
                                screenshot.favoritesCount = Int16(favoritesCount)
                            } else {
                                screenshot.favoritesCount += 1
                            }
                            screenshot.lastFavorited = now
                        }
                    } else {
                        product.dateFavorited = nil
                        if let screenshot = product.shoppable?.screenshot {
                            screenshot.removeFromFavorites(product)
                            if let favorites = screenshot.favorites {
                                screenshot.favoritesCount = Int16(favorites.count)
                            } else {
                                screenshot.favoritesCount = 0
                                screenshot.lastFavorited = nil
                            }
                        }
                    }
                }
                try managedObjectContext.save()
                
                if toFavorited {
                    AccumulatorModel.favorite.incrementUninformedCount()
                }else{
                    AccumulatorModel.favorite.decrementUninformedCount(by:1)
                }
            } catch {
                self.receivedCoreDataError(error: error)
                print("favorite toFavorited:\(toFavorited) results with error:\(error)")
            }
        }
    }
    
    public func unfavorite(favoriteArray: [Product]) {
        let moiArray = favoriteArray.map { $0.objectID }
        self.unfavorite(favoriteArray: moiArray)
    }
    
    public func unfavorite(favoriteArray: [NSManagedObjectID]) {
        let moiArray = favoriteArray
        
        
        self.performBackgroundTask { (managedObjectContext) in
            let fetchRequest: NSFetchRequest<Product> = Product.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "SELF IN %@", moiArray)
            fetchRequest.sortDescriptors = nil
            
            do {
                let results = try managedObjectContext.fetch(fetchRequest)
                for product in results {
                    if let screenshot = product.screenshot {
                        screenshot.removeFromFavorites(product)
                        screenshot.favoritesCount -= 1
                    }
                    product.isFavorite = false
                    product.dateFavorited = nil
                    AccumulatorModel.favorite.decrementUninformedCount(by:results.count)
                    product.untrack()
                }
                try managedObjectContext.save()
                
            } catch {
                self.receivedCoreDataError(error: error)
                print("unfavorite objectIDs:\(moiArray) results with error:\(error)")
            }
        }
    }
    
    public func setNoShoppables(assetId: String, uploadedURLString: String?) {
        DataModel.sharedInstance.performBackgroundTask { (managedObjectContext) in
            let fetchRequest: NSFetchRequest<Screenshot> = Screenshot.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "assetId == %@", assetId)
            fetchRequest.sortDescriptors = nil
            
            do {
                let results = try managedObjectContext.fetch(fetchRequest)
                for screenshot in results {
                    screenshot.shoppablesCount = -1
                    screenshot.uploadedImageURL = uploadedURLString
                }
                try managedObjectContext.save()
            } catch {
                self.receivedCoreDataError(error: error)
                print("setNoShoppables assetId:\(assetId) results with error:\(error)")
            }
        }
    }
    
    // Must be called on main.
    public func countTotalScreenshots() -> Int {
        let predicate = NSPredicate(format: "shoppablesCount > 0")
        return countScreenshotWorkhorse(predicate: predicate)
    }
    
    func countScreenshotWorkhorse(predicate: NSPredicate) -> Int {
        let managedObjectContext = mainMoc()
        let fetchRequest: NSFetchRequest<Screenshot> = Screenshot.fetchRequest()
        fetchRequest.predicate = predicate
        fetchRequest.resultType = .countResultType
        fetchRequest.includesSubentities = false
        
        var count: Int = 0
        do {
            count = try managedObjectContext.count(for: fetchRequest)
        } catch {
            self.receivedCoreDataError(error: error)
            print("countScreenshotWorkhorse results with error:\(error)")
        }
        return count
    }
    
    func countMatchsticks(managedObjectContext: NSManagedObjectContext) -> Int {
        let fetchRequest: NSFetchRequest<Matchstick> = Matchstick.fetchRequest()
        fetchRequest.predicate = nil
        fetchRequest.resultType = .countResultType
        fetchRequest.includesSubentities = false
        
        var count: Int = 0
        do {
            count = try managedObjectContext.count(for: fetchRequest)
        } catch {
            self.receivedCoreDataError(error: error)
            print("countMatchsticks results with error:\(error)")
        }
        return count
    }
    
    func isNextMatchsticksNeeded(matchstickCount: Int) -> Bool {
        let lowWatermark = 20
        return matchstickCount <= lowWatermark
    }
    
    // Returns a promise of the count of matchsticks in the DB,
    // and, crucially, errors if above the low water mark,
    // allowing chained promises to not execute.
    public func nextMatchsticksIfNeeded() -> Promise<Int> {
        return Promise { fulfill, reject in
            performBackgroundTask { (managedObjectContext) in
                let matchstickCount = self.countMatchsticks(managedObjectContext: managedObjectContext)
                if self.isNextMatchsticksNeeded(matchstickCount: matchstickCount) {
                    fulfill(matchstickCount)
                } else {
                    // Not really an error. Just an easy way to cancel further processing.
                    let error = NSError(domain: "Craze", code: 24, userInfo: [NSLocalizedDescriptionKey : "Good. We have enough, \(matchstickCount) matchsticks."])
                    reject(error)
                }
            }
        }
    }
    
    // MARK: DB Migration
    
    func postDbMigration(from: Int, to: Int, container: NSPersistentContainer) {
        let installDate = UserDefaults.standard.object(forKey: UserDefaultsKeys.dateInstalled) as? NSDate
        if (from < 9 && to >= 7 && installDate != nil) { // Originally was from < 7, but a bug fixed in 9 should re-run for 7 or 8.
            let op = BlockOperation{
                    let managedObjectContext = container.newBackgroundContext()
                    self.initializeFavoritesCounts(managedObjectContext: managedObjectContext)
            }
            op.queuePriority = .veryHigh   // Earlier actions may have already been queued - make sure migration is at the top of the list.
            self.dbQ.addOperation(op)
        }
        if from < 8 && to >= 8 && installDate != nil {
            let op = BlockOperation{
                let managedObjectContext = container.newBackgroundContext()
                self.initializeFavoritesSets(managedObjectContext: managedObjectContext)
                self.cleanDeletedScreenshots(managedObjectContext: managedObjectContext)
            }
            op.queuePriority = .veryHigh // Earlier actions may have already been queued - make sure migration is at the top of the list.
            self.dbQ.addOperation(op)
        }
        if from < 18 && to >= 18 && installDate != nil {
            let op = BlockOperation{
                let managedObjectContext = container.newBackgroundContext()
                self.moveCartItemsToFavorites(managedObjectContext: managedObjectContext)
            }
            op.queuePriority = .veryHigh   // Earlier actions may have already been queued - make sure migration is at the top of the list.
            self.dbQ.addOperation(op)
        }
    }
    
    func initializeFavoritesCounts(managedObjectContext: NSManagedObjectContext) {
        // Favorites count grouped by screenshot
        let countKeypathExp = NSExpression(forKeyPath: "isFavorite")
        let countExpression = NSExpression(forFunction: "count:", arguments: [countKeypathExp])
        let countDesc = NSExpressionDescription()
        countDesc.expression = countExpression
        countDesc.name = "count"
        countDesc.expressionResultType = .integer16AttributeType
        
        // lastDateFavorited grouped by screenshot
        let maxKeypathExp = NSExpression(forKeyPath: "dateFavorited")
        let maxExpression = NSExpression(forFunction: "max:", arguments: [maxKeypathExp])
        let maxDesc = NSExpressionDescription()
        maxDesc.expression = maxExpression
        maxDesc.name = "max"
        maxDesc.expressionResultType = .dateAttributeType
        
        let request: NSFetchRequest<NSDictionary> = NSFetchRequest(entityName: "Product")
        request.returnsObjectsAsFaults = false
        request.propertiesToGroupBy = ["shoppable.screenshot"]
        request.propertiesToFetch = ["shoppable.screenshot", countDesc, maxDesc]
        request.resultType = .dictionaryResultType
        request.predicate = NSPredicate(format: "isFavorite == TRUE")
        
        do {
            let results = try managedObjectContext.fetch(request)
            for dict in results {
                if let favoritesCount = dict["count"] as? Int16,
                    let lastFavorited = dict["max"] as? Date,
                    let screenshotId = dict["shoppable.screenshot"] as? NSManagedObjectID,
                    let screenshot = managedObjectContext.object(with: screenshotId) as? Screenshot {
                    screenshot.favoritesCount = favoritesCount
                    screenshot.lastFavorited = lastFavorited
                } else {
                    print("Migration screenshot.favoritesCount screenshot.lastFavorited failed")
                }
            }
            try managedObjectContext.save()
        } catch {
            self.receivedCoreDataError(error: error)
            print("initializeFavoritesCounts results with error:\(error)")
        }
    }
    
    func initializeFavoritesSets(managedObjectContext: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Product> = Product.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isFavorite == TRUE")
        fetchRequest.sortDescriptors = nil
        
        do {
            let results = try managedObjectContext.fetch(fetchRequest)
            for product in results {
                product.shoppable?.screenshot?.addToFavorites(product)
            }
            try managedObjectContext.save()
        } catch {
            self.receivedCoreDataError(error: error)
            print("initializeFavoritesSets results with error:\(error)")
        }
    }
    
    func cleanDeletedScreenshots(managedObjectContext: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Screenshot> = Screenshot.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isHidden == TRUE")
        fetchRequest.sortDescriptors = nil
        
        do {
            let results = try managedObjectContext.fetch(fetchRequest)
            for screenshot in results {
                screenshot.hideWorkhorse()
            }
            try managedObjectContext.save()
        } catch {
            self.receivedCoreDataError(error: error)
            print("cleanDeletedScreenshots results with error:\(error)")
        }
    }
    
    func moveCartItemsToFavorites(managedObjectContext: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<CartItem> = CartItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "cart.isPastOrder == FALSE")
        fetchRequest.sortDescriptors = nil
        
        do {
            let results = try managedObjectContext.fetch(fetchRequest)
            let unfavoritedProducts = Set<Product>(results.compactMap { $0.product != nil && !$0.product!.isFavorite ? $0.product : nil })
            self.favorite(toFavorited: true, productOIDs: unfavoritedProducts.map { $0.objectID })
            results.forEach { managedObjectContext.delete($0) }
            try managedObjectContext.save()
        } catch {
            self.receivedCoreDataError(error: error)
            print("moveCartItemsToFavorites results with error:\(error)")
        }
    }
    
}

extension NSFetchedResultsController {
    @objc var fetchedObjectsCount:Int {
        get {
            return sections?.reduce(0, {$0 + $1.numberOfObjects}) ?? 0
        }
    }
}

extension String {
    func productTitle() -> String? {
        let components = split(separator: ",")
        
        if components.count > 1 {
            return components.dropLast().joined(separator: ",")
        }
        else {
            return self
        }
    }
}

extension NSManagedObjectContext {
    @discardableResult func saveIfNeeded() -> Bool{
        if self.hasChanges {
            do {
                try self.save()
                return true
            } catch {
                DataModel.sharedInstance.receivedCoreDataError(error: error)
                return false
            }
        }else{
            return true
        }
    }
    
    func objectId(for objectIdUrl:URL) -> NSManagedObjectID? {
        return self.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: objectIdUrl)
    }
    
    func productWith(objectId:NSManagedObjectID) -> Product? {
        if let card = self.object(with: objectId) as? Product {
            do{
                try card.validateForUpdate()
                return card
            }catch{
                DataModel.sharedInstance.receivedCoreDataError(error: error)
                
            }
        }
        return nil
    }
    
    func screenshotWith(objectId:NSManagedObjectID) -> Screenshot? {
        if let screenshot = self.object(with: objectId) as? Screenshot {
            do{
                try screenshot.validateForUpdate()
                return screenshot
            }catch{
                DataModel.sharedInstance.receivedCoreDataError(error: error)
                
            }
        }
        return nil
    }
    
    func shoppableWith(objectId:NSManagedObjectID) -> Shoppable? {
        if let screenshot = self.object(with: objectId) as? Shoppable {
            do{
                try screenshot.validateForUpdate()
                return screenshot
            }catch{
                DataModel.sharedInstance.receivedCoreDataError(error: error)
            }
        }
        return nil
    }
    
    func cartItemWith(objectId: NSManagedObjectID) -> CartItem? {
        if let cartItem = object(with: objectId) as? CartItem {
            do {
                try cartItem.validateForUpdate()
                return cartItem
            }
            catch {
                DataModel.sharedInstance.receivedCoreDataError(error: error)
            }
        }
        return nil
    }
    
    func cardWith(objectId:NSManagedObjectID) -> Card? {
        if let card = self.object(with: objectId) as? Card {
            do{
                try card.validateForUpdate()
                return card
            }catch{
                DataModel.sharedInstance.receivedCoreDataError(error: error)
                
            }
        }
        return nil
    }
    
    func shippingAddressWith(objectId:NSManagedObjectID) -> ShippingAddress? {
        if let shippingAddress = self.object(with: objectId) as? ShippingAddress {
            do{
                try shippingAddress.validateForUpdate()
                return shippingAddress
            }catch{
                DataModel.sharedInstance.receivedCoreDataError(error: error)
                
            }
        }
        return nil
    }
    
    func findOrCreateScreenshotWith(assetId:String) -> Screenshot {
        if let screenshot = self.screenshotWith(assetId: assetId) {
            return screenshot
        }
        
        let screenshot = Screenshot(context: self)
        screenshot.assetId = assetId
        let now = Date()
        screenshot.createdAt = now
        
        screenshot.isHidden = true
        screenshot.isNew = true
        screenshot.lastModified = Date()
        return screenshot
        
    }
    
    func screenshotWith(screenshotId:String) -> Screenshot? {
        let fetchRequest: NSFetchRequest<Screenshot> = Screenshot.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "screenshotId == %@", screenshotId)
        fetchRequest.sortDescriptors = nil
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try self.fetch(fetchRequest)
            return results.first
        } catch {
            DataModel.sharedInstance.receivedCoreDataError(error: error)
            print("retrieveScreenshot screenshotId:\(screenshotId) results with error:\(error)")
        }
        return nil
    }
    func screenshotWith(assetId:String) -> Screenshot? {
        let fetchRequest: NSFetchRequest<Screenshot> = Screenshot.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "assetId == %@", assetId)
        fetchRequest.sortDescriptors = nil
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try self.fetch(fetchRequest)
            return results.first
        } catch {
            DataModel.sharedInstance.receivedCoreDataError(error: error)
            print("retrieveScreenshot assetId:\(assetId) results with error:\(error)")
        }
        return nil
    }
    
}
