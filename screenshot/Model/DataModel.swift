//
//  DataModel.swift
//  screenshot
//
//  Created by Gershon Kagan on 8/9/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit
import CoreData

@objc public protocol FrcDelegateProtocol : class {
    func frcOneAddedAt(indexPath: IndexPath)
    func frcOneDeletedAt(indexPath: IndexPath)
    func frcReloadData()
}

enum CZChangeKind {
    case none, singleAdd, singleDelete, multiple
}


class DataModel: NSObject {
    
    public static let sharedInstance = DataModel()
    
    public static func docsDirURL() -> URL {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls.last! // If no documents dir, just crash.
    }
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Model")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                print("Unresolved error \(error), \(error.userInfo)")
            }
            container.viewContext.automaticallyMergesChangesFromParent = true
        })
        return container
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let modelURL = Bundle.main.url(forResource: "Model", withExtension: "momd")!
        let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)!
        
        let applicationDocumentsDirectory = DataModel.docsDirURL()
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        let url = applicationDocumentsDirectory.appendingPathComponent("CoreData.sqlite")
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        } catch {
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's core data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = "There was an error creating or loading the application's core data." as AnyObject?
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "CZ_ERROR_DOMAIN", code: 9999, userInfo: dict)
            print("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
        }
        
        return coordinator
    }()

    func mainMoc() -> NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    public func adHocMoc() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
    
    // MARK: - FRC

    public lazy var screenshotFrc: NSFetchedResultsController<Screenshot> = {
        let request: NSFetchRequest<Screenshot> = Screenshot.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        request.predicate = NSPredicate(format: "isFashion == TRUE AND isHidden == FALSE AND shoppablesCount > 0")
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
        request.sortDescriptors = [NSSortDescriptor(key: "order", ascending: false)]
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
            NSLog("controllerWillChangeContent screenshotFrc")
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
            NSLog("controller screenshotFrc didChange at indexPath:\(String(describing: indexPath))  type:\(type)  newIndexPath:\(String(describing: newIndexPath))")
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
            NSLog("screenshotFrc controllerDidChangeContent")
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
                        isFashion: Bool,
                        createdAt: Date?) -> Screenshot {
        let entityDescription = NSEntityDescription.entity(forEntityName: "Screenshot", in: managedObjectContext)
        let screenshotToSave = Screenshot(entity: entityDescription!, insertInto: managedObjectContext)
        screenshotToSave.assetId = assetId
        screenshotToSave.isFashion = isFashion
        if let nsDate = createdAt as NSDate? {
            screenshotToSave.createdAt = nsDate
        }
        do {
            try managedObjectContext.save()
        } catch {
            print("Failed to saveScreenshot")
        }
        return screenshotToSave
    }
    
    func retrieveAllAssetIds() -> Set<String> {
        return retrieveAssetIds(predicate: nil)
    }
    
    func retrieveCompleteAssetIds() -> Set<String> {
        return retrieveAssetIds(predicate: NSPredicate(format: "isFashion != nil"))
    }
    
    func retrieveAssetIds(predicate: NSPredicate?) -> Set<String> {
        let managedObjectContext = adHocMoc()
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest<NSFetchRequestResult>(entityName: "Screenshot")
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = nil //[NSSortDescriptor(key: "createdAt", ascending: false)]
        fetchRequest.includesSubentities = false
        fetchRequest.resultType = .dictionaryResultType
        fetchRequest.includesPendingChanges = false
        fetchRequest.propertiesToFetch = ["assetId"]
        fetchRequest.returnsDistinctResults = true
        fetchRequest.includesPropertyValues = true
        fetchRequest.shouldRefreshRefetchedObjects = true
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
    
    func deleteScreenshots(assetIds: Set<String>) {
        let managedObjectContext = adHocMoc()
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
                       order: Int16,
                       label: String?,
                       offersURL: String?,
                       b0x: Double,
                       b0y: Double,
                       b1x: Double,
                       b1y: Double) -> Shoppable {
        let entityDescription = NSEntityDescription.entity(forEntityName: "Shoppable", in: managedObjectContext)
        let shoppableToSave = Shoppable(entity: entityDescription!, insertInto: managedObjectContext)
        shoppableToSave.screenshot = screenshot
        shoppableToSave.order = order
        shoppableToSave.label = label
        shoppableToSave.offersURL = offersURL
        shoppableToSave.b0x = b0x
        shoppableToSave.b0y = b0y
        shoppableToSave.b1x = b1x
        shoppableToSave.b1y = b1y
        do {
            try managedObjectContext.save()
        } catch {
            print("Failed to saveShoppable order:\(order)")
        }
        return shoppableToSave
    }
    
    func delete(shoppable: Shoppable, managedObjectContext: NSManagedObjectContext) {
        let screenshot = shoppable.screenshot
        do {
            managedObjectContext.delete(shoppable)
            screenshot?.shoppablesCount -= 1
            try managedObjectContext.save()
        } catch {
            print("Failed to delete shoppable")
        }
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
        let entityDescription = NSEntityDescription.entity(forEntityName: "Product", in: managedObjectContext)
        let productToSave = Product(entity: entityDescription!, insertInto: managedObjectContext)
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
        do {
            try managedObjectContext.save()
        } catch {
            print("Failed to saveProduct order:\(order)")
        }
        return productToSave
    }
    
    public func unfavorite(favoriteArray: [Product]) {
        for favorite in favoriteArray {
            favorite.isFavorite = false
        }
        saveMain()
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
        self.isHidden = true
        DataModel.sharedInstance.saveMain()
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
        self.isFavorite = toFavorited
        self.dateFavorited = toFavorited ? NSDate() : nil
        DataModel.sharedInstance.saveMain()
    }
    
}
