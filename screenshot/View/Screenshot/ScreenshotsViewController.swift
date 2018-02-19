//
//  ScreenshotsViewController.swift
//  screenshot
//
//  Created by Jonathan Rose on 2/18/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import CoreData

//FRC stuff
extension ScreenshotsViewController : FetchedResultsControllerManagerDelegate {
    func managerDidChangeContent(_ controller: NSObject, change: FetchedResultsControllerManagerChange) {
        change.shifIndexSections(by: 1)
        change.applyChanges(collectionView: self.collectionView)
        self.syncHelperViewVisibility()

    }
    
    @objc func setupFetchedResultsController(){
        self.screenshotFrcManager = DataModel.sharedInstance.screenshotFrc(delegate: self)
        
    }
    @objc func screenshotFrc() -> NSFetchedResultsController<Screenshot>? {
        return (self.screenshotFrcManager as? FetchedResultsControllerManager<Screenshot>)?.fetchedResultsController
        
    }
}
