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
    func frcOneAddedAt(indexPath: IndexPath)
    func frcOneDeletedAt(indexPath: IndexPath)
    func frcOneUpdatedAt(indexPath: IndexPath)
    func frcReloadData()
}

enum CZChangeKind {
    case none, singleAdd, singleDelete, singleUpdate, multiple
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
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        request.predicate = NSPredicate(format: "isFashion == TRUE AND isHidden == FALSE AND shoppablesCount > 0")
        request.fetchLimit = 100
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
    
    
    public func setupShoppableFrc(screenshot: Screenshot) -> NSFetchedResultsController<Shoppable> {
        let request: NSFetchRequest<Shoppable> = Shoppable.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true), NSSortDescriptor(key: "offersURL", ascending: true)]
        request.predicate = NSPredicate(format: "screenshot == %@ AND productCount > 0", screenshot)
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.mainMoc(), sectionNameKeyPath: nil, cacheName: nil)
        shoppableFrc = fetchedResultsController
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Failed to fetch shoppables from core data:\(error)")
        }
        return fetchedResultsController
    }
    
    public func clearShoppableFrc() {
        shoppableFrc = nil
    }
    
    weak open var shoppableFrcDelegate: FrcDelegateProtocol?
    
    fileprivate var shoppableFrc: NSFetchedResultsController<Shoppable>?
    fileprivate var shoppableChangeIndexPath: IndexPath?
    fileprivate var shoppableChangeKind: CZChangeKind = .none

    
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
        switch controller {
        case screenshotFrc:
            screenshotChangeKind = .none
            screenshotChangeIndexPath = nil
        case shoppableFrcStandIn:
            shoppableChangeKind = .none
            shoppableChangeIndexPath = nil
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
        switch controller {
        case screenshotFrc:
            didChange(changeKind: &screenshotChangeKind, changeIndexPath: &screenshotChangeIndexPath, type: type, indexPath: indexPath, newIndexPath: newIndexPath)
        case shoppableFrcStandIn:
            didChange(changeKind: &shoppableChangeKind, changeIndexPath: &shoppableChangeIndexPath, type: type, indexPath: indexPath, newIndexPath: newIndexPath)
        case favoriteFrc:
            didChange(changeKind: &favoriteChangeKind, changeIndexPath: &favoriteChangeIndexPath, type: type, indexPath: indexPath, newIndexPath: newIndexPath)
        default:
            print("Unknown controller:\(controller) in controller didChange")
        }
    }
    
    func didChangeContent(changeKind: inout CZChangeKind, changeIndexPath: inout IndexPath?, frcDelegate: FrcDelegateProtocol?) {
        switch changeKind {
        case .none:
            print("DataModel didChangeContent no change. Weird")
        case .singleAdd:
            if let changeIndexPath = changeIndexPath {
                frcDelegate?.frcOneAddedAt(indexPath: changeIndexPath)
            } else {
                print("Error DataModel singleAdd changeIndexPath nil")
                frcDelegate?.frcReloadData()
            }
        case .singleDelete:
            if let changeIndexPath = changeIndexPath {
                frcDelegate?.frcOneDeletedAt(indexPath: changeIndexPath)
            } else {
                print("Error DataModel singleDelete changeIndexPath nil")
                frcDelegate?.frcReloadData()
            }
        case .singleUpdate:
            if let changeIndexPath = changeIndexPath {
                frcDelegate?.frcOneUpdatedAt(indexPath: changeIndexPath)
            } else {
                print("Error DataModel singleAdd changeIndexPath nil")
                frcDelegate?.frcReloadData()
            }
        case .multiple:
            frcDelegate?.frcReloadData()
        }
        changeKind = .none
        changeIndexPath = nil
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        let shoppableFrcStandIn = shoppableFrc == nil ? NSFetchedResultsController() : shoppableFrc!
        switch controller {
        case screenshotFrc:
            didChangeContent(changeKind: &screenshotChangeKind, changeIndexPath: &screenshotChangeIndexPath, frcDelegate: screenshotFrcDelegate)
        case shoppableFrcStandIn:
            didChangeContent(changeKind: &shoppableChangeKind, changeIndexPath: &shoppableChangeIndexPath, frcDelegate: shoppableFrcDelegate)
        case favoriteFrc:
            didChangeContent(changeKind: &favoriteChangeKind, changeIndexPath: &favoriteChangeIndexPath, frcDelegate: favoriteFrcDelegate)
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
                        imageData: Data?) -> Screenshot {
        let screenshotToSave = Screenshot(context: managedObjectContext)
        screenshotToSave.assetId = assetId
        if let nsDate = createdAt as NSDate? {
            screenshotToSave.createdAt = nsDate
        }
        screenshotToSave.isFashion = isFashion
        screenshotToSave.isFromShare = isFromShare
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
        
        var allAssetIdsSet = Set<String>()
        do {
            guard let results = try managedObjectContext.fetch(fetchRequest) as? [[String : String]] else {
                print("retrieveAssetIds failed to fetch dictionaries")
                return allAssetIdsSet
            }
            for result in results {
                if let assetId = result["assetId"] {
                    allAssetIdsSet.insert(assetId)
                }
            }
        } catch {
            print("retrieveAllAssetIds results with error:\(error)")
        }
        return allAssetIdsSet
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
                       b1y: Double) -> Shoppable {
        let shoppableToSave = Shoppable(context: managedObjectContext)
        shoppableToSave.screenshot = screenshot
        let spellingMap = ["Neclesses" : "Necklaces", "Cufflings" : "Cufflinks"]
        if let label = label, let correctedSpelling = spellingMap[label] {
            shoppableToSave.label = correctedSpelling
        } else {
            shoppableToSave.label = label
        }
        let priorityMap = ["Jackets" : "00", "Skirts" : "01", "Shoes" : "02", "Bags" : "03"]
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
        return shoppableToSave
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
                     merchant: String?) -> Product {
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
    
    // Update changes made in the background
    public func saveMain() {
        saveMoc(managedObjectContext: mainMoc())
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
                    screenshot.syteJson = nil
                    screenshot.uploadedImageURL = nil
                    screenshot.shareLink = nil
                    if let shoppables = screenshot.shoppables as? Set<Shoppable> {
                        for shoppable in shoppables {
                            managedObjectContext.delete(shoppable)
                        }
                    }
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
            } catch {
                print("setFavorited objectID:\(managedObjectID) results with error:\(error)")
            }
        }
    }
    
}
