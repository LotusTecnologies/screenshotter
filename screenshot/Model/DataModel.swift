//
//  DataModel.swift
//  screenshot
//
//  Created by Gershon Kagan on 8/9/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit
import CoreData
import PromiseKit
import SwiftKeychainWrapper

enum ScreenshotSource : String {
    case unknown
    case discover
    case gallery
    case shuffle
    case share
    case tutorial
}

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
            AnalyticsTrackers.standard.track(.error, properties: ["type":"noHardDriveSpace"])
            DispatchQueue.main.async {
                AppDelegate.shared.presentLowDiskSpaceWarning()
            }
        }else{
            AnalyticsTrackers.standard.track(.error, properties: ["domain":error.domain, "code":error.code, "localizedDescription":error.localizedDescription])
        }
    }
}
extension DataModel {
    func screenshotFrc(delegate:FetchedResultsControllerManagerDelegate?) -> FetchedResultsControllerManager<Screenshot>  {
        let request: NSFetchRequest<Screenshot> = Screenshot.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "lastModified", ascending: false), NSSortDescriptor(key: "createdAt", ascending: false)]
        request.predicate = NSPredicate(format: "isHidden == FALSE AND isRecognized == TRUE")
        let context = self.mainMoc()
        let fetchedResultsController = FetchedResultsControllerManager<Screenshot>.init(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, delegate: delegate)
        return fetchedResultsController
    }
    
    func screenshotBySourceFrc(sourse:ScreenshotSource, delegate:FetchedResultsControllerManagerDelegate?) -> FetchedResultsControllerManager<Screenshot>  {
        let request: NSFetchRequest<Screenshot> = Screenshot.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "lastModified", ascending: false), NSSortDescriptor(key: "createdAt", ascending: false)]
        let notHidden = NSPredicate(format: "isHidden == FALSE AND isRecognized == TRUE")
        let fromSource:NSPredicate = {
            if sourse == .unknown {
                return NSPredicate.init(format: "sourseString == nil || sourceString == %@", sourse.rawValue)
            }else {
                return NSPredicate.init(format: "sourceString == %@", sourse.rawValue)
            }
        }()
        request.predicate = NSCompoundPredicate.init(andPredicateWithSubpredicates: [notHidden, fromSource])
        let context = self.mainMoc()
        let fetchedResultsController = FetchedResultsControllerManager<Screenshot>.init(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, delegate: delegate)
        return fetchedResultsController
    }
    
    func singleScreenshotFrc(delegate:FetchedResultsControllerManagerDelegate?, screenshot:Screenshot) -> FetchedResultsControllerManager<Screenshot>  {
        let request: NSFetchRequest<Screenshot> = Screenshot.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "lastModified", ascending: false)]
        request.predicate = NSPredicate(format: "SELF == %@", screenshot.objectID)
        let context = self.mainMoc()
        let fetchedResultsController = FetchedResultsControllerManager<Screenshot>.init(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, delegate: delegate)
        return fetchedResultsController
    }
    
    func shoppableFrc(delegate:FetchedResultsControllerManagerDelegate?, screenshot:Screenshot) -> FetchedResultsControllerManager<Shoppable> {
        let request: NSFetchRequest<Shoppable> = Shoppable.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true), NSSortDescriptor(key: "b0x", ascending: true), NSSortDescriptor(key: "b0y", ascending: true), NSSortDescriptor(key: "b1x", ascending: true), NSSortDescriptor(key: "b1y", ascending: true), NSSortDescriptor(key: "offersURL", ascending: true)]
        request.predicate = NSPredicate(format: "screenshot == %@", screenshot)
        let context = self.mainMoc()
        let fetchedResultsController = FetchedResultsControllerManager<Shoppable>.init(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, delegate: delegate)
        return fetchedResultsController
    }
    
    func favoriteFrc(delegate:FetchedResultsControllerManagerDelegate?) -> FetchedResultsControllerManager<Screenshot> {
        let request: NSFetchRequest = Screenshot.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "lastFavorited", ascending: false)]
        request.predicate = NSPredicate(format: "favoritesCount != 0")
        let context = self.mainMoc()
        let fetchedResultsController:FetchedResultsControllerManager<Screenshot> = FetchedResultsControllerManager<Screenshot>.init(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, delegate: delegate)
        return fetchedResultsController
    }
    
    func productFrc(delegate:FetchedResultsControllerManagerDelegate?, shoppableOID: NSManagedObjectID) -> FetchedResultsControllerManager<Product> {
        let request: NSFetchRequest = Product.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "dateFavorited", ascending: false)]
        request.predicate = NSPredicate(format: "shoppable == %@", shoppableOID)
        
        let context = self.mainMoc()
        let fetchedResultsController:FetchedResultsControllerManager<Product> = FetchedResultsControllerManager<Product>.init(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, delegate: delegate)
        return fetchedResultsController
    }
    
    func productBarFrc(delegate:FetchedResultsControllerManagerDelegate?) -> FetchedResultsControllerManager<Product> {
        let request: NSFetchRequest = Product.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "dateSortProductBar", ascending: false)]
        let date = NSDate.init(timeIntervalSinceNow:  -60*60*24*7)
        request.predicate = NSCompoundPredicate.init(andPredicateWithSubpredicates: [NSPredicate(format: "hideFromProductBar != true"), NSCompoundPredicate.init(orPredicateWithSubpredicates: [ NSPredicate(format: "isFavorite == true"), NSPredicate(format: "dateViewed != nil")]), NSPredicate(format:"dateSortProductBar > %@", date)])
        
        let context = self.mainMoc()
        let fetchedResultsController:FetchedResultsControllerManager<Product> = FetchedResultsControllerManager<Product>.init(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, delegate: delegate)
        return fetchedResultsController
    }
    
    func matchstickFrc(delegate:FetchedResultsControllerManagerDelegate?) -> FetchedResultsControllerManager<Matchstick> {
        let request: NSFetchRequest = Matchstick.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "receivedAt", ascending: true)]
        request.predicate = NSPredicate(format: "imageData != nil")
        let context = self.mainMoc()
        let fetchedResultsController:FetchedResultsControllerManager<Matchstick> = FetchedResultsControllerManager<Matchstick>.init(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, delegate:delegate)
        
        return fetchedResultsController
    }
    
    func cartItemFrc(delegate:FetchedResultsControllerManagerDelegate?) -> FetchedResultsControllerManager<CartItem>  {
        let request: NSFetchRequest<CartItem> = CartItem.fetchRequest()
        request.predicate = NSPredicate(format: "cart.isPastOrder == FALSE")
        request.sortDescriptors = [NSSortDescriptor(key: "errorMask", ascending: false), NSSortDescriptor(key: "dateModified", ascending: false)]
        let context = self.mainMoc()
        let fetchedResultsController = FetchedResultsControllerManager<CartItem>(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, delegate: delegate)
        return fetchedResultsController
    }
    
    func cardFrc(delegate:FetchedResultsControllerManagerDelegate?) -> FetchedResultsControllerManager<Card>  {
        let request: NSFetchRequest<Card> = Card.fetchRequest()
        request.predicate = NSPredicate(format: "isSaved == TRUE")
        request.sortDescriptors = [NSSortDescriptor(key: "dateAdded", ascending: false)]
        let context = self.mainMoc()
        let fetchedResultsController = FetchedResultsControllerManager<Card>(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, delegate: delegate)
        return fetchedResultsController
    }
    
    func shippingAddressFrc(delegate:FetchedResultsControllerManagerDelegate?) -> FetchedResultsControllerManager<ShippingAddress>  {
        let request: NSFetchRequest<ShippingAddress> = ShippingAddress.fetchRequest()
        request.predicate = nil
        request.sortDescriptors = [NSSortDescriptor(key: "dateAdded", ascending: false)]
        let context = self.mainMoc()
        let fetchedResultsController = FetchedResultsControllerManager<ShippingAddress>(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, delegate: delegate)
        return fetchedResultsController
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
                        classification: String?) -> Screenshot {
        let screenshotToSave = Screenshot(context: managedObjectContext)
        screenshotToSave.assetId = assetId
        screenshotToSave.createdAt = createdAt
        screenshotToSave.isRecognized = isRecognized
        screenshotToSave.source = source
        screenshotToSave.isHidden = isHidden
        screenshotToSave.isNew = true
        screenshotToSave.imageData = imageData
        
        screenshotToSave.lastModified = Date()
        if let classification = classification {
            screenshotToSave.syteJson = classification // Dual-purposing syteJson field
        }
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
    
    public func hide(screenshotOIDArray: [NSManagedObjectID]) {
        performBackgroundTask { (managedObjectContext) in
            do {
                screenshotOIDArray.forEach { screenshotOID in
                    if let screenshot = managedObjectContext.object(with: screenshotOID) as? Screenshot {
                        do{
                            try screenshot.validateForUpdate()
                            screenshot.isHidden = true
                            screenshot.hideWorkhorse(managedObjectContext: managedObjectContext)
                        } catch{
                            
                        }
                        
                        
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
                     shoppable: Shoppable,
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
        variantToSave.dateModified = Date()
        return variantToSave
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
                        syteJson: String) -> Matchstick {
        let matchstickToSave = Matchstick(context: managedObjectContext)
        matchstickToSave.remoteId = remoteId
        matchstickToSave.imageUrl = imageUrl
        matchstickToSave.syteJson = syteJson
        matchstickToSave.receivedAt = Date()
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
                        let startKeychain = Date()
                        let didSetCardNumber: Bool = KeychainWrapper.standard.set(number, forKey: key)
                        print("GMK didSetCardNumber:\(didSetCardNumber) took \(-startKeychain.timeIntervalSinceNow) seconds")
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
    
    // See: https://stackoverflow.com/questions/42733574/nspersistentcontainer-concurrency-for-saving-to-core-data
    // I thought dataModel.persistentContainer.performBackgroundTask ran against a single internal serial queue.
    // But it only runs against a private queue, and each call may have its own private queue running in parallel.
    // Thanks for still getting it wrong, Apple. So here is what I thought Apple would be doing.
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        self.dbQ.addOperation {
            let managedObjectContext = self.persistentContainer.newBackgroundContext()
            managedObjectContext.performAndWait {
                block(managedObjectContext)
            }
        }
    }
    
    func backgroundPromise(dict: [String : Any], block: @escaping (NSManagedObjectContext) -> NSManagedObject) -> Promise<(NSManagedObject, [String : Any])> {
        return Promise { fulfill, reject in
            self.dbQ.addOperation {
                let managedObjectContext = self.persistentContainer.newBackgroundContext()
                managedObjectContext.perform {
                    fulfill((block(managedObjectContext), dict))
                }
            }
        }
    }
    
    public func unfavorite(favoriteArray: [Product]) {
        let moiArray = favoriteArray.map { $0.objectID }
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
            op.queuePriority = .veryHigh   //earilier actions may have already been queue - make sure migration is at the top of the list
            self.dbQ.addOperation(op)
        }
        if from < 8 && to >= 8 && installDate != nil {
            let op = BlockOperation{
                let managedObjectContext = container.newBackgroundContext()
                self.initializeFavoritesSets(managedObjectContext: managedObjectContext)
                self.cleanDeletedScreenshots(managedObjectContext: managedObjectContext)
                self.fixProductFiltersNoClassification(managedObjectContext: managedObjectContext)
                self.fixProductsNoClassification(managedObjectContext: managedObjectContext)
            }
            op.queuePriority = .veryHigh //earilier actions may have already been queue - make sure migration is at the top of the list
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
                screenshot.hideWorkhorse(managedObjectContext: managedObjectContext)
            }
            try managedObjectContext.save()
        } catch {
            self.receivedCoreDataError(error: error)
            print("cleanDeletedScreenshots results with error:\(error)")
        }
    }
    
    func fixProductFiltersNoClassification(managedObjectContext: NSManagedObjectContext) {
        let noClassificationPredicate = NSPredicate(format: "(optionsMask & 192) == 0")
        let fetchRequest: NSFetchRequest<ProductFilter> = ProductFilter.fetchRequest()
        fetchRequest.predicate = noClassificationPredicate
        fetchRequest.sortDescriptors = nil
        
        do {
            let results = try managedObjectContext.fetch(fetchRequest)
            for productFilter in results {
                productFilter.optionsMask |= Int32(ProductsOptionsMask.categoryFashion.rawValue)
            }
            try managedObjectContext.save()
        } catch {
            self.receivedCoreDataError(error: error)
            print("fixProductFiltersNoClassification results with error:\(error)")
        }
    }
    
    func fixProductsNoClassification(managedObjectContext: NSManagedObjectContext) {
        let noClassificationPredicate = NSPredicate(format: "(optionsMask & 192) == 0")
        let fetchRequest: NSFetchRequest<Product> = Product.fetchRequest()
        fetchRequest.predicate = noClassificationPredicate
        fetchRequest.sortDescriptors = nil
        
        do {
            let results = try managedObjectContext.fetch(fetchRequest)
            for product in results {
                product.optionsMask |= Int32(ProductsOptionsMask.categoryFashion.rawValue)
            }
            try managedObjectContext.save()
        } catch {
            self.receivedCoreDataError(error: error)
            print("fixProductsNoClassification results with error:\(error)")
        }
    }
    
}

extension Screenshot {

    var source:ScreenshotSource {
        get {
            if let sourceString = self.sourceString,  let source = ScreenshotSource.init(rawValue: sourceString) {
                return source
            }else{
                return .unknown
            }
        }
        set (newValue){
            self.sourceString = newValue.rawValue
        }
    }
    var isShamrockVersion:Bool {
        return self.assetId?.hasPrefix("shamrock") ?? false
    }
    
    // hideWorkhorse is not meant to be called from UI code,
    // but may be called on the main queue, even if generally called on a background queue.
    // It does not actually hide the screenshot.
    func hideWorkhorse(managedObjectContext: NSManagedObjectContext, deleteImage: Bool = true) {
        if let favoriteSet = favorites as? Set<Product>,
            favoriteSet.count > 0 {
            favoriteSet.forEach { $0.shoppable = nil }
        } else if deleteImage {
            if isFromShare {
                managedObjectContext.delete(self)
                return
            }
            imageData = nil
        }
        if let shoppablesSet = shoppables as? Set<Shoppable> {
            shoppablesSet.forEach { managedObjectContext.delete($0) }
        }
        shoppablesCount = -1
        syteJson = nil
        shareLink = nil
        uploadedImageURL = nil
    }
    
    public func setHide() {
        let managedObjectID = self.objectID
        DataModel.sharedInstance.performBackgroundTask { (managedObjectContext) in
            do {
                guard let screenshot = managedObjectContext.object(with: managedObjectID) as? Screenshot,
                    screenshot.isHidden == false else {
                        return
                }
                screenshot.isHidden = true
                screenshot.hideWorkhorse(managedObjectContext: managedObjectContext)
                try managedObjectContext.save()
            } catch {
                DataModel.sharedInstance.receivedCoreDataError(error: error)
                print("setHide objectID:\(managedObjectID) results with error:\(error)")
            }
        }
    }
    
    public func setViewed() {
        let managedObjectID = self.objectID
        DataModel.sharedInstance.performBackgroundTask { (managedObjectContext) in
            let fetchRequest: NSFetchRequest<Screenshot> = Screenshot.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "SELF == %@", managedObjectID)
            fetchRequest.sortDescriptors = nil
            
            do {
                let results = try managedObjectContext.fetch(fetchRequest)
                for screenshot in results {
                    screenshot.isNew = false
                }
                try managedObjectContext.save()
            } catch {
                DataModel.sharedInstance.receivedCoreDataError(error: error)
                print("setViewed objectID:\(managedObjectID) results with error:\(error)")
            }
        }
    }
    
    func shoppablesBoundingFrame(in size: CGSize) -> CGRect {
        var frame: CGRect = .null
        
        if let shoppables = shoppables {
            for shoppable in shoppables {
                if let shoppable = shoppable as? Shoppable {
                    frame = frame.union(shoppable.frame(size: size))
                }
            }
        }
        
        return frame
    }
    
    var favoritedShoppablesCount: Int {
        if let favoritedShoppablesCount = shoppables?.filtered(using: NSPredicate(format: "ANY products.isFavorite == TRUE")).count {
            return favoritedShoppablesCount
        }
        return 0
    }
    
    
    var favoritedProducts: [Product] {
        let sortDescriptors = [NSSortDescriptor(key: "dateFavorited", ascending: false)]
        if let sortedFavorites = favorites?.sortedArray(using: sortDescriptors) as? [Product] {
            return sortedFavorites
        }
        return []
    }
    
}

extension Shoppable {
    
    public func frame(size: CGSize) -> CGRect {
        let viewWidth = Double(size.width)
        let viewHeight = Double(size.height)
        let frame = CGRect(x: b0x * viewWidth, y: b0y * viewHeight, width: (b1x - b0x) * viewWidth, height: (b1y - b0y) * viewHeight)
        return frame
    }
    
    public func cropped(image: UIImage, thumbSize:CGSize) -> UIImage? {
        let cropFrame = self.frame(size: image.size)
        let imageFrame = CGRect.init(origin: .zero, size: image.size)
        let thumbFrame = CGRect.init(origin: .zero, size: thumbSize)
        let cropFrameWithoutWhiteBars = thumbFrame.aspectFit(around:cropFrame).intersection(imageFrame)
        
        if let imageRef = image.cgImage?.cropping(to: cropFrameWithoutWhiteBars) {
            let croppedImage = UIImage(cgImage: imageRef, scale: UIScreen.main.scale, orientation: .up)
            return croppedImage
        }else{
            return nil
        }
    }
    
    private func productFilter(managedObjectContext: NSManagedObjectContext, optionsMask: Int) -> ProductFilter? {
        let shoppableID = self.objectID
        let fetchRequest: NSFetchRequest<ProductFilter> = ProductFilter.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "shoppable == %@ AND optionsMask == %d", shoppableID, optionsMask)
        fetchRequest.sortDescriptors = nil
        
        do {
            let results = try managedObjectContext.fetch(fetchRequest)
            if let productFilter = results.first {
                return productFilter
            }
        } catch {
            DataModel.sharedInstance.receivedCoreDataError(error: error)
            print("productFilter optionsMask:\(optionsMask)  shoppableID:\(shoppableID) results with error:\(error)")
        }
        return nil
    }
    
    private func productFiltersContains(managedObjectContext: NSManagedObjectContext, optionsMask: ProductsOptionsMask) -> Bool {
        return productFilter(managedObjectContext: managedObjectContext, optionsMask: optionsMask.rawValue) != nil
    }
    
    fileprivate func addProductFilter(managedObjectContext: NSManagedObjectContext, optionsMask: ProductsOptionsMask, rating: Int16 = 0) {
        let productFilterToSave = ProductFilter(context: managedObjectContext)
        productFilterToSave.optionsMask = Int32(optionsMask.rawValue)
        productFilterToSave.rating = rating
        productFilterToSave.productCount = 0
        productFilterToSave.dateSet = Date()
        productFilterToSave.shoppable = self
    }
    
    func getLastFilter() -> ProductFilter? {
        let lastSetDescriptor = NSSortDescriptor(key: "dateSet", ascending: false)
        if let lastSetFilter = productFilters?.sortedArray(using: [lastSetDescriptor]).first as? ProductFilter {
            return lastSetFilter
        }
        return nil
    }
    
    // Updates all this screenshot's shoppables' productFilters' dateSet.
    func set(productsOptions: ProductsOptions, callback: @escaping () -> Void) {
        guard let screenshotId = self.screenshot?.objectID else {
            return
        }
        let optionsMask = ProductsOptionsMask(productsOptions.category, productsOptions.gender, productsOptions.size)
        let optionsMaskInt = optionsMask.rawValue
        DataModel.sharedInstance.performBackgroundTask { (managedObjectContext) in
            let fetchRequest: NSFetchRequest<Shoppable> = Shoppable.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "screenshot == %@", screenshotId)
            fetchRequest.sortDescriptors = nil
            
            do {
                let results = try managedObjectContext.fetch(fetchRequest)
                for shoppable in results {
                    if let lastSetMask = shoppable.getLast(),
                        lastSetMask.rawValue & 0x01C0 != optionsMaskInt & 0x01C0 { // Category bits
                        if let screenshot = shoppable.screenshot {
                            screenshot.hideWorkhorse(managedObjectContext: managedObjectContext, deleteImage: false)
                            screenshot.syteJson = (optionsMaskInt & ProductsOptionsMask.categoryFurniture.rawValue > 0) ? "f" : "h"
                            AssetSyncModel.sharedInstance.processingQ.async {
                                AssetSyncModel.sharedInstance.rescanClassification(assetId: screenshot.assetId!, imageData: screenshot.imageData as Data?, optionsMask: optionsMask)
                            }
                        }
                        break // Break out of the shoppable for loop
                    }
                    if let matchingFilter = shoppable.productFilters?.filtered(using: NSPredicate(format: "optionsMask == %d", optionsMaskInt)).first as? ProductFilter {
                        matchingFilter.dateSet = Date()
                        if matchingFilter.productCount == 0,
                            let actualFilteredProductCount = shoppable.products?.filtered(using: NSPredicate(format: "(optionsMask & %d) == %d", optionsMaskInt, optionsMaskInt)).count {
                            matchingFilter.productCount = Int16(actualFilteredProductCount)
                        }
                        shoppable.productFilterCount = matchingFilter.productCount
                        continue
                    }
                    shoppable.addProductFilter(managedObjectContext: managedObjectContext, optionsMask: optionsMask)
                    shoppable.productFilterCount = 0
                    guard let offersURL = shoppable.offersURL else {
                        continue
                    }
                    if let actualFilteredProductCount = shoppable.products?.filtered(using: NSPredicate(format: "(optionsMask & %d) == %d", optionsMaskInt, optionsMaskInt)).count,
                        actualFilteredProductCount > 0 {
                        continue
                    }
                    AssetSyncModel.sharedInstance.reExtractProducts(shoppableId: shoppable.objectID, optionsMask: optionsMask, offersURL: offersURL)
                }
                try managedObjectContext.save()
                DispatchQueue.main.async(execute: callback)
            } catch {
                DataModel.sharedInstance.receivedCoreDataError(error: error)
                print("shoppable set optionsMask results with error:\(error)")
            }
        }
    }
    
    func getLast() -> ProductsOptionsMask? {
        if let lastSetFilter = getLastFilter() {
            return ProductsOptionsMask(rawValue: Int(lastSetFilter.optionsMask))
        }
        return nil
    }
    
    public func getRating() -> Int16 {
        if let lastSetFilter = getLastFilter() {
            return lastSetFilter.rating
        }
        return 0
    }
    
    public func setRating(positive: Bool) {
        let shoppableID = self.objectID
        let imageUrl = self.screenshot?.uploadedImageURL
        let offersUrl = self.offersURL
        let category = self.label
        let b0x = self.b0x
        let b0y = self.b0y
        let b1x = self.b1x
        let b1y = self.b1y
        
        let dataModel = DataModel.sharedInstance
        dataModel.performBackgroundTask { (managedObjectContext) in
            let fetchRequest: NSFetchRequest<ProductFilter> = ProductFilter.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "shoppable == %@", shoppableID)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateSet", ascending: false)]
            
            do {
                let results = try managedObjectContext.fetch(fetchRequest)
                let positiveRating: Int16 = 5
                let negativeRating: Int16 = 1
                let ratingValue: Int16 = positive ? positiveRating : negativeRating
                let optionsMask: ProductsOptionsMask
                if let productFilter = results.first {
                    productFilter.rating = ratingValue
                    optionsMask = ProductsOptionsMask(rawValue: Int(productFilter.optionsMask))
                } else {
                    guard let shoppable = dataModel.retrieveShoppable(managedObjectContext: managedObjectContext, objectId: shoppableID) else {
                        return
                    }
                    optionsMask = ProductsOptionsMask(.auto, .auto, .adult) // Historical value that was never set.
                    shoppable.addProductFilter(managedObjectContext: managedObjectContext, optionsMask: optionsMask, rating: ratingValue)
                }
                var augmentedOffersUrl: String? = nil
                if let offersUrl = offersUrl {
                    augmentedOffersUrl = AssetSyncModel.sharedInstance.augmentedUrl(offersURL: offersUrl, optionsMask: optionsMask)?.absoluteString
                }
                NetworkingPromise.sharedInstance.feedbackToSyte(isPositive: positive, imageUrl: imageUrl, offersUrl: augmentedOffersUrl, b0x: b0x, b0y: b0y, b1x: b1x, b1y: b1y)
                
                let imageOrDash = imageUrl ?? "-"
                let categoryOrDash = category ?? "-"
                let augmentedOffersUrlOrDash = augmentedOffersUrl ?? "-"
                if positive {
                    AnalyticsTrackers.standard.track(.shoppableRatingPositive, properties: ["Rating" : positiveRating, "Screenshot" : imageOrDash, "Category" : categoryOrDash, "AugmentedOffersUrl" : augmentedOffersUrlOrDash])
                } else {
                    AnalyticsTrackers.standard.track(.shoppableRatingNegative, properties: ["Rating" : negativeRating, "Screenshot" : imageOrDash, "Category" : categoryOrDash, "AugmentedOffersUrl" : augmentedOffersUrlOrDash])
                }
                try managedObjectContext.save()
            } catch {
                DataModel.sharedInstance.receivedCoreDataError(error: error)
                print("setRating shoppableID:\(shoppableID) results with error:\(error)")
            }
        }
    }
    
}

extension Product {
    
    func getSortDateForProductBar() -> Date {
        
        var date = Date.distantPast
        
        if self.isFavorite, let dateFavorited = self.dateFavorited as Date?{
            date = dateFavorited
        }
        
        if  let dateViewed = self.dateViewed as Date?{
            if dateViewed.compare(date) == .orderedDescending {
                date = dateViewed
            }
        }
        
        return date
    }
    
    public func recordViewedProduct(){
        let now = Date()
        let managedObjectID = self.objectID
        DataModel.sharedInstance.performBackgroundTask { (managedObjectContext) in
            let fetchRequest: NSFetchRequest<Product> = Product.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "SELF == %@", managedObjectID)
            fetchRequest.sortDescriptors = nil
            
            do {
                let results = try managedObjectContext.fetch(fetchRequest)
                for product in results {
                    product.dateViewed = now
                    product.dateSortProductBar = product.getSortDateForProductBar()
                    product.hideFromProductBar = false
                }
                try managedObjectContext.save()
            } catch {
                DataModel.sharedInstance.receivedCoreDataError(error: error)
                print("recordViewedProduct objectID:\(managedObjectID) results with error:\(error)")
            }
        }
    }
    
    
    public func setFavorited(toFavorited: Bool) {
        let managedObjectID = self.objectID
        DataModel.sharedInstance.performBackgroundTask { (managedObjectContext) in
            let fetchRequest: NSFetchRequest<Product> = Product.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "SELF == %@", managedObjectID)
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
                    let score = UserDefaults.standard.integer(forKey: UserDefaultsKeys.gameScore)
                    UserDefaults.standard.set(score + 1, forKey: UserDefaultsKeys.gameScore)
                }
            } catch {
                DataModel.sharedInstance.receivedCoreDataError(error: error)
                print("setFavorited objectID:\(managedObjectID) results with error:\(error)")
            }
        }
    }
    
    override public func awakeFromFetch() {
        super.awakeFromFetch()
        if let displayBrand = brand,
            !displayBrand.isEmpty {
            displayTitle = displayBrand
        } else {
            displayTitle = merchant
        }
    }
    
    public func isSale() -> Bool {
        return floatPrice < floatOriginalPrice
    }
    
    public func imageURLs() -> [URL] {
        return altImageURLs?.components(separatedBy: ",").compactMap {URL(string: $0)} ?? []
    }
    
    func productTitle() -> String? {
        return productDescription?.productTitle()
    }
    
}

extension Variant {
    
    func parsedImageURLs() -> [URL] {
        return imageURLs?.components(separatedBy: ",").compactMap { URL(string: $0) } ?? []
    }
    
}

extension Matchstick {
    
    public func add(callback: ((_ screenshot: Screenshot) -> Void)? = nil) {
        let managedObjectID = self.objectID
        let dataModel = DataModel.sharedInstance
        dataModel.performBackgroundTask { (managedObjectContext) in
            do {
                if let matchstick = managedObjectContext.object(with: managedObjectID) as? Matchstick,
                    let assetId = matchstick.remoteId,
                    let uploadedImageURL = matchstick.imageUrl,
                    let syteJson = matchstick.syteJson,
                    let segments = NetworkingPromise.sharedInstance.jsonDestringify(string: syteJson) {
                    let addedScreenshot = dataModel.saveScreenshot(managedObjectContext: managedObjectContext,
                                                                   assetId: assetId,
                                                                   createdAt: Date(),
                                                                   isRecognized: true,
                                                                   source: .discover,
                                                                   isHidden: false,
                                                                   imageData: matchstick.imageData as Data?,
                                                                   classification: nil)
                    addedScreenshot.uploadedImageURL = uploadedImageURL
                    addedScreenshot.syteJson = syteJson
                    if callback == nil {
                        managedObjectContext.delete(matchstick)
                    }
                    try managedObjectContext.save()
                    AssetSyncModel.sharedInstance.processingQ.async {
                        AssetSyncModel.sharedInstance.saveShoppables(assetId: assetId, uploadedURLString: uploadedImageURL, segments: segments)
                    }
                    if let callback = callback {
                        let addedScreenshotOID = addedScreenshot.objectID
                        DispatchQueue.main.async {
                            if let mainScreenshot = dataModel.mainMoc().object(with: addedScreenshotOID) as? Screenshot {
                                callback(mainScreenshot)
                            }
                        }
                    }
                    if callback == nil,
                        dataModel.isNextMatchsticksNeeded(matchstickCount: dataModel.countMatchsticks(managedObjectContext: managedObjectContext)) {
                        MatchstickModel.shared.fetchNextIfBelowWatermark()
                    }
                } else {
                    print("matchstick add managedObjectID:\(managedObjectID) not found")
                }
            } catch {
                DataModel.sharedInstance.receivedCoreDataError(error: error)
                print("matchstick add managedObjectID:\(managedObjectID) results with error:\(error)")
            }
        }
    }
    
    public func pass() {
        let managedObjectID = self.objectID
        let dataModel = DataModel.sharedInstance
        dataModel.performBackgroundTask { (managedObjectContext) in
            do {
                if let matchstick = managedObjectContext.object(with: managedObjectID) as? Matchstick {
                    managedObjectContext.delete(matchstick)
                    try managedObjectContext.save()
                    if dataModel.isNextMatchsticksNeeded(matchstickCount: dataModel.countMatchsticks(managedObjectContext: managedObjectContext)) {
                        MatchstickModel.shared.fetchNextIfBelowWatermark()
                    }
                } else {
                    print("matchstick pass managedObjectID:\(managedObjectID) not found")
                }
            } catch {
                DataModel.sharedInstance.receivedCoreDataError(error: error)
                print("matchstick pass managedObjectID:\(managedObjectID) results with error:\(error)")
            }
        }
    }
    
}

extension CartItem {
    
    func productTitle() -> String? {
        return productDescription?.productTitle()
    }
    
}

extension Card {
    
    func cardNumberKeychainKey() -> String {
        return objectID.uriRepresentation().absoluteString
    }
    
    func retrieveCardNumber() -> String? {
        let key = cardNumberKeychainKey()
        let startKeychain = Date()
        let cardNumber = KeychainWrapper.standard.string(forKey: key)
        let hasValue = cardNumber != nil && cardNumber?.isEmpty == false
        print("GMK retrieveCardNumber hasValue:\(hasValue) took \(-startKeychain.timeIntervalSinceNow) seconds")
        return cardNumber
    }
    
    func edit(fullName: String,
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
              phone: String) {
        let oid = objectID
        DataModel.sharedInstance.performBackgroundTask { (managedObjectContext) in
            guard let card = managedObjectContext.object(with: oid) as? Card else {
                print("Card.edit failed to retrieve object with oid:\(oid)")
                return
            }
            card.fullName = fullName
            card.displayNumber = displayNumber
            card.brand = brand
            card.expirationMonth = expirationMonth
            card.expirationYear = expirationYear
            card.street = street
            card.city = city
            card.country = country
            card.zipCode = zipCode
            card.state = state
            card.email = email
            card.phone = phone
            card.isSaved = true
            card.dateModified = Date()
            do {
                try managedObjectContext.save()
                let key = self.cardNumberKeychainKey()
                DispatchQueue.global(qos: .utility).async {
                    let startKeychain = Date()
                    let didUpdateCardNumber: Bool = KeychainWrapper.standard.set(number, forKey: key)
                    print("GMK didUpdateCardNumber:\(didUpdateCardNumber) took \(-startKeychain.timeIntervalSinceNow) seconds")
                }
            } catch {
                DataModel.sharedInstance.receivedCoreDataError(error: error)
            }
        }
    }
    
    func delete() {
        let oid = objectID
        DataModel.sharedInstance.performBackgroundTask { (managedObjectContext) in
            guard let card = managedObjectContext.object(with: oid) as? Card else {
                print("Card.delete failed to retrieve object with oid:\(oid)")
                return
            }
            let key = self.cardNumberKeychainKey()
            managedObjectContext.delete(card)
            do {
                try managedObjectContext.save()
                DispatchQueue.global(qos: .utility).async {
                    let startKeychain = Date()
                    let didDeleteCardNumber: Bool = KeychainWrapper.standard.removeObject(forKey: key)
                    print("GMK didDeleteCardNumber:\(didDeleteCardNumber) took \(-startKeychain.timeIntervalSinceNow) seconds")
                }
            } catch {
                DataModel.sharedInstance.receivedCoreDataError(error: error)
            }
        }
    }
    
}

extension ShippingAddress {
    
    func edit(firstName: String?,
              lastName: String?,
              street: String,
              city: String,
              country: String,
              zipCode: String,
              state: String?,
              phone: String) {
        let oid = objectID
        DataModel.sharedInstance.performBackgroundTask { (managedObjectContext) in
            guard let shippingAddress = managedObjectContext.object(with: oid) as? ShippingAddress else {
                print("ShippingAddress.edit failed to retrieve object with oid:\(oid)")
                return
            }
            shippingAddress.firstName = firstName
            shippingAddress.lastName = lastName
            shippingAddress.street = street
            shippingAddress.city = city
            shippingAddress.country = country
            shippingAddress.zipCode = zipCode
            shippingAddress.state = state
            shippingAddress.phone = phone
            shippingAddress.dateModified = Date()
            do {
                try managedObjectContext.save()
            } catch {
                DataModel.sharedInstance.receivedCoreDataError(error: error)
            }
        }
    }
    
    func delete() {
        let oid = objectID
        DataModel.sharedInstance.performBackgroundTask { (managedObjectContext) in
            guard let shippingAddress = managedObjectContext.object(with: oid) as? ShippingAddress else {
                print("ShippingAddress.delete failed to retrieve object with oid:\(oid)")
                return
            }
            managedObjectContext.delete(shippingAddress)
            do {
                try managedObjectContext.save()
            } catch {
                DataModel.sharedInstance.receivedCoreDataError(error: error)
            }
        }
    }
    
    var fullName: String? {
        if let names = [firstName, lastName].filter({ $0?.isEmpty == false }) as? [String] {
            return names.joined(separator: " ")
        }
        return nil
    }
    
    var readableAddress: String? {
        guard let street = street, let city = city, let state = state, let zip = zipCode, let country = country else {
            return nil
        }
        
        return """
        \(street)
        \(city), \(state) \(zip)
        \(country)
        """
    }
    
}

extension NSFetchedResultsController {
    @objc var fetchedObjectsCount:Int {
        get {
            return sections?.reduce(0, {$0 + $1.numberOfObjects}) ?? 0
        }
    }
}

fileprivate extension String {
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
    func saveIfNeeded(){
        if self.hasChanges {
            do {
                try self.save()
            } catch {
                DataModel.sharedInstance.receivedCoreDataError(error: error)
            }
        }
    }
    
    func objectId(for objectIdUrl:URL) -> NSManagedObjectID? {
        return self.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: objectIdUrl)
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
