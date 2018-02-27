//
//  FetchedResultsControllerManager.swift
//  coreDataNeverCrash
//
//  Created by Jonathan Rose on 2/17/18.
//  Copyright © 2018 Jonathan Rose. All rights reserved.
//

import UIKit
import CoreData

extension IndexSet {
    func toArray() -> [Int] {
        var indexes:[Int] = [];
        self.enumerated().forEach({ arg in
            let (_, element) = arg
            indexes.append(element);
        })
        return indexes;
    }
}

protocol FetchedResultsControllerManagerChange {
    func applyChanges(tableView:UITableView);
    func applyChanges(collectionView:UICollectionView);
    func shiftIndexSections(by :Int);
    var insertedRows:[IndexPath] { get }
    var deletedRows:[IndexPath] { get }
    var updatedRows:[IndexPath] { get }
    var insertedSections:IndexSet { get }
    var deletedSections:IndexSet { get }

}

protocol FetchedResultsControllerManagerDelegate : class {
    func managerDidChangeContent(_ controller:NSObject, change:FetchedResultsControllerManagerChange)
}

class FetchedResultsControllerManager<ResultType> : NSObject, NSFetchedResultsControllerDelegate  where ResultType : NSFetchRequestResult {
    class Section {
        var items:[ResultType] = []
        init(_ i:[ResultType]) {
            items = i
        }
    }
    class Change: NSObject, FetchedResultsControllerManagerChange {
        var insertedSections:IndexSet = []
        var deletedSections:IndexSet = []
        var insertedRows:[IndexPath] {
            return insertedElements.map{ $0.index }
        }
        var deletedRows:[IndexPath]{
            return deletedElements.map{ $0.index }
        }
        var updatedRows:[IndexPath] {
            return updatedElements.map{ $0.index }
        }
        
        var insertedElements:[(index:IndexPath, element:ResultType)] = []
        var deletedElements:[(index:IndexPath, element:ResultType)] = []
        var updatedElements:[(index:IndexPath, element:ResultType)] = []
        
        
        func applyChanges(tableView:UITableView){
            tableView.beginUpdates()
            tableView.deleteRows(at: deletedRows, with: .none)
            tableView.deleteSections(deletedSections, with: .none)
            tableView.insertSections(insertedSections, with: .none)
            tableView.insertRows(at: insertedRows, with: .none)
            tableView.endUpdates()
            
            tableView.reloadRows( at: updatedRows, with: .none)
            
        }
        
        func applyChanges(collectionView:UICollectionView){
            collectionView.performBatchUpdates({
                collectionView.deleteItems(at: deletedRows)
                collectionView.deleteSections(deletedSections)
                collectionView.insertSections(insertedSections)
                collectionView.insertItems(at: insertedRows)
            }) { (completed) in
            }
            collectionView.reloadItems(at: self.updatedRows)
            
            
        }
        override var description: String {
            return " insertedSections: \(insertedSections.toArray()), deletedSections::\(deletedSections.toArray()) , insertedRows:\(insertedRows), deletedRows:\(deletedRows), updatedRows:\(updatedRows)"
        }
        func shiftIndexSections(by :Int){
            insertedSections = IndexSet(insertedSections.map { $0 + by })
            deletedSections = IndexSet(deletedSections.map { $0 + by })
            insertedElements = insertedElements.map { (IndexPath.init(row: $0.row, section: ($0.section + by)), $1 ) }
            deletedElements = deletedElements.map { (IndexPath.init(row: $0.row, section: ($0.section + by)), $1 ) }
            updatedElements = updatedElements.map { (IndexPath.init(row: $0.row, section: ($0.section + by)), $1 ) }
        }
    }
    
    
    private var fetchedResultsController:NSFetchedResultsController<ResultType>
    private var currentChange:Change?
    weak var delegate:FetchedResultsControllerManagerDelegate?
    var arrayOfArrays:[Section] = []
    
    
    func numberOfSections() -> Int {
        return arrayOfArrays.count
    }
    var fetchedObjectsCount: Int {
        return self.arrayOfArrays.reduce(0, {$0 + $1.items.count})
    }
    var first: ResultType? {
        return self.arrayOfArrays.first?.items.first
    }
    
    var fetchedObjects:[ResultType] {
        
        var toReturn:[Any] = []
        for a in arrayOfArrays {
            toReturn.append(a.items)
        }
        return toReturn as? [ResultType] ?? []
    }
    
    func indexPath(forObject:ResultType) ->IndexPath?{
        for (section, sectionInfo) in arrayOfArrays.enumerated() {
            for (row, object) in sectionInfo.items.enumerated() {
                if forObject.isEqual(object) {
                    return IndexPath.init(row: row, section: section)
                }
            }

        }
        return nil
    }
    
    func numberOfItems(in section:Int) -> Int {
        return self.arrayOfArrays[section].items.count
    }
    func object(at indexPath:IndexPath) -> ResultType {
        return self.arrayOfArrays[indexPath.section].items[indexPath.row]
    }
    
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
        if let sections = self.fetchedResultsController.sections {
            for s in sections {
                if let objects = s.objects as? [ResultType] {
                    self.arrayOfArrays.append(Section( objects ))
                }
            }
        }
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.currentChange = Change.init()
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
        if let anObject = anObject as? ResultType {
            switch type {
            case .insert:
                if let i = newIndexPath {
                    self.currentChange?.insertedElements.append((i, anObject))
                }
            case .delete:
                if let i = indexPath {
                    self.currentChange?.deletedElements.append((i, anObject))
                }
            case .update:
                if let i = indexPath {
                    self.currentChange?.updatedElements.append((i, anObject))
                }
                
            case .move:
                if let i = indexPath {
                    self.currentChange?.deletedElements.append((i, anObject))
                }
                if let i = newIndexPath {
                    self.currentChange?.insertedElements.append((i, anObject))
                }
            }
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let change = self.currentChange else {
            return
        }
        change.insertedElements.sort(by:  { $0.index < $1.index } )
        change.deletedElements.sort(by:  { $0.index > $1.index } )
        
        change.updatedElements.forEach({ (tuple) in
            arrayOfArrays[tuple.index.section].items[tuple.index.row] = tuple.element
        })
        let updateOnlyChange = Change()
        updateOnlyChange.updatedElements = change.updatedElements
        if updateOnlyChange.updatedElements.count > 0 {
            self.delegate?.managerDidChangeContent(self, change:updateOnlyChange)
        }
        
        change.deletedRows.forEach({ (indexPath) in
            arrayOfArrays[indexPath.section].items.remove(at: indexPath.row)
        })
        change.deletedSections.reversed().forEach({ (index) in
            arrayOfArrays.remove(at: index)
        })
        change.insertedSections.forEach({ (index) in
            arrayOfArrays.insert(Section([]), at: index)
        })
        change.insertedElements.forEach({ (tuple) in
            arrayOfArrays[tuple.index.section].items.insert(tuple.element, at: tuple.index.row)
        })
        change.updatedElements = []
        if change.deletedRows.count + change.deletedSections.count + change.insertedSections.count + change.insertedElements.count > 0 {
            self.delegate?.managerDidChangeContent(self, change:change)
        }

        self.currentChange = nil
    }
}


