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

@objc public protocol FrcDelegateProtocol : class {
    func frc(_ frc:NSFetchedResultsController<NSFetchRequestResult>, oneAddedAt indexPath: IndexPath)
    func frc(_ frc:NSFetchedResultsController<NSFetchRequestResult>, oneDeletedAt indexPath: IndexPath)
    func frc(_ frc:NSFetchedResultsController<NSFetchRequestResult>, oneUpdatedAt indexPath: IndexPath)
    func frcReloadData(_ frc:NSFetchedResultsController<NSFetchRequestResult>)
}

enum CZChangeKind {
    case none, singleAdd, singleDelete, singleUpdate, multiple
}


class ShoppableFrc: NSFetchedResultsController<Shoppable> {
    public let hasShoppablesFrc: NSFetchedResultsController<Screenshot>
    init(fetchRequest: NSFetchRequest<Shoppable>, managedObjectContext: NSManagedObjectContext, sectionNameKeyPath: String?, cacheName: String?, hasShoppablesFrc: NSFetchedResultsController<Screenshot>) {
        self.hasShoppablesFrc = hasShoppablesFrc
        super.init(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
    }
}

class DataModel: NSObject {
    
    public static let sharedInstance = DataModel()
    public static func setup() {
        let _ = DataModel.sharedInstance
    }

    public static func docsDirURL() -> URL {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls.last! // If no documents dir, just crash.
    }
    
    public var coreDataStackFailureHandler: (() -> Void)?
    public var coreDataStackCompletionHandler: (() -> Void)?
    public var isCoreDataStackReady = false
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Model")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                print("loadPersistentStores error:\(error)")
                if let handler = self.coreDataStackFailureHandler {
                    DispatchQueue.main.async {
                        handler()
                    }
                }
            } else {
                container.viewContext.automaticallyMergesChangesFromParent = true
                self.isCoreDataStackReady = true
                if let handler = self.coreDataStackCompletionHandler {
                    DispatchQueue.main.async {
                        handler()
                    }
                }
            }
        }
        return container
    }()
    
    func mainMoc() -> NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    public func adHocMoc() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
    
    override init() {
        super.init()
        DispatchQueue.global(qos: .userInitiated).async {
            let _ = self.persistentContainer
        }
    }
    
    // See https://stackoverflow.com/questions/42733574/nspersistentcontainer-concurrency-for-saving-to-core-data . Go Rose!
    let dbQ = DispatchQueue(label: "io.crazeapp.screenshot.db.serial")

    // MARK: - FRC

    public lazy var screenshotFrc: NSFetchedResultsController<Screenshot> = {
        let request: NSFetchRequest<Screenshot> = Screenshot.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "lastModified", ascending: false), NSSortDescriptor(key: "createdAt", ascending: false)]
        request.predicate = NSPredicate(format: "isHidden == FALSE AND isFashion == TRUE")
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.mainMoc(), sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Failed to fetch screenshots from core data:\(error)")
        }
        return fetchedResultsController
    }()
    weak open var screenshotFrcDelegate: FrcDelegateProtocol?
    
    fileprivate var screenshotChangeIndexPath: IndexPath?
    fileprivate var screenshotChangeKind: CZChangeKind = .none
    
    
    public func setupShoppableFrc(screenshot: Screenshot) -> ShoppableFrc {
        let hasShoppablesRequest: NSFetchRequest<Screenshot> = Screenshot.fetchRequest()
        hasShoppablesRequest.sortDescriptors = [NSSortDescriptor(key: "lastModified", ascending: false)]
        hasShoppablesRequest.predicate = NSPredicate(format: "SELF == %@", screenshot.objectID)
        let hasShoppablesFetchedResultsController = NSFetchedResultsController(fetchRequest: hasShoppablesRequest, managedObjectContext: self.mainMoc(), sectionNameKeyPath: nil, cacheName: nil)
        hasShoppablesFrc = hasShoppablesFetchedResultsController
        hasShoppablesFrc?.delegate = self
        
        let request: NSFetchRequest<Shoppable> = Shoppable.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true), NSSortDescriptor(key: "b0x", ascending: true), NSSortDescriptor(key: "b0y", ascending: true), NSSortDescriptor(key: "b1x", ascending: true), NSSortDescriptor(key: "b1y", ascending: true), NSSortDescriptor(key: "offersURL", ascending: true)]
        request.predicate = NSPredicate(format: "screenshot == %@ AND productCount > 0", screenshot)
        let fetchedResultsController = ShoppableFrc(fetchRequest: request, managedObjectContext: self.mainMoc(), sectionNameKeyPath: nil, cacheName: nil, hasShoppablesFrc: hasShoppablesFrc!)
        shoppableFrc = fetchedResultsController as NSFetchedResultsController<Shoppable>
        shoppableFrc?.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
            try hasShoppablesFetchedResultsController.performFetch()
        } catch {
            print("Failed to fetch shoppables from core data:\(error)")
        }
        return fetchedResultsController
    }
    
    public func clearShoppableFrc() {
        shoppableFrc?.delegate = nil
        shoppableFrc = nil
        hasShoppablesFrc?.delegate = nil
        hasShoppablesFrc = nil
    }
    
    weak open var shoppableFrcDelegate: FrcDelegateProtocol?
    
    fileprivate var shoppableFrc: NSFetchedResultsController<Shoppable>?
    fileprivate var shoppableChangeIndexPath: IndexPath?
    fileprivate var shoppableChangeKind: CZChangeKind = .none
    fileprivate var hasShoppablesFrc: NSFetchedResultsController<Screenshot>?
    fileprivate var hasShoppablesChangeIndexPath: IndexPath?
    fileprivate var hasShoppablesChangeKind: CZChangeKind = .none

    
    public lazy var favoriteFrc: NSFetchedResultsController<Product> = {
        let request: NSFetchRequest<Product> = Product.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "dateFavorited", ascending: false)]
        request.predicate = NSPredicate(format: "isFavorite == TRUE")
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.mainMoc(), sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Failed to fetch favorites from core data:\(error)")
        }
        return fetchedResultsController
    }()
    weak open var favoriteFrcDelegate: FrcDelegateProtocol?
    
    fileprivate var favoriteChangeIndexPath: IndexPath?
    fileprivate var favoriteChangeKind: CZChangeKind = .none

}

extension DataModel: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        let shoppableFrcStandIn = shoppableFrc == nil ? NSFetchedResultsController() : shoppableFrc!
        let hasShoppablesFrcStandIn = hasShoppablesFrc == nil ? NSFetchedResultsController() : hasShoppablesFrc!
        switch controller {
        case screenshotFrc:
            screenshotChangeKind = .none
            screenshotChangeIndexPath = nil
        case shoppableFrcStandIn:
            shoppableChangeKind = .none
            shoppableChangeIndexPath = nil
        case hasShoppablesFrcStandIn:
            hasShoppablesChangeKind = .none
            hasShoppablesChangeIndexPath = nil
        case favoriteFrc:
            favoriteChangeKind = .none
            favoriteChangeIndexPath = nil
        default:
            print("Unknown controller:\(controller) in controllerWillChangeContent")
        }
    }
    
    func didChange(changeKind: inout CZChangeKind, changeIndexPath: inout IndexPath?, type: NSFetchedResultsChangeType, indexPath: IndexPath?, newIndexPath: IndexPath?) {
        if changeKind != .none || changeIndexPath != nil {
            changeKind = .multiple
        } else {
            switch type {
            case .insert:
                changeKind = .singleAdd
                changeIndexPath = newIndexPath
            case .delete:
                changeKind = .singleDelete
                changeIndexPath = indexPath
            case .update:
                changeKind = .singleUpdate
                changeIndexPath = indexPath
            default:
                changeKind = .multiple
            }
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        let shoppableFrcStandIn = shoppableFrc == nil ? NSFetchedResultsController() : shoppableFrc!
        let hasShoppablesFrcStandIn = hasShoppablesFrc == nil ? NSFetchedResultsController() : hasShoppablesFrc!
        switch controller {
        case screenshotFrc:
            didChange(changeKind: &screenshotChangeKind, changeIndexPath: &screenshotChangeIndexPath, type: type, indexPath: indexPath, newIndexPath: newIndexPath)
        case shoppableFrcStandIn:
            didChange(changeKind: &shoppableChangeKind, changeIndexPath: &shoppableChangeIndexPath, type: type, indexPath: indexPath, newIndexPath: newIndexPath)
        case hasShoppablesFrcStandIn:
            didChange(changeKind: &hasShoppablesChangeKind, changeIndexPath: &hasShoppablesChangeIndexPath, type: type, indexPath: indexPath, newIndexPath: newIndexPath)
        case favoriteFrc:
            didChange(changeKind: &favoriteChangeKind, changeIndexPath: &favoriteChangeIndexPath, type: type, indexPath: indexPath, newIndexPath: newIndexPath)
        default:
            print("Unknown controller:\(controller) in controller didChange")
        }
    }
    
    func didChangeContent(frc: NSFetchedResultsController<NSFetchRequestResult>, changeKind: inout CZChangeKind, changeIndexPath: inout IndexPath?, frcDelegate: FrcDelegateProtocol?) {
        switch changeKind {
        case .none:
            print("DataModel didChangeContent no change. Weird")
        case .singleAdd:
            if let changeIndexPath = changeIndexPath {
                frcDelegate?.frc(frc, oneAddedAt: changeIndexPath)
            } else {
                print("Error DataModel singleAdd changeIndexPath nil")
                frcDelegate?.frcReloadData(frc)
            }
        case .singleDelete:
            if let changeIndexPath = changeIndexPath {
                frcDelegate?.frc(frc, oneDeletedAt: changeIndexPath)
            } else {
                print("Error DataModel singleDelete changeIndexPath nil")
                frcDelegate?.frcReloadData(frc)
            }
        case .singleUpdate:
            if let changeIndexPath = changeIndexPath {
                frcDelegate?.frc(frc, oneUpdatedAt: changeIndexPath)
            } else {
                print("Error DataModel singleAdd changeIndexPath nil")
                frcDelegate?.frcReloadData(frc)
            }
        case .multiple:
            frcDelegate?.frcReloadData(frc)
        }
        changeKind = .none
        changeIndexPath = nil
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        let shoppableFrcStandIn = shoppableFrc == nil ? NSFetchedResultsController() : shoppableFrc!
        let hasShoppablesFrcStandIn = hasShoppablesFrc == nil ? NSFetchedResultsController() : hasShoppablesFrc!
        switch controller {
        case screenshotFrc:
            didChangeContent(frc: controller, changeKind: &screenshotChangeKind, changeIndexPath: &screenshotChangeIndexPath, frcDelegate: screenshotFrcDelegate)
        case shoppableFrcStandIn:
            didChangeContent(frc: controller, changeKind: &shoppableChangeKind, changeIndexPath: &shoppableChangeIndexPath, frcDelegate: shoppableFrcDelegate)
        case hasShoppablesFrcStandIn:
            didChangeContent(frc: controller, changeKind: &hasShoppablesChangeKind, changeIndexPath: &hasShoppablesChangeIndexPath, frcDelegate: shoppableFrcDelegate)
        case favoriteFrc:
            didChangeContent(frc: controller, changeKind: &favoriteChangeKind, changeIndexPath: &favoriteChangeIndexPath, frcDelegate: favoriteFrcDelegate)
        default:
            print("Unknown controller:\(controller) in controllerDidChangeContent")
        }
    }
    
}

extension DataModel {
    
    // Save a new Screenshot to Core Data.
    func saveScreenshot(managedObjectContext: NSManagedObjectContext,
                        assetId: String,
                        createdAt: Date?,
                        isFashion: Bool,
                        isFromShare: Bool,
                        isHidden: Bool,
                        imageData: Data?) -> Screenshot {
        let screenshotToSave = Screenshot(context: managedObjectContext)
        screenshotToSave.assetId = assetId
        if let nsDate = createdAt as NSDate? {
            screenshotToSave.createdAt = nsDate
        }
        screenshotToSave.isFashion = isFashion
        screenshotToSave.isFromShare = isFromShare
        screenshotToSave.isHidden = isHidden
        screenshotToSave.isNew = true
        if let nsData = imageData as NSData? {
            screenshotToSave.imageData = nsData
        }
        screenshotToSave.lastModified = NSDate()
        do {
            try managedObjectContext.save()
        } catch {
            print("Failed to saveScreenshot")
        }
        return screenshotToSave
    }
    
    func retrieveAllAssetIds(managedObjectContext: NSManagedObjectContext) -> Set<String> {
        return retrieveAssetIds(managedObjectContext: managedObjectContext, predicate: nil)
    }
    
    func retrieveCompleteAssetIds(managedObjectContext: NSManagedObjectContext) -> Set<String> {
        return retrieveAssetIds(managedObjectContext: managedObjectContext, predicate: NSPredicate(format: "isFashion != nil"))
    }
    
    func retrieveHiddenAssetIds(managedObjectContext: NSManagedObjectContext) -> Set<String> {
        return retrieveAssetIds(managedObjectContext: managedObjectContext, predicate: NSPredicate(format: "isHidden == TRUE"))
    }
    
    func retrieveLastScreenshotAssetId(managedObjectContext: NSManagedObjectContext) -> String? {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest<NSFetchRequestResult>(entityName: "Screenshot")
        fetchRequest.predicate = NSPredicate(format: "isFashion == TRUE AND isFromShare == FALSE AND isHidden == TRUE") // match uploadScreenshotWithClarifai
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        fetchRequest.fetchLimit = 1
        fetchRequest.includesSubentities = false
        fetchRequest.resultType = .dictionaryResultType
        fetchRequest.includesPendingChanges = false
        fetchRequest.propertiesToFetch = ["assetId"]
        fetchRequest.returnsDistinctResults = true
        fetchRequest.includesPropertyValues = true
        fetchRequest.shouldRefreshRefetchedObjects = false
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            guard let results = try managedObjectContext.fetch(fetchRequest) as? [[String : String]],
              let result = results.first,
              let assetId = result["assetId"] else {
                print("retrieveLastScreenshotAssetId failed to fetch dictionaries")
                return nil
            }
            return assetId
        } catch {
            print("retrieveAllAssetIds results with error:\(error)")
        }
        return nil
    }
    
    func retrieveAssetIds(managedObjectContext: NSManagedObjectContext, predicate: NSPredicate?) -> Set<String> {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest<NSFetchRequestResult>(entityName: "Screenshot")
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = nil //[NSSortDescriptor(key: "createdAt", ascending: false)]
        fetchRequest.includesSubentities = false
        fetchRequest.resultType = .dictionaryResultType
        fetchRequest.includesPendingChanges = false
        fetchRequest.propertiesToFetch = ["assetId"]
        fetchRequest.returnsDistinctResults = true
        fetchRequest.includesPropertyValues = true
        fetchRequest.shouldRefreshRefetchedObjects = false
        fetchRequest.returnsObjectsAsFaults = false
        
        var assetIdsSet = Set<String>()
        do {
            guard let results = try managedObjectContext.fetch(fetchRequest) as? [[String : String]] else {
                print("retrieveAssetIds failed to fetch dictionaries")
                return assetIdsSet
            }
            for result in results {
                if let assetId = result["assetId"] {
                    assetIdsSet.insert(assetId)
                }
            }
        } catch {
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
            print("retrieveScreenshot assetId:\(assetId) results with error:\(error)")
        }
        return nil
    }
    
    func deleteScreenshots(managedObjectContext: NSManagedObjectContext, assetIds: Set<String>) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest<NSFetchRequestResult>(entityName: "Screenshot")
        fetchRequest.predicate = NSPredicate(format: "assetId IN %@", assetIds)
        fetchRequest.sortDescriptors = nil //[NSSortDescriptor(key: "createdAt", ascending: false)]
        fetchRequest.includesSubentities = false
        fetchRequest.resultType = .managedObjectIDResultType
        fetchRequest.includesPendingChanges = false
        fetchRequest.propertiesToFetch = nil
        fetchRequest.includesPropertyValues = false
        fetchRequest.shouldRefreshRefetchedObjects = true
        
        do {
            let results = try managedObjectContext.fetch(fetchRequest)
            guard let managedObjectIds = results as? [NSManagedObjectID] else {
                return
            }
            for managedObjectId in managedObjectIds {
                let managedObject = managedObjectContext.object(with: managedObjectId)
                managedObjectContext.delete(managedObject)
            }
            try managedObjectContext.save()
        } catch {
            print("deleteScreenshots results with error:\(error)")
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
        productToSave.optionsMask = optionsMask
        return productToSave
    }
    
    // See: https://stackoverflow.com/questions/42733574/nspersistentcontainer-concurrency-for-saving-to-core-data
    // I thought dataModel.persistentContainer.performBackgroundTask ran against a single internal serial queue.
    // But it only runs against a private queue, and each call may have its own private queue running in parallel.
    // Thanks for still getting it wrong, Apple. So here is what I thought Apple would be doing.
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        dbQ.async {
            let managedObjectContext = DataModel.sharedInstance.adHocMoc()
            managedObjectContext.performAndWait {
                block(managedObjectContext)
            }
        }
    }
    
    func backgroundPromise(dict: [String : Any], block: @escaping (NSManagedObjectContext) -> NSManagedObject) -> Promise<(NSManagedObject, [String : Any])> {
        return Promise { fulfill, reject in
            dbQ.async {
                let managedObjectContext = DataModel.sharedInstance.adHocMoc()
                managedObjectContext.perform {
                    fulfill(block(managedObjectContext), dict)
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
                    product.isFavorite = false
                }
                try managedObjectContext.save()
            } catch {
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
                print("setNoShoppables assetId:\(assetId) results with error:\(error)")
            }
        }
    }

    // Must be called on main.
    @objc public func countShared() -> Int {
        let predicate = NSPredicate(format: "isFromShare == TRUE AND shoppablesCount > 0")
        return countScreenshotWorkhorse(predicate: predicate)
    }
    
    // Must be called on main.
    @objc public func countScreenshotted() -> Int {
        let predicate = NSPredicate(format: "isFromShare == FALSE AND shoppablesCount > 0")
        return countScreenshotWorkhorse(predicate: predicate)
    }
    
    // Must be called on main.
    @objc public func countTotalScreenshots() -> Int {
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
            print("countScreenshotWorkhorse results with error:\(error)")
        }
        return count
    }
    
    // Update changes made in the background
    public func saveMain() {
        saveMoc(managedObjectContext: mainMoc())
    }
    
    public func pinMain() {
        do {
            try mainMoc().setQueryGenerationFrom(NSQueryGenerationToken.current)
        } catch {
            print("pinMain results with error:\(error)")
        }
    }
    
    public func unpinMain() {
        do {
            try mainMoc().setQueryGenerationFrom(nil)
        } catch {
            print("unpinMain results with error:\(error)")
        }
    }

    public func saveMoc(managedObjectContext: NSManagedObjectContext) {
        do {
            try managedObjectContext.save()
        } catch {
            print("Updating db results with error:\(error)")
        }
    }

}

extension Screenshot {
    
    @objc public func setHide() {
        let managedObjectID = self.objectID
        DataModel.sharedInstance.performBackgroundTask { (managedObjectContext) in
            let fetchRequest: NSFetchRequest<Screenshot> = Screenshot.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "SELF == %@", managedObjectID)
            fetchRequest.sortDescriptors = nil
            
            do {
                let results = try managedObjectContext.fetch(fetchRequest)
                for screenshot in results {
                    screenshot.isHidden = true
                    screenshot.imageData = nil
                }
                try managedObjectContext.save()
            } catch {
                print("setHide objectID:\(managedObjectID) results with error:\(error)")
            }
        }
    }
    
    @objc public func setViewed() {
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
                print("setViewed objectID:\(managedObjectID) results with error:\(error)")
            }
        }
    }

}

extension Shoppable {
    
    @objc public func frame(size: CGSize) -> CGRect {
        let viewWidth = Double(size.width)
        let viewHeight = Double(size.height)
        let frame = CGRect(x: b0x * viewWidth, y: b0y * viewHeight, width: (b1x - b0x) * viewWidth, height: (b1y - b0y) * viewHeight)
        return frame
    }
    
    @objc public func cropped(image: UIImage) -> UIImage? {
        let cropFrame = self.frame(size: image.size)
        guard let imageRef = image.cgImage?.cropping(to: cropFrame) else {
            return nil
        }
        let croppedImage = UIImage(cgImage: imageRef, scale: UIScreen.main.scale, orientation: .up)
        return croppedImage
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
        productFilterToSave.dateSet = NSDate()
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
    @objc func set(productsOptions: ProductsOptions) {
        guard let screenshotId = self.screenshot?.objectID else {
            return
        }
       var optionsMaskInt: Int
        switch productsOptions.gender! { // TODO: GMK remove "!" once productsOptions.gender not optional.
        case .male:
            optionsMaskInt = ProductsOptionsMask.genderMale.rawValue
        case .female:
            optionsMaskInt = ProductsOptionsMask.genderFemale.rawValue
        case .unisex:
            optionsMaskInt = ProductsOptionsMask.genderUnisex.rawValue
        }
        switch productsOptions.size! { // TODO: GMK remove "!" once productsOptions.size not optional.
        case .adult:
            optionsMaskInt |= ProductsOptionsMask.sizeAdult.rawValue
        case .child:
            optionsMaskInt |= ProductsOptionsMask.sizeChild.rawValue
        case .plus:
            optionsMaskInt |= ProductsOptionsMask.sizePlus.rawValue
        }
        let optionsMask = ProductsOptionsMask(rawValue: optionsMaskInt)
        DataModel.sharedInstance.performBackgroundTask { (managedObjectContext) in
            let fetchRequest: NSFetchRequest<Shoppable> = Shoppable.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "screenshot == %@", screenshotId)
            fetchRequest.sortDescriptors = nil
            
            do {
                let results = try managedObjectContext.fetch(fetchRequest)
                for shoppable in results {
                    if let matchingFilter = shoppable.productFilters?.filtered(using: NSPredicate(format: "optionsMask == %d", optionsMaskInt)).first as? ProductFilter {
                        matchingFilter.dateSet = NSDate()
                        continue
                    }
                    shoppable.addProductFilter(managedObjectContext: managedObjectContext, optionsMask: optionsMask)
                    guard let offersURL = shoppable.offersURL else {
                        continue
                    }
                    if let existingProducts = shoppable.products as? Set<Product>,
                        existingProducts.contains(where: { $0.optionsMask == optionsMaskInt }) {
                        continue
                    }
                    AssetSyncModel.sharedInstance.reExtractProducts(shoppableId: shoppable.objectID, optionsMask: optionsMask, offersURL: offersURL)
                }
                try managedObjectContext.save()
            } catch {
                print("shoppable set optionsMask results with error:\(error)")
            }
        }
    }
    
    @objc func getLast() -> ProductsOptionsMask? {
        if let lastSetFilter = getLastFilter() {
            return ProductsOptionsMask(rawValue: Int(lastSetFilter.optionsMask))
        }
        return nil
    }

    @objc public func getRating() -> Int16 {
        if let lastSetFilter = getLastFilter() {
            return lastSetFilter.rating
        }
        return 0
    }
    
    @objc public func setRating(positive: Bool) {
        let shoppableID = self.objectID
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
                if let productFilter = results.first {
                    productFilter.rating = ratingValue
                } else {
                    guard let shoppable = dataModel.retrieveShoppable(managedObjectContext: managedObjectContext, objectId: shoppableID) else {
                        return
                    }
                    shoppable.addProductFilter(managedObjectContext: managedObjectContext, optionsMask: ProductsOptionsMask(rawValue: 9), rating: ratingValue)
                }
                try managedObjectContext.save()
            } catch {
                print("setRating shoppableID:\(shoppableID) results with error:\(error)")
            }
        }
    }
    
}

extension Product {
    
    @objc public func setFavorited(toFavorited: Bool) {
        let managedObjectID = self.objectID
        DataModel.sharedInstance.performBackgroundTask { (managedObjectContext) in
            let fetchRequest: NSFetchRequest<Product> = Product.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "SELF == %@", managedObjectID)
            fetchRequest.sortDescriptors = nil
            
            do {
                let results = try managedObjectContext.fetch(fetchRequest)
                for product in results {
                    product.isFavorite = toFavorited
                    product.dateFavorited = toFavorited ? NSDate() : nil
                }
                try managedObjectContext.save()
                
                let score = UserDefaults.standard.integer(forKey: UserDefaultsKeys.gameScore)
                UserDefaults.standard.set(score + 1, forKey: UserDefaultsKeys.gameScore)
            } catch {
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
    
    @objc public func isSale() -> Bool {
        return floatPrice < floatOriginalPrice
    }
    
}
