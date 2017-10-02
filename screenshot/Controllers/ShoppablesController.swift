//
//  ShoppablesController.swift
//  screenshot
//
//  Created by Corey Werner on 9/10/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit
import CoreData

@objc protocol ShoppablesControllerDelegate {
    func shoppablesControllerIsEmpty(_ controller: ShoppablesController)
}

class ShoppablesController: NSObject, FrcDelegateProtocol {
    fileprivate var shoppablesFrc: ShoppableFrc!
    fileprivate var hasShoppablesFrc: NSFetchedResultsController<Screenshot>!
    public var collectionView: UICollectionView?
    public var delegate: ShoppablesControllerDelegate?
    
    init(screenshot: Screenshot) {
        super.init()
        
        DataModel.sharedInstance.shoppableFrcDelegate = self
        shoppablesFrc = DataModel.sharedInstance.setupShoppableFrc(screenshot: screenshot)
        hasShoppablesFrc = shoppablesFrc.hasShoppablesFrc
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
        if frc == shoppablesFrc {
            collectionView?.insertItems(at: [indexPath])
        }
    }
    
    func frc(_ frc:NSFetchedResultsController<NSFetchRequestResult>, oneDeletedAt indexPath: IndexPath) {
        if frc == shoppablesFrc {
            collectionView?.deleteItems(at: [indexPath])
        }
    }
    
    func frc(_ frc:NSFetchedResultsController<NSFetchRequestResult>, oneUpdatedAt indexPath: IndexPath) {
        if frc == shoppablesFrc {
            collectionView?.reloadItems(at: [indexPath])
            
        } else if frc == hasShoppablesFrc {
            let screenshot = hasShoppablesFrc.object(at: indexPath)
            
            if screenshot.shoppablesCount == -1 {
                delegate?.shoppablesControllerIsEmpty(self)
            }
        }
    }
    
    func frcReloadData(_ frc:NSFetchedResultsController<NSFetchRequestResult>) {
        if frc == shoppablesFrc {
            collectionView?.reloadData()
        }
    }
}

@objc protocol ShoppablesControllerProtocol {
    var shoppablesController: ShoppablesController! { get set }
}
