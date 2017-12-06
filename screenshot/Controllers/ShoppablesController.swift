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
    func shoppablesControllerDidReload(_ controller: ShoppablesController)
}

@objc protocol ShoppablesControllerProtocol {
    var shoppablesController: ShoppablesController! { set get }
}

class ShoppablesController: NSObject, FrcDelegateProtocol {
    var collectionView: UICollectionView?
    weak var delegate: ShoppablesControllerDelegate?
    
    fileprivate var shoppablesFrc: ShoppableFrc!
    fileprivate var hasShoppablesFrc: NSFetchedResultsController<Screenshot>!
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
    
    func refetchShoppables() {
        AssetSyncModel.sharedInstance.refetchShoppables(screenshot: screenshot)
    }
    
    func shoppableCount() -> Int {
        return shoppablesFrc.fetchedObjects!.count
    }
    
    func shoppables() -> [Shoppable] {
        return shoppablesFrc.fetchedObjects!
    }
    
    func shoppable(at index: Int) -> Shoppable {
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
            preserveSelectedItem {
                collectionView?.reloadItems(at: [indexPath])
            }
            
            delegate?.shoppablesControllerDidReload(self)
            
        } else if frc == hasShoppablesFrc {
            let screenshot = hasShoppablesFrc.object(at: indexPath)
            
            if screenshot.shoppablesCount == -1 {
                delegate?.shoppablesControllerIsEmpty(self)
            }
        }
    }
    
    func frcReloadData(_ frc:NSFetchedResultsController<NSFetchRequestResult>) {
        if frc == shoppablesFrc {
            preserveSelectedItem {
                collectionView?.reloadData()
            }
            
            delegate?.shoppablesControllerDidReload(self)
        }
    }
    
    private func preserveSelectedItem(reload: () -> ()) {
        let shoppablesCount = collectionView?.numberOfItems(inSection: 0)
        let selectedIndexPath = collectionView?.indexPathsForSelectedItems?.first
        
        reload()
        
        if collectionView?.numberOfItems(inSection: 0) == shoppablesCount {
            collectionView?.selectItem(at: selectedIndexPath, animated: false, scrollPosition: .centeredHorizontally)
        }
    }
}
