//
//  ShoppablesController.swift
//  screenshot
//
//  Created by Corey Werner on 9/10/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit
import CoreData

class ShoppablesController: NSObject, FrcDelegateProtocol {
    private var shoppablesFrc: NSFetchedResultsController<Shoppable>!
    public var collectionView: UICollectionView?
    
    init(screenshot: Screenshot) {
        super.init()
        
        DataModel.sharedInstance.shoppableFrcDelegate = self
        shoppablesFrc = DataModel.sharedInstance.setupShoppableFrc(screenshot: screenshot)
    }
    
    deinit {
        DataModel.sharedInstance.shoppableFrcDelegate = nil
        DataModel.sharedInstance.clearShoppableFrc();
    }
    
    public func shoppableCount() -> Int {
        return shoppablesFrc.fetchedObjects!.count
    }
    
    public func shoppables() -> [Shoppable] {
        return shoppablesFrc.fetchedObjects!
    }
    
    public func shoppable(at index: Int) -> Shoppable {
        return shoppablesFrc.object(at: IndexPath.init(row: index, section: 0))
    }
}

extension ShoppablesController {
    func frcOneAddedAt(indexPath: IndexPath) {
        collectionView?.insertItems(at: [indexPath])
    }
    
    func frcOneDeletedAt(indexPath: IndexPath) {
        collectionView?.deleteItems(at: [indexPath])
    }
    
    func frcOneUpdatedAt(indexPath: IndexPath) {
        collectionView?.reloadItems(at: [indexPath])
    }
    
    func frcReloadData() {
        collectionView?.reloadData()
    }
}
