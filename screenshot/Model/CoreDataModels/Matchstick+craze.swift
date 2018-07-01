//
//  Matchstick+craze.swift
//  screenshot
//
//  Created by Jonathan Rose on 6/3/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import Foundation
import CoreData

extension Matchstick {
    static func predicateForDisplayingMatchstick() -> NSPredicate {
        return NSPredicate.init(format: "isDisplaying == true")
    }
    static func predicateForQueuedMatchstick() -> NSPredicate {
        return NSCompoundPredicate.init(andPredicateWithSubpredicates: [
            NSPredicate.init(format: "dateSkipped == nil"),
            NSPredicate.init(format: "was404 == false"),
            NSPredicate.init(format: "wasAdded == false"),
            NSPredicate.init(format: "isDisplaying == false"),
            ])
    }

    static var skipRotationTime:TimeInterval = 7*24*60*60  // 1 week
    static var displayingSize = 3
    static var queueSize = 50
    
    var isInGarbage:Bool {
        if self.wasAdded || self.was404 {
            return true
        }else if let date = self.dateSkipped {
            if abs(date.timeIntervalSinceNow) < Matchstick.skipRotationTime {
                return true
            }
        }
        return false
    }
    
    
    public func add(callback: ((_ screenshot: Screenshot) -> Void)? = nil) {
        let managedObjectID = self.objectID
        let dataModel = DataModel.sharedInstance
        dataModel.performBackgroundTask { (managedObjectContext) in
            if let matchstick = managedObjectContext.object(with: managedObjectID) as? Matchstick,
                let assetId = matchstick.remoteId,
                let uploadedImageURL = matchstick.imageUrl {
                
                let addedScreenshot = dataModel.saveScreenshot(managedObjectContext: managedObjectContext,
                                                               assetId: assetId,
                                                               createdAt: Date(),
                                                               isRecognized: true,
                                                               source: .discover,
                                                               isHidden: false,
                                                               imageData: matchstick.imageData as Data?,
                                                               uploadedImageURL: uploadedImageURL,
                                                               syteJsonString: nil)
                addedScreenshot.trackingInfo = matchstick.trackingInfo
                if callback == nil {
                    managedObjectContext.delete(matchstick)
                }
                managedObjectContext.saveIfNeeded()
                Analytics.trackScreenshotCreated(screenshot: addedScreenshot)
                AssetSyncModel.sharedInstance.processingQ.async {
                    AssetSyncModel.sharedInstance.syteProcessing(imageData: nil, orImageUrlString: uploadedImageURL, assetId: assetId, optionsMask: ProductsOptionsMask.global)
                    
                }
                DispatchQueue.main.async {
                    AccumulatorModel.screenshotUninformed.incrementUninformedCount()
                }
                
                if let callback = callback {
                    let addedScreenshotOID = addedScreenshot.objectID
                    DispatchQueue.main.async {
                        if let mainScreenshot = dataModel.mainMoc().object(with: addedScreenshotOID) as? Screenshot {
                            callback(mainScreenshot)
                        }
                    }
                }
                if callback == nil,
                    dataModel.isNextMatchsticksNeeded(matchstickCount: dataModel.countMatchsticks(managedObjectContext: managedObjectContext)) {
                    RecombeeMatchstickModel.shared.fetchNextIfBelowWatermark()
                }
            } else {
                print("matchstick add managedObjectID:\(managedObjectID) not found")
            }
        }
    }
    
    public func pass() {
        let managedObjectID = self.objectID
        let dataModel = DataModel.sharedInstance
        dataModel.performBackgroundTask { (managedObjectContext) in
            do {
                if let matchstick = managedObjectContext.object(with: managedObjectID) as? Matchstick {
                    managedObjectContext.delete(matchstick)
                    try managedObjectContext.save()
                    if dataModel.isNextMatchsticksNeeded(matchstickCount: dataModel.countMatchsticks(managedObjectContext: managedObjectContext)) {
                        RecombeeMatchstickModel.shared.fetchNextIfBelowWatermark()
                    }
                } else {
                    print("matchstick pass managedObjectID:\(managedObjectID) not found")
                }
            } catch {
                DataModel.sharedInstance.receivedCoreDataError(error: error)
                print("matchstick pass managedObjectID:\(managedObjectID) results with error:\(error)")
            }
        }
    }
    
}
