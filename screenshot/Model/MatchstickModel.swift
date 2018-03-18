//
//  MatchstickModel.swift
//  screenshot
//
//  Created by Gershon Kagan on 1/18/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import PromiseKit

class MatchstickModel: NSObject {
    
    public static let shared = MatchstickModel()
    var downloadMatchsitckQueue:OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Download matchsticks Queue"
        queue.maxConcurrentOperationCount = 2
        return queue
    }()

    let serialQ = DispatchQueue(label: "io.crazeapp.screenshot.matchsticks.serial")
    let processingQ = DispatchQueue.global(qos: .utility)
    private(set) var isFetchingNext = false
    
    public func prepareMatchsticks() {
        serialQ.async {
            if self.isFetchingNext {
                print("prepareMatchsticks is already fetching next matchsticks. What??")
            }
            self.isFetchingNext = true
            self.fetchMissingImages() // Don't call fetchMissingImages after fetchNextWorkhorse, or its images could be fetched twice
            self.fetchNextWorkhorse()
        }
    }
    
    public func fetchNextIfBelowWatermark() {
        serialQ.async {
            guard self.isFetchingNext == false else {
                return
            }
            self.isFetchingNext = true
            self.fetchNextWorkhorse()
        }
    }
    
    func fetchNextWorkhorse() {
        let dataModel = DataModel.sharedInstance
        dataModel.nextMatchsticksIfNeeded()
            .then(on: processingQ) { matchstickCount -> Promise<NSDictionary> in
                return NetworkingPromise.sharedInstance.nextMatchsticks()
            }.then(on: processingQ) { dict -> Void in
                if let matchsticksArray = dict["screenshots"] as? [[String : Any]] {
                    dataModel.performBackgroundTask { (managedObjectContext) in
                        // Reverse order received, so we can always take latest saved.
                        for matchstick in matchsticksArray {
                            if let remoteId = matchstick["id"] as? String,
                                let imageUrl = matchstick["image"] as? String,
                                let syteJson = matchstick["syteJson"] as? String {
                                let _ = dataModel.saveMatchstick(managedObjectContext: managedObjectContext,
                                                                 remoteId: remoteId,
                                                                 imageUrl: imageUrl,
                                                                 syteJson: syteJson)
                                self.processingQ.async {
                                    self.fetchImageData(imageUrl: imageUrl)
                                }
                            } else {
                                print("Could not parse matchstick:\(matchstick)")
                            }
                        }
                        managedObjectContext.saveIfNeeded()
                        if let token = dict["next"] as? String {
                            UserDefaults.standard.set(token, forKey: UserDefaultsKeys.matchsticksSyncToken)
                        }
                        print("fetchNextIfBelowWatermark saveMoc matchsticksArray.count:\(matchsticksArray.count)")
                    }
                } else {
                    print("fetchNextIfBelowWatermark could not parse dict:\(dict)")
                }
            }.always(on: self.serialQ) {
                self.isFetchingNext = false
            }.catch(on: processingQ) { error in
                print("fetchNextIfBelowWatermark catch error:\(error)")
        }
    }
    
    func fetchMissingImages() {
        let dataModel = DataModel.sharedInstance
        dataModel.performBackgroundTask { (managedObjectContext) in
            let imageUrls = dataModel.retrieveMatchstickImageUrlsWithNoData(managedObjectContext: managedObjectContext)
            for imageUrl in imageUrls {
                self.processingQ.async {
                    self.fetchImageData(imageUrl: imageUrl)
                }
            }
        }
    }
    
    func fetchImageData(imageUrl: String) {
        self.downloadMatchsitckQueue.addOperation(AsyncOperation.init(timeout: 90.0) { (completed) in
            NetworkingPromise.sharedInstance.downloadImageData(urlString: imageUrl)
                .then(on: self.processingQ) { imageData -> Void in
                    DataModel.sharedInstance.performBackgroundTask { (managedObjectContext) in
                        DataModel.sharedInstance.addImageDataToMatchstick(managedObjectContext: managedObjectContext, imageUrl: imageUrl, imageData: imageData)
                        completed()
                    }
                }.catch(on: self.processingQ) { error in
                    print("fetchImageData catch error:\(error)")
                    completed()
            }
            
        })
    }

}

