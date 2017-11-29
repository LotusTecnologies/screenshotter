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

@objc protocol ShoppablesControllerProtocol {
    var shoppablesController: ShoppablesController! { get set }
}

class ShoppablesController: NSObject, FrcDelegateProtocol {
    fileprivate var shoppablesFrc: ShoppableFrc!
    fileprivate var hasShoppablesFrc: NSFetchedResultsController<Screenshot>!
    public var collectionView: UICollectionView?
    public var delegate: ShoppablesControllerDelegate?
    private var screenshot: Screenshot!
    
    init(screenshot: Screenshot) {
        super.init()
        
        self.screenshot = screenshot
        DataModel.sharedInstance.shoppableFrcDelegate = self
        
        shoppablesFrc = DataModel.sharedInstance.setupShoppableFrc(screenshot: screenshot)
        hasShoppablesFrc = shoppablesFrc.hasShoppablesFrc
    }
    
    deinit {
        DataModel.sharedInstance.shoppableFrcDelegate = nil
        DataModel.sharedInstance.clearShoppableFrc();
    }
    
    public func refetchShoppables() {
        AssetSyncModel.sharedInstance.refetchShoppables(screenshot: screenshot)
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
            let shoppablesCount = collectionView?.numberOfItems(inSection: 0)
            let selectedIndexPath = collectionView?.indexPathsForSelectedItems?.first
            
            collectionView?.reloadItems(at: [indexPath])
            
            if collectionView?.numberOfItems(inSection: 0) == shoppablesCount {
                collectionView?.selectItem(at: selectedIndexPath, animated: false, scrollPosition: .centeredHorizontally)
            }
            
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
