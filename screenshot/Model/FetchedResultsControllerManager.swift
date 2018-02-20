//
//  FetchedResultsControllerManager.swift
//  coreDataNeverCrash
//
//  Created by Jonathan Rose on 2/17/18.
//  Copyright © 2018 Jonathan Rose. All rights reserved.
//

import UIKit
import CoreData


class FetchedResultsControllerManagerChange: NSObject {
    var insertedSections:IndexSet = []
    var deletedSections:IndexSet = []
    var insertedRows:[IndexPath] = []
    var deletedRows:[IndexPath] = []
    var updatedRows:[IndexPath] = []
    
    var insertedObjectId:[NSManagedObjectID] = []
    var deletedObjectId:[NSManagedObjectID] = []
    var updatedObjectId:[NSManagedObjectID] = []
    
    func applyChanges(tableView:UITableView){
        if #available(iOS 11.0, *) {
            tableView.performBatchUpdates({
                tableView.deleteSections(deletedSections, with: .none)
                tableView.deleteRows(at: deletedRows, with: .none)
                tableView.insertSections(insertedSections, with: .none)
                tableView.insertRows(at: insertedRows, with: .none)
            }) { (completed) in
                
            }
            tableView.reloadRows( at: updatedRows, with: .none)
        }else{
            tableView.beginUpdates()
            tableView.deleteSections(deletedSections, with: .none)
            tableView.deleteRows(at: deletedRows, with: .none)
            tableView.insertSections(insertedSections, with: .none)
            tableView.insertRows(at: insertedRows, with: .none)
            tableView.endUpdates()
            tableView.reloadRows( at: updatedRows, with: .none)
        }
    }
    
    func applyChanges(collectionView:UICollectionView){
        collectionView.performBatchUpdates({
            collectionView.deleteSections(deletedSections)
            collectionView.deleteItems(at: deletedRows)
            collectionView.insertSections(insertedSections)
            collectionView.insertItems(at: insertedRows)
        }) { (completed) in
        }
        collectionView.reloadItems(at: self.updatedRows)

    }
    
    func shiftIndexSections(by :Int){
        insertedSections = IndexSet(insertedSections.map { $0 + by })
        deletedSections = IndexSet(deletedSections.map { $0 + by })
        insertedRows = insertedRows.map { IndexPath.init(row: $0.row, section: ($0.section + by) ) }
        deletedRows = deletedRows.map { IndexPath.init(row: $0.row, section: ($0.section + by) ) }
        updatedRows = updatedRows.map { IndexPath.init(row: $0.row, section: ($0.section + by) ) }
    }
}

protocol FetchedResultsControllerManagerDelegate : NSObjectProtocol{
    func managerDidChangeContent(_ controller:NSObject, change:FetchedResultsControllerManagerChange)
}

class FetchedResultsControllerManager<ResultType> : NSObject, NSFetchedResultsControllerDelegate  where ResultType : NSFetchRequestResult {

    var fetchedResultsController:NSFetchedResultsController<ResultType>
    private var currentChange:FetchedResultsControllerManagerChange?
    weak var delegate:FetchedResultsControllerManagerDelegate?
    
    public init(fetchRequest: NSFetchRequest<ResultType>, managedObjectContext context: NSManagedObjectContext, sectionNameKeyPath: String?, delegate:FetchedResultsControllerManagerDelegate?){
        fetchedResultsController = NSFetchedResultsController.init(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: sectionNameKeyPath, cacheName: nil)

        super.init()
        
        fetchedResultsController.delegate = self
        self.delegate = delegate
        do {
            try self.fetchedResultsController.performFetch()
        }catch{
            print("Failed to fetch in fetchedResultsControllerManager from core data:\(error)")
        }
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.currentChange = FetchedResultsControllerManagerChange.init()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            self.currentChange?.insertedSections.insert(sectionIndex)
        case .delete:
            self.currentChange?.deletedSections.insert(sectionIndex)
        default:
            //shouldn't happen
            return
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let i = newIndexPath {
                self.currentChange?.insertedRows.append(i)
                if let obj = anObject as? NSManagedObject {
                    self.currentChange?.insertedObjectId.append(obj.objectID)
                }
            }
        case .delete:
            if let i = indexPath {
                self.currentChange?.deletedRows.append(i)
                if let obj = anObject as? NSManagedObject {
                    self.currentChange?.deletedObjectId.append(obj.objectID)
                }
            }
        case .update:
            if let i = newIndexPath {
                self.currentChange?.updatedRows.append(i)
                if let obj = anObject as? NSManagedObject {
                    self.currentChange?.updatedObjectId.append(obj.objectID)
                }
            }
            
        case .move:
            if let i = indexPath {
                self.currentChange?.deletedRows.append(i)
                if let obj = anObject as? NSManagedObject {
                    self.currentChange?.deletedObjectId.append(obj.objectID)
                }
            }
            if let i = newIndexPath {
                self.currentChange?.insertedRows.append(i)
                if let obj = anObject as? NSManagedObject {
                    self.currentChange?.insertedObjectId.append(obj.objectID)
                }
            }
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.currentChange?.insertedRows.sort(by:  { $0 < $1 } )
        self.currentChange?.deletedRows.sort(by:  { $0 > $1 } )
        if let change = self.currentChange {
            self.delegate?.managerDidChangeContent(self, change: change)
        }
        self.currentChange = nil
    }
}
