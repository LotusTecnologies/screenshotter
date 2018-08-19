//&& //
//  DataModel.swift
//  screenshot
//
//  Created by Gershon Kagan on 8/9/17.
//  Copyright (c) 2017 crazeapp. All rights reserved.
//

import UIKit
import CoreData
import PromiseKit

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
                    DiscoverManager.shared.discoverViewDidAppear() //make sure some stuff is there when the user arrives
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
    func saveScreenshot(upsert:Bool,
                        managedObjectContext: NSManagedObjectContext,
                        assetId: String,
                        createdAt: Date?,
                        isRecognized: Bool,
                        source: ScreenshotSource,
                        isHidden: Bool,
                        imageData: Data?,
                        uploadedImageURL: String?,
                        syteJsonString: String?) -> Screenshot {
        
        var current:Screenshot? = nil;
        var wasHidden:Bool? = nil
        if upsert {
            current = managedObjectContext.screenshotWith(assetId: assetId)
            wasHidden = current?.isHidden
            
            if  current == nil {
                if let uploadedImageURL = uploadedImageURL {
                    current = managedObjectContext.screenshotWith(imageUrl: uploadedImageURL)
                    wasHidden = current?.isHidden
                }
            }
        }
       
        
        let screenshotToSave = current ?? Screenshot(context: managedObjectContext)
        
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
        
        if current == nil || (wasHidden == true && isHidden == false) {
            Analytics.trackScreenshotCreated(screenshot: screenshotToSave)
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
    
    public func hide(screenshotOIDArray: [NSManagedObjectID], kind:Analytics.AnalyticsScreenshotDeletedKind) {
        performBackgroundTask { (managedObjectContext) in
            do {
                screenshotOIDArray.forEach { screenshotOID in
                    if let screenshot = managedObjectContext.object(with: screenshotOID) as? Screenshot {
                        Analytics.trackScreenshotDeleted(screenshot: screenshot, kind: kind)
                        do{
                            try screenshot.validateForUpdate()
                            screenshot.isHidden = true
                            screenshot.isNew = false
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
        
        if let current =  (screenshot.shoppables as? Set<Shoppable>)?.first(where: { $0.offersURL == offersURL } ){
            return current
        }
        
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
                     id: String?,
                     color: String?,
                     sku: String?,
                     fallbackPrice: Float,
                     optionsMask: Int32) -> Product {
        if let current =  (shoppable?.products as? Set<Product>)?.first(where: { $0.offer == offer } ){
            return current
        }
        
        let productToSave = Product(context: managedObjectContext)
        productToSave.shoppable = shoppable
        productToSave.order = order
        productToSave.productDescription = productDescription
        productToSave.price = price
        productToSave.originalPrice = originalPrice
        productToSave.floatPrice = floatPrice
        productToSave.floatOriginalPrice = floatOriginalPrice
        productToSave.categories = categories
        productToSave.label = shoppable?.label
        productToSave.brand = brand
        productToSave.offer = offer
        productToSave.imageURL = imageURL
        productToSave.merchant = merchant
        productToSave.partNumber = partNumber
        productToSave.id = id
        productToSave.color = color
        productToSave.sku = sku
        productToSave.fallbackPrice = fallbackPrice
        productToSave.optionsMask = optionsMask
        productToSave.dateRetrieved = Date()
        return productToSave
    }
    
    func saveOrphanedProduct(managedObjectContext: NSManagedObjectContext, serverDict dict: NSDictionary) -> Product? {
        if let price = dict["price"] as? String,
          let imageURL = dict["imageUrl"] as? String,
          let productDescription = dict["productDescription"] as? String,
          let offer = dict["offer"] as? String,
          let floatPriceNumber = dict["floatPrice"] as? NSNumber {
            let floatPrice = floatPriceNumber.floatValue
            let originalPrice = dict["originalPrice"] as? String
            var floatOriginalPrice: Float =  0
            if let p = dict["floatOriginalPrice"] as? NSNumber {
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
            let orphanedProduct = saveProduct(managedObjectContext: managedObjectContext,
                                              shoppable: nil,
                                              order: 0,
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
                                              partNumber: partNumber,
                                              id: id,
                                              color: color,
                                              sku: sku,
                                              fallbackPrice: fallbackPrice,
                                              optionsMask: Int32(optionsMask))
            managedObjectContext.saveIfNeeded()
            return orphanedProduct
        }
        return nil
    }
    
    func saveOrphanedProduct(serverDict: NSDictionary) -> Promise<NSManagedObjectID> {
        return Promise { fulfill, reject in
            self.performBackgroundTask { managedObjectContext in
                if let orphanedProduct = self.saveOrphanedProduct(managedObjectContext: managedObjectContext, serverDict: serverDict) {
                    fulfill(orphanedProduct.objectID)
                } else {
                    reject(NSError(domain: "Craze", code: 120, userInfo: [NSLocalizedDescriptionKey : "save orphaned product fail"]))
                }
            }
        }
    }
    
    // Returns a Product that is from the mainMoc for the main thread.
    func mainSafeOrphanedProduct(serverDict: NSDictionary) -> Promise<Product> {
        return saveOrphanedProduct(serverDict: serverDict).then(on: .main) { orphanedProductOID -> Promise<Product> in
            if let orphanedProduct = self.mainMoc().object(with: orphanedProductOID) as? Product {
                return Promise(value: orphanedProduct)
            } else {
                return Promise(error: NSError(domain: "Craze", code: 121, userInfo: [NSLocalizedDescriptionKey : "retrieve orphaned product fail"]))
            }
        }
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
    
    func retrieveProduct(managedObjectContext: NSManagedObjectContext, id: String) -> Product? {
        let fetchRequest: NSFetchRequest<Product> = Product.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        fetchRequest.sortDescriptors = nil //[NSSortDescriptor(key: "createdAt", ascending: false)]
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try managedObjectContext.fetch(fetchRequest)
            return results.first
        } catch {
            self.receivedCoreDataError(error: error)
            print("retrieveProduct id:\(id) results with error:\(error)")
        }
        return nil
    }
    
    func retrieveProduct(managedObjectContext: NSManagedObjectContext, imageURL: String) -> Product? {
        let fetchRequest: NSFetchRequest<Product> = Product.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "imageURL == %@", imageURL)
        fetchRequest.sortDescriptors = nil //[NSSortDescriptor(key: "createdAt", ascending: false)]
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try managedObjectContext.fetch(fetchRequest)
            return results.first
        } catch {
            self.receivedCoreDataError(error: error)
            print("retrieveProduct imageURL:\(imageURL) results with error:\(error)")
        }
        return nil
    }
    
    func markProductNotInNotif(imageURL: String) {
        self.performBackgroundTask { managedObjectContext in
            let fetchRequest: NSFetchRequest<Product> = Product.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "imageURL == %@", imageURL)
            fetchRequest.sortDescriptors = nil //[NSSortDescriptor(key: "createdAt", ascending: false)]
            
            do {
                let results = try managedObjectContext.fetch(fetchRequest)
                results.forEach { $0.inNotif = false }
                managedObjectContext.saveIfNeeded()
            } catch {
                self.receivedCoreDataError(error: error)
                print("markProductNotInNotif imageURL:\(imageURL) results with error:\(error)")
            }
        }
    }
    
    func markScreenshotNotInNotif(assetId: String) {
        self.performBackgroundTask { managedObjectContext in
            let fetchRequest: NSFetchRequest<Screenshot> = Screenshot.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "assetId == %@", assetId)
            fetchRequest.sortDescriptors = nil //[NSSortDescriptor(key: "createdAt", ascending: false)]
            
            do {
                let results = try managedObjectContext.fetch(fetchRequest)
                results.forEach { $0.inNotif = false }
                managedObjectContext.saveIfNeeded()
            } catch {
                self.receivedCoreDataError(error: error)
                print("markScreenshotNotInNotif assetId:\(assetId) results with error:\(error)")
            }
        }
    }
    
    func markProductHasPriceAlerts(id: String) {
        self.performBackgroundTask { managedObjectContext in
            let fetchRequest: NSFetchRequest<Product> = Product.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@ AND hasPriceAlerts == FALSE", id)
            fetchRequest.sortDescriptors = nil //[NSSortDescriptor(key: "createdAt", ascending: false)]
            
            do {
                let results = try managedObjectContext.fetch(fetchRequest)
                results.forEach { $0.hasPriceAlerts = true }
                managedObjectContext.saveIfNeeded()
            } catch {
                self.receivedCoreDataError(error: error)
                print("markProductHasPriceAlerts id:\(id) results with error:\(error)")
            }
        }
    }
    
    func updateProductPrice(id: String, updatedPrice: Float?, updatedCurrency: String) -> Promise<String> {
        return Promise { fulfill, reject in
            self.performBackgroundTask { managedObjectContext in
                if let updatedPrice = updatedPrice,
                  let formattedUpdatePrice = self.formattedPrice(price: updatedPrice, currency: updatedCurrency),
                  let product = self.retrieveProduct(managedObjectContext: managedObjectContext, id: id) {
                    product.floatPrice = updatedPrice
                    product.price = formattedUpdatePrice
                    managedObjectContext.saveIfNeeded()
                }
                fulfill(id)
            }
        }
    }
    
    func retrieveLatestFavorite(in context:NSManagedObjectContext) -> Product? {
        let fetchRequest: NSFetchRequest<Product> = Product.fetchRequest()
        let twoMonthsAgo = NSDate(timeIntervalSinceNow: -60 * TimeInterval.oneDay)
        fetchRequest.predicate = NSPredicate(format: "isFavorite == TRUE AND inNotif == FALSE AND imageURL != nil AND dateFavorited > %@", twoMonthsAgo)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateFavorited", ascending: false)]
        fetchRequest.fetchLimit = 1
        do {
            let results = try context.fetch(fetchRequest)
            if let latest = results.first {
                return latest
            }
        } catch {
            self.receivedCoreDataError(error: error)
            
        }
        return nil
    }
    
    func retrieveLatestTapped(in context:NSManagedObjectContext) -> Product? {
        let fetchRequest: NSFetchRequest<Product> = Product.fetchRequest()
        let aMonthAgo = NSDate(timeIntervalSinceNow: -30 * TimeInterval.oneDay)
        fetchRequest.predicate = NSPredicate(format: "isFavorite == FALSE AND inNotif == FALSE AND imageURL != nil AND dateViewed > %@", aMonthAgo)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateViewed", ascending: false)]
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.first
        } catch {
            self.receivedCoreDataError(error: error)
            print("retrieveLatestTapped results with error:\(error)")
            
        }
        return nil
    }
    
    func retrieveSaleScreenshot(in context:NSManagedObjectContext) -> Screenshot? {
        let fetchRequest: NSFetchRequest<Shoppable> = Shoppable.fetchRequest()
        let twoMonthsAgo = NSDate(timeIntervalSinceNow: -60 * TimeInterval.oneDay)
        fetchRequest.predicate = NSPredicate(format: "screenshot.lastModified > %@ AND screenshot.inNotif == FALSE AND screenshot.isHidden == FALSE AND screenshot.imageData != nil AND (SUBQUERY(products, $x, ($x.order == 0 OR $x.order == 1) AND $x.floatPrice < $x.floatOriginalPrice).@count == 2)", twoMonthsAgo)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "screenshot.lastModified", ascending: false)]
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try context.fetch(fetchRequest)
            if let latestShoppable = results.first,
                let latestScreenshot = latestShoppable.screenshot {
                return latestScreenshot
            }
        } catch {
            self.receivedCoreDataError(error: error)
            print("retrieveSaleScreenshot results with error:\(error)")
        }
        return nil
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
   
   
    func saveMatchstick(managedObjectContext: NSManagedObjectContext,
                        remoteId: String,
                        imageUrl: String,
                        properties:[String:[String]]?
                        ) -> Matchstick? {
        let fetchRequest: NSFetchRequest<Matchstick> = Matchstick.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "imageUrl == %@", imageUrl)
        fetchRequest.sortDescriptors = nil
        
        let results = try? managedObjectContext.fetch(fetchRequest)
        if let first = results?.first {
            return first
        }
        let matchstickToSave = Matchstick(context: managedObjectContext)
        matchstickToSave.remoteId = remoteId
        matchstickToSave.imageUrl = imageUrl
        if let properties = properties {
            if JSONSerialization.isValidJSONObject(properties), let data = try? JSONSerialization.data(withJSONObject: properties, options: []), let string = String.init(data: data, encoding: .utf8) {
                matchstickToSave.propertiesJson = string
            }
            
            matchstickToSave.isMale = properties["genders"]?.contains("male")  ?? false
            matchstickToSave.isFemale = properties["genders"]?.contains("female") ?? false
        }
        matchstickToSave.receivedAt = Date()
        

        return matchstickToSave
    }
    
    func addImageDataToMatchstick(managedObjectContext: NSManagedObjectContext, imageUrl: String, imageData: Data) {
        let fetchRequest: NSFetchRequest<Matchstick> = Matchstick.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "imageUrl == %@", imageUrl)
        fetchRequest.sortDescriptors = nil
        
        if let results = try? managedObjectContext.fetch(fetchRequest), let matchstick = results.first {
            matchstick.imageData = imageData
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
                    if toFavorited == false {
                        product.dateViewed  = nil
                    }
                    if toFavorited {
                        let now = Date()
                        product.dateFavorited = now
                        product.dateSortProductBar = product.getSortDateForProductBar()
                        if let screenshot = product.shoppable?.screenshot {
                            screenshot.addToFavorites(product)
                            if let favoritesCount = screenshot.favorites?.count {
                                screenshot.favoritesCount = Int16(favoritesCount)
                            } else {
                                screenshot.favoritesCount += 1
                            }
                            screenshot.lastFavorited = now
                        }
                        UserAccountManager.shared.uploadFavorites(product: product)

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
                        UserAccountManager.shared.deleteFavorite(product: product)
                    }
                }
                try managedObjectContext.save()
                
                if toFavorited {
                    AccumulatorModel.favoriteUninformed.incrementUninformedCount()
                }else{
                    AccumulatorModel.favoriteUninformed.decrementUninformedCount(by:1)
                }
            } catch {
                self.receivedCoreDataError(error: error)
                print("favorite toFavorited:\(toFavorited) results with error:\(error)")
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
    
    func formattedPrice(price: Float, currency: String) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        let localeIdentifier = Locale.identifier(fromComponents: [NSLocale.Key.currencyCode.rawValue: currency])
        formatter.locale = Locale(identifier: localeIdentifier)
        return formatter.string(from: NSNumber(value: price))
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
    
    func cleanDB() {
        performBackgroundTask { (managedObjectContext) in
            let screenshotRequest: NSFetchRequest<Screenshot> = Screenshot.fetchRequest()
            screenshotRequest.predicate = NSPredicate(format: "isHidden == TRUE")
            
            do {
                let screenshots = try managedObjectContext.fetch(screenshotRequest)
                let favoriteRequest: NSFetchRequest<Product> = Product.fetchRequest()
                favoriteRequest.predicate = NSPredicate(format: "isFavorite == TRUE AND screenshot IN %@", screenshots)
                let favorites = try managedObjectContext.fetch(favoriteRequest)
                for favorite in favorites {
                    favorite.screenshot = nil
                    favorite.shoppable = nil
                }
                for screenshot in screenshots {
                    managedObjectContext.delete(screenshot)
                }
                let shoppableRequest: NSFetchRequest<Shoppable> = Shoppable.fetchRequest()
                shoppableRequest.predicate = NSPredicate(format: "isFavorite == TRUE AND screenshot IN %@", screenshots)
                let shoppables = try managedObjectContext.fetch(shoppableRequest)
                try managedObjectContext.save()
            } catch {
                self.receivedCoreDataError(error: error)
                print("cleanDB results with error:\(error)")
            }
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
        if let product = self.object(with: objectId) as? Product {
            do{
                try product.validateForUpdate()
                return product
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
        if let shoppable = self.object(with: objectId) as? Shoppable {
            do{
                try shoppable.validateForUpdate()
                return shoppable
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
    
    func screenshotWith(imageUrl:String) -> Screenshot? {
        let fetchRequest: NSFetchRequest<Screenshot> = Screenshot.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "uploadedImageURL == %@", imageUrl)
        fetchRequest.sortDescriptors = nil
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try self.fetch(fetchRequest)
            return results.first
        } catch {
            DataModel.sharedInstance.receivedCoreDataError(error: error)
            print("retrieveScreenshot imageUrl:\(imageUrl) results with error:\(error)")
        }
        return nil
    }
    
    func inboxMessageWith(objectId:NSManagedObjectID) ->InboxMessage? {
        if let m = self.object(with: objectId) as? InboxMessage {
            do{
                try m.validateForUpdate()
                return m
            }catch{
                DataModel.sharedInstance.receivedCoreDataError(error: error)
            }
        }
        return nil
    }
}
