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
    
    public func add(callback: ((_ screenshot: Screenshot) -> Void)? = nil) {
        let managedObjectID = self.objectID
        let dataModel = DataModel.sharedInstance
        dataModel.performBackgroundTask { (managedObjectContext) in
            if let matchstick = managedObjectContext.object(with: managedObjectID) as? Matchstick,
                let assetId = matchstick.remoteId,
                let uploadedImageURL = matchstick.imageUrl {
                
                let addedScreenshot = dataModel.saveScreenshot(upsert:true,
                                                               managedObjectContext: managedObjectContext,
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

                AssetSyncModel.sharedInstance.syteProcessing(imageData: nil, orImageUrlString: uploadedImageURL, assetId: assetId, optionsMask: ProductsOptionsMask.global)
                    
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
                    MatchstickModel.shared.fetchNextIfBelowWatermark()
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
                        MatchstickModel.shared.fetchNextIfBelowWatermark()
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
