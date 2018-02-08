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
    func frc(_ frc:NSFetchedResultsController<NSFetchRequestResult>, oneMovedTo indexPath: IndexPath)
    func frcReloadData(_ frc:NSFetchedResultsController<NSFetchRequestResult>)
}

enum CZChangeKind {
    case none, singleAdd, singleDelete, singleUpdate, singleMove, multiple
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

    public var isCoreDataStackReady = false
    
    public let persistentContainer = NSPersistentContainer(name: "Model")
    
    func mainMoc() -> NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    public func adHocMoc() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
    
    fileprivate(set) var isMainPinned = false
    
    override init() {
        super.init()
        DispatchQueue.global(qos: .userInitiated).async {
            self.persistentContainer.loadPersistentStores { (storeDescription, error) in
                if let error = error as NSError? {
                    print("loadPersistentStores error:\(error)")
                    // Must async, or lazy eval closure called infinitely. Might as well async to main, as most handlers are there.
                    // See https://medium.com/@soapyfrog/dont-forget-that-none-of-this-is-thread-safe-so-it-is-actually-possible-for-the-lazy-eval-closure-add1c9b1dd95
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationCenterKeys.coreDataStackCompleted), object: nil, userInfo: ["error" : error])
                    }
                } else {
                    self.persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
                    self.isCoreDataStackReady = true
                    let lastDbVersionMigrated = UserDefaults.standard.integer(forKey: UserDefaultsKeys.lastDbVersionMigrated)
                    if lastDbVersionMigrated != Constants.currentMomVersion {
                        self.postDbMigration(from: lastDbVersionMigrated, to: Constants.currentMomVersion, container: self.persistentContainer)
                        UserDefaults.standard.set(Constants.currentMomVersion, forKey: UserDefaultsKeys.lastDbVersionMigrated)
                    }
                    // See above about lazy eval closure called infinitely if notification not asynced.
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationCenterKeys.coreDataStackCompleted), object: nil, userInfo: ["success" : true])
                    }
                    MatchstickModel.shared.prepareMatchsticks()
                }
            }
        }
    }
    
    // See https://stackoverflow.com/questions/42733574/nspersistentcontainer-concurrency-for-saving-to-core-data . Go Rose!
    let dbQ = DispatchQueue(label: "io.crazeapp.screenshot.db.serial")

    // MARK: - FRC

    public lazy var screenshotFrc: NSFetchedResultsController<Screenshot> = {
        let request: NSFetchRequest<Screenshot> = Screenshot.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "lastModified", ascending: false), NSSortDescriptor(key: "createdAt", ascending: false)]
        request.predicate = NSPredicate(format: "isHidden == FALSE AND isRecognized == TRUE")
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
        request.predicate = NSPredicate(format: "screenshot == %@", screenshot)
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

    
    public lazy var favoriteFrc: NSFetchedResultsController<Screenshot> = {
        let request: NSFetchRequest<Screenshot> = Screenshot.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "lastFavorited", ascending: false)]
        request.predicate = NSPredicate(format: "lastFavorited != nil")
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.mainMoc(), sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Failed to fetch _favoriteFrc from core data:\(error)")
        }
        return fetchedResultsController
    }()
    weak open var favoriteFrcDelegate: FrcDelegateProtocol?
    
    fileprivate var favoriteChangeIndexPath: IndexPath?
    fileprivate var favoriteChangeKind: CZChangeKind = .none
    
    
    public lazy var matchstickFrc: NSFetchedResultsController<Matchstick> = {
        let request: NSFetchRequest<Matchstick> = Matchstick.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "receivedAt", ascending: true)]
        request.predicate = NSPredicate(format: "imageData != nil")
        request.fetchBatchSize = 3
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.mainMoc(), sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Failed to fetch matchsticks from core data:\(error)")
        }
        return fetchedResultsController
    }()
    weak open var matchstickFrcDelegate: FrcDelegateProtocol?
    
    fileprivate var matchstickChangeIndexPath: IndexPath?
    fileprivate var matchstickChangeKind: CZChangeKind = .none
    
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
        case matchstickFrc:
            matchstickChangeKind = .none
            matchstickChangeIndexPath = nil
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
            case .move:
                changeKind = .singleMove
                changeIndexPath = newIndexPath
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
        case matchstickFrc:
            didChange(changeKind: &matchstickChangeKind, changeIndexPath: &matchstickChangeIndexPath, type: type, indexPath: indexPath, newIndexPath: newIndexPath)
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
        case .singleMove:
            if let changeIndexPath = changeIndexPath {
                frcDelegate?.frc(frc, oneMovedTo: changeIndexPath)
            } else {
                print("Error DataModel singleMove changeIndexPath nil")
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
        case matchstickFrc:
            didChangeContent(frc: controller, changeKind: &matchstickChangeKind, changeIndexPath: &matchstickChangeIndexPath, frcDelegate: matchstickFrcDelegate)
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
                        isRecognized: Bool,
                        isFromShare: Bool,
                        isHidden: Bool,
                        imageData: Data?,
                        classification: String?) -> Screenshot {
        let screenshotToSave = Screenshot(context: managedObjectContext)
        screenshotToSave.assetId = assetId
        if let nsDate = createdAt as NSDate? {
            screenshotToSave.createdAt = nsDate
        }
        screenshotToSave.isRecognized = isRecognized
        screenshotToSave.isFromShare = isFromShare
        screenshotToSave.isHidden = isHidden
        screenshotToSave.isNew = true
        if let nsData = imageData as NSData? {
            screenshotToSave.imageData = nsData
        }
        screenshotToSave.lastModified = NSDate()
        if let classification = classification {
            screenshotToSave.syteJson = classification // Dual-purposing syteJson field
        }
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
        return retrieveAssetIds(managedObjectContext: managedObjectContext, predicate: NSPredicate(format: "isRecognized != nil"))
    }
    
    func retrieveHiddenAssetIds(managedObjectContext: NSManagedObjectContext) -> Set<String> {
        return retrieveAssetIds(managedObjectContext: managedObjectContext, predicate: NSPredicate(format: "isHidden == TRUE"))
    }
    
    func retrieveLastScreenshotAssetId(managedObjectContext: NSManagedObjectContext) -> String? {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest<NSFetchRequestResult>(entityName: "Screenshot")
        fetchRequest.predicate = NSPredicate(format: "isRecognized == TRUE AND isFromShare == FALSE AND isHidden == TRUE") // match uploadScreenshotWithClarifai
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
    
    func saveMatchstick(managedObjectContext: NSManagedObjectContext,
                        remoteId: String,
                        imageUrl: String,
                        syteJson: String) -> Matchstick {
        let matchstickToSave = Matchstick(context: managedObjectContext)
        matchstickToSave.remoteId = remoteId
        matchstickToSave.imageUrl = imageUrl
        matchstickToSave.syteJson = syteJson
        matchstickToSave.receivedAt = NSDate()
        return matchstickToSave
    }

    func addImageDataToMatchstick(managedObjectContext: NSManagedObjectContext, imageUrl: String, imageData: Data) {
        let fetchRequest: NSFetchRequest<Matchstick> = Matchstick.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "imageUrl == %@", imageUrl)
        fetchRequest.sortDescriptors = nil
        
        do {
            let results = try managedObjectContext.fetch(fetchRequest)
            for matchstick in results {
                matchstick.imageData = imageData as NSData
                matchstick.receivedAt = NSDate()
            }
            try managedObjectContext.save()
        } catch {
            print("addImageDataToMatchstick imageUrl:\(imageUrl) results with error:\(error)")
        }
    }

    func retrieveMatchstickImageUrlsWithNoData(managedObjectContext: NSManagedObjectContext) -> [String] {
        let fetchRequest: NSFetchRequest<Matchstick> = Matchstick.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "imageData == nil")
        fetchRequest.sortDescriptors = nil
        
        do {
            let results = try managedObjectContext.fetch(fetchRequest)
            if let imageUrls = results.flatMap({$0.imageUrl}).flatMap({$0.copy()}) as? [String] {
                return imageUrls
            }
        } catch {
            print("retrieveMatchstickImageUrlsWithNoData results with error:\(error)")
        }
        return []
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
                var screenshotsToUpdate = Set<Screenshot>()
                let results = try managedObjectContext.fetch(fetchRequest)
                for product in results {
                    if let screenshot = product.screenshot {
                        screenshot.removeFromFavorites(product)
                        screenshot.favoritesCount -= 1
                        if let screenshotFavoritedDate = screenshot.lastFavorited,
                          let productFavoritedDate = product.dateFavorited,
                          (screenshotFavoritedDate as Date) <= (productFavoritedDate as Date) {
                            screenshotsToUpdate.insert(screenshot)
                        }
                    }
                    product.isFavorite = false
                    product.dateFavorited = nil
                }
                screenshotsToUpdate.forEach {$0.updateLastFavorited()}
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
    
    func countMatchsticks(managedObjectContext: NSManagedObjectContext) -> Int {
        let fetchRequest: NSFetchRequest<Matchstick> = Matchstick.fetchRequest()
        fetchRequest.predicate = nil
        fetchRequest.resultType = .countResultType
        fetchRequest.includesSubentities = false
        
        var count: Int = 0
        do {
            count = try managedObjectContext.count(for: fetchRequest)
        } catch {
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
    
    public func pinMain() {
        guard !isMainPinned else {
            return
        }
        do {
            try mainMoc().setQueryGenerationFrom(NSQueryGenerationToken.current)
            isMainPinned = true
        } catch {
            print("pinMain results with error:\(error)")
        }
    }
    
    public func unpinMain() {
        guard isMainPinned else {
            return
        }
        do {
            try mainMoc().setQueryGenerationFrom(nil)
            isMainPinned = false
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

// MARK: DB Migration

    func postDbMigration(from: Int, to: Int, container: NSPersistentContainer) {
        let installDate = UserDefaults.standard.object(forKey: UserDefaultsKeys.dateInstalled) as? NSDate
        if (from < 9 && to >= 7 && installDate != nil) { // Originally was from < 7, but a bug fixed in 9 should re-run for 7 or 8.
            dbQ.async {
                let managedObjectContext = container.newBackgroundContext()
                self.initializeFavoritesCounts(managedObjectContext: managedObjectContext)
            }
        }
        if from < 8 && to >= 8 && installDate != nil {
            dbQ.async {
                let managedObjectContext = container.newBackgroundContext()
                self.initializeFavoritesSets(managedObjectContext: managedObjectContext)
                self.cleanDeletedScreenshots(managedObjectContext: managedObjectContext)
                self.fixProductFiltersNoClassification(managedObjectContext: managedObjectContext)
                self.fixProductsNoClassification(managedObjectContext: managedObjectContext)
            }
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
                  let lastFavorited = dict["max"] as? NSDate,
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
            print("fixProductsNoClassification results with error:\(error)")
        }
    }
    
}

extension Screenshot {
    
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
    
    @objc public func setHide() {
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
    
    @objc func shoppablesBoundingFrame(in size: CGSize) -> CGRect {
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

    // Typically called after unfavoriting a product, its screenshot's lastFavorited needs to be set to the most recently favorited,
    // so the favoriteFrc correctly orders the screenshots.
    func updateLastFavorited() {
        if let favoritesArray = favorites?.allObjects as? [Product] {
            let latest = favoritesArray.flatMap({$0.dateFavorited as Date?}).reduce(Date.distantPast, { $0 > $1 ? $0 : $1 })
            lastFavorited = (latest == Date.distantPast ? nil : latest as NSDate)
        } else {
            lastFavorited = nil
        }
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
        productFilterToSave.productCount = 0
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
    @objc func set(productsOptions: ProductsOptions, callback: @escaping () -> Void) {
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
                        matchingFilter.dateSet = NSDate()
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
                NetworkingPromise.feedbackToSyte(isPositive: positive, imageUrl: imageUrl, offersUrl: augmentedOffersUrl, b0x: b0x, b0y: b0y, b1x: b1x, b1y: b1y)
                if positive {
                    AnalyticsTrackers.standard.track("Shoppable rating positive", properties: ["Rating" : positiveRating, "Screenshot" : imageUrl ?? "-", "Category" : category ?? "-", "AugmentedOffersUrl" : augmentedOffersUrl ?? "-"])
                } else {
                    AnalyticsTrackers.standard.track("Shoppable rating negative", properties: ["Rating" : negativeRating, "Screenshot" : imageUrl ?? "-", "Category" : category ?? "-", "AugmentedOffersUrl" : augmentedOffersUrl ?? "-"])
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
                    if toFavorited {
                        let now = NSDate()
                        product.dateFavorited = now
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
                        let dateFavorited = product.dateFavorited
                        product.dateFavorited = nil
                        if let screenshot = product.shoppable?.screenshot {
                            screenshot.removeFromFavorites(product)
                            if let favorites = screenshot.favorites {
                                screenshot.favoritesCount = Int16(favorites.count)
                                if let dateFavorited = dateFavorited,
                                    let screenshotLastFavorited = screenshot.lastFavorited,
                                    dateFavorited.compare(screenshotLastFavorited as Date) == .orderedAscending {
                                    // No need to update the screenshot's lastFavorited.
                                } else {
                                    screenshot.updateLastFavorited()
                                }
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

extension Matchstick {

    @objc public func add(callback: ((_ screenshot: Screenshot) -> Void)? = nil) {
        let managedObjectID = self.objectID
        let dataModel = DataModel.sharedInstance
        dataModel.performBackgroundTask { (managedObjectContext) in
            do {
                if let matchstick = managedObjectContext.object(with: managedObjectID) as? Matchstick,
                  let assetId = matchstick.remoteId,
                  let uploadedImageURL = matchstick.imageUrl,
                  let syteJson = matchstick.syteJson,
                  let segments = NetworkingPromise.jsonDestringify(string: syteJson) {
                    let addedScreenshot = dataModel.saveScreenshot(managedObjectContext: managedObjectContext,
                                                                   assetId: assetId,
                                                                   createdAt: Date(),
                                                                   isRecognized: true,
                                                                   isFromShare: true,
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
                print("matchstick add managedObjectID:\(managedObjectID) results with error:\(error)")
            }
        }
    }
    
    @objc public func pass() {
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
                print("matchstick pass managedObjectID:\(managedObjectID) results with error:\(error)")
            }
        }
    }
    
}

extension NSFetchedResultsController {
    var fetchedObjectsCount:Int {
        get {
            return sections?.reduce(0, {$0 + $1.numberOfObjects}) ?? 0
        }
    }
}
