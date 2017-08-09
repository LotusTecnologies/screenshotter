//
//  DataModel.swift
//  screenshot
//
//  Created by Gershon Kagan on 8/9/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit
import CoreData

public protocol FrcDelegateProtocol : class {
    func oneAddedAt(indexPath: IndexPath)
    func oneDeletedAt(indexPath: IndexPath)
    func reloadData()
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
    
    func adHocMoc() -> NSManagedObjectContext {
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
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
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
                    screenshotFrcDelegate?.oneAddedAt(indexPath: screenshotChangeIndexPath)
                } else {
                    print("Error DataModel singleAdd screenshotChangeIndexPath nil")
                    screenshotFrcDelegate?.reloadData()
                }
            case .singleDelete:
                if let screenshotChangeIndexPath = screenshotChangeIndexPath {
                    screenshotFrcDelegate?.oneDeletedAt(indexPath: screenshotChangeIndexPath)
                } else {
                    print("Error DataModel singleDelete screenshotChangeIndexPath nil")
                    screenshotFrcDelegate?.reloadData()
                }
            case .multiple:
                screenshotFrcDelegate?.reloadData()
            }
            screenshotChangeKind = .none
            screenshotChangeIndexPath = nil
        case shoppableFrc:
            switch shoppableChangeKind {
            case .none:
                print("DataModel shoppable no change. Weird")
            case .singleAdd:
                if let shoppableChangeIndexPath = shoppableChangeIndexPath {
                    shoppableFrcDelegate?.oneAddedAt(indexPath: shoppableChangeIndexPath)
                } else {
                    print("Error DataModel singleAdd shoppableChangeIndexPath nil")
                    shoppableFrcDelegate?.reloadData()
                }
            case .singleDelete:
                if let shoppableChangeIndexPath = shoppableChangeIndexPath {
                    shoppableFrcDelegate?.oneDeletedAt(indexPath: shoppableChangeIndexPath)
                } else {
                    print("Error DataModel singleDelete shoppableChangeIndexPath nil")
                    shoppableFrcDelegate?.reloadData()
                }
            case .multiple:
                shoppableFrcDelegate?.reloadData()
            }
            shoppableChangeKind = .none
            shoppableChangeIndexPath = nil
        default:
            print("Unknown controller:\(controller) in controllerDidChangeContent")
        }
    }
    
}
