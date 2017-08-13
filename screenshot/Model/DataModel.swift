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
        request.predicate = NSPredicate(format: "isFashion == TRUE")
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
        request.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        request.predicate = NSPredicate(format: "screenshot == %@", screenshot)
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
    
    fileprivate var shoppableFrc: NSFetchedResultsController<Shoppable>!
    fileprivate var shoppableChangeIndexPath: IndexPath?
    fileprivate var shoppableChangeKind: CZChangeKind = .none

}

extension DataModel: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        switch controller {
        case screenshotFrc:
            screenshotChangeKind = .none
            screenshotChangeIndexPath = nil
        case shoppableFrc:
            shoppableChangeKind = .none
            shoppableChangeIndexPath = nil
        default:
            print("Unknown controller:\(controller) in controllerWillChangeContent")
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch controller {
        case screenshotFrc:
            if screenshotChangeKind != .none || screenshotChangeIndexPath != nil {
                screenshotChangeKind = .multiple
            } else {
                switch type {
                case .insert:
                    screenshotChangeKind = .singleAdd
                    screenshotChangeIndexPath = newIndexPath
                case .delete:
                    screenshotChangeKind = .singleDelete
                    screenshotChangeIndexPath = indexPath
                default:
                    screenshotChangeKind = .multiple
                }
            }
        case shoppableFrc:
            if shoppableChangeKind != .none || shoppableChangeIndexPath != nil {
                shoppableChangeKind = .multiple
            } else {
                switch type {
                case .insert:
                    shoppableChangeKind = .singleAdd
                    shoppableChangeIndexPath = newIndexPath
                case .delete:
                    shoppableChangeKind = .singleDelete
                    shoppableChangeIndexPath = indexPath
                default:
                    shoppableChangeKind = .multiple
                }
            }
        default:
            print("Unknown controller:\(controller) in controller didChange")
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        switch controller {
        case screenshotFrc:
            switch screenshotChangeKind {
            case .none:
                print("DataModel screenshot no change. Weird")
            case .singleAdd:
                if let screenshotChangeIndexPath = screenshotChangeIndexPath {
                    screenshotFrcDelegate?.frcOneAddedAt(indexPath: screenshotChangeIndexPath)
                } else {
                    print("Error DataModel singleAdd screenshotChangeIndexPath nil")
                    screenshotFrcDelegate?.frcReloadData()
                }
            case .singleDelete:
                if let screenshotChangeIndexPath = screenshotChangeIndexPath {
                    screenshotFrcDelegate?.frcOneDeletedAt(indexPath: screenshotChangeIndexPath)
                } else {
                    print("Error DataModel singleDelete screenshotChangeIndexPath nil")
                    screenshotFrcDelegate?.frcReloadData()
                }
            case .multiple:
                screenshotFrcDelegate?.frcReloadData()
            }
            screenshotChangeKind = .none
            screenshotChangeIndexPath = nil
        case shoppableFrc:
            switch shoppableChangeKind {
            case .none:
                print("DataModel shoppable no change. Weird")
            case .singleAdd:
                if let shoppableChangeIndexPath = shoppableChangeIndexPath {
                    shoppableFrcDelegate?.frcOneAddedAt(indexPath: shoppableChangeIndexPath)
                } else {
                    print("Error DataModel singleAdd shoppableChangeIndexPath nil")
                    shoppableFrcDelegate?.frcReloadData()
                }
            case .singleDelete:
                if let shoppableChangeIndexPath = shoppableChangeIndexPath {
                    shoppableFrcDelegate?.frcOneDeletedAt(indexPath: shoppableChangeIndexPath)
                } else {
                    print("Error DataModel singleDelete shoppableChangeIndexPath nil")
                    shoppableFrcDelegate?.frcReloadData()
                }
            case .multiple:
                shoppableFrcDelegate?.frcReloadData()
            }
            shoppableChangeKind = .none
            shoppableChangeIndexPath = nil
        default:
            print("Unknown controller:\(controller) in controllerDidChangeContent")
        }
    }
    
}

extension DataModel {
    
    // Save a new Screenshot to Core Data.
    func saveScreenshot(assetId: String) -> Screenshot {
        let managedObjectContext = mainMoc()
        let entityDescription = NSEntityDescription.entity(forEntityName: "Screenshot", in: managedObjectContext)
        let screenshotToSave = Screenshot(entity: entityDescription!, insertInto: managedObjectContext)
        screenshotToSave.assetId = assetId
        screenshotToSave.createdAt = NSDate()
        do {
            try managedObjectContext.save()
        } catch {
            print("Failed to saveScreenshot")
        }
        return screenshotToSave
    }
    
    func lastSavedScreenshotMain() -> Screenshot? {
        return lastSavedScreenshot(managedObjectContext: mainMoc())
    }
    
    func lastSavedScreenshotBackground() -> Screenshot? {
        return lastSavedScreenshot(managedObjectContext: adHocMoc())
    }
    
    func lastSavedScreenshot(managedObjectContext: NSManagedObjectContext) -> Screenshot? {
        return screenshot(predicate: nil, managedObjectContext: managedObjectContext)
    }
    
    func screenshot(assetId: String, managedObjectContext: NSManagedObjectContext) -> Screenshot? {
        return screenshot(predicate: NSPredicate(format: "assetId == %@", assetId), managedObjectContext: managedObjectContext)
    }
    
    fileprivate func screenshot(predicate: NSPredicate?, managedObjectContext: NSManagedObjectContext) -> Screenshot? {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest<NSFetchRequestResult>(entityName: "Screenshot")
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        fetchRequest.fetchBatchSize = 1
        do {
            let results = try managedObjectContext.fetch(fetchRequest)
            if let lastSavedScreenshot = results.first as? Screenshot {
                return lastSavedScreenshot
            }
        } catch {
            print("lastSavedScreenshot results with error:\(error)")
        }
        return nil
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

extension Shoppable {
    
    @objc public func frame(size: CGSize) -> CGRect {
        let viewWidth = Double(size.width)
        let viewHeight = Double(size.height)
        let frame = CGRect(x: b0x * viewWidth, y: b0y * viewHeight, width: (b1x - b0x) * viewWidth, height: (b1y - b0y) * viewHeight)
        print("frame:\(NSStringFromCGRect(frame))")
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
