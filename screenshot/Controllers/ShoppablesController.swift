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
    func frc(_ frc:NSFetchedResultsController<NSFetchRequestResult>, oneAddedAt indexPath: IndexPath) {
        collectionView?.insertItems(at: [indexPath])
    }
    
    func frc(_ frc:NSFetchedResultsController<NSFetchRequestResult>, oneDeletedAt indexPath: IndexPath) {
        collectionView?.deleteItems(at: [indexPath])
    }
    
    func frc(_ frc:NSFetchedResultsController<NSFetchRequestResult>, oneUpdatedAt indexPath: IndexPath) {
        collectionView?.reloadItems(at: [indexPath])
    }
    
    func frcReloadData(_ frc:NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView?.reloadData()
    }
}

@objc protocol ShoppablesControllerProtocol {
    var shoppablesController: ShoppablesController! { get set }
}
