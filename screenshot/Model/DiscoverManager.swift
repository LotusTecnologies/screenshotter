//
//  DiscoverManager.swift
//  screenshot
//
//  Created by Jonathan Rose on 6/27/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import CoreData
import PromiseKit

class DiscoverManager {

    var downloadMatchsitckQueue:OperationQueue = {
        var queue = AsyncOperationQueue()
        queue.name = "Download matchsticks Queue"
        queue.maxConcurrentOperationCount = 2
        return queue
    }()
    
    func didAdd(_ item:Matchstick, callback: ((_ screenshot: Screenshot) -> Void)? = nil ){
        let managedObjectID = item.objectID

        DataModel.sharedInstance.performBackgroundTask { (context) in
            if let item = context.object(with: managedObjectID) as? Matchstick,
                let assetId = item.remoteId,
                let uploadedImageURL = item.imageUrl {
                // DisplayingItem -> GarbageItem
                item.wasAdded = true
                item.isDisplaying = false
                //create screesnhot
                let addedScreenshot = DataModel.sharedInstance.saveScreenshot(managedObjectContext: context,
                                                               assetId: assetId,
                                                               createdAt: Date(),
                                                               isRecognized: true,
                                                               source: .discover,
                                                               isHidden: false,
                                                               imageData: item.imageData as Data?,
                                                               uploadedImageURL: uploadedImageURL,
                                                               syteJsonString: nil)
                addedScreenshot.trackingInfo = item.trackingInfo
                Analytics.trackScreenshotCreated(screenshot: addedScreenshot)
                AssetSyncModel.sharedInstance.processingQ.async {
                    AssetSyncModel.sharedInstance.syteProcessing(imageData: nil, orImageUrlString: uploadedImageURL, assetId: assetId, optionsMask: ProductsOptionsMask.global)
                    
                }
                DispatchQueue.main.async {
                    AccumulatorModel.screenshotUninformed.incrementUninformedCount()
                }
                //fill up queues
                self.fillQueues(in: context)
                
                // 4) send recombee rating = 0.5 completion { request more recombee }
                let event = AnalyticsTrackers.RecombeeAnalyticsTracker.RecombeeEvent.positiveRating
                NetworkingPromise.sharedInstance.recombeeRequest(path: event.path(), method: "POST", params: event.postData(itemId: assetId)).always {
                    NetworkingPromise.sharedInstance.recombeeRecommendation().then(execute: { (recommendations) -> Void in
                        self.recombeeRecommendation(recommendations)
                    })
                }
                
                context.saveIfNeeded()
                if let callback = callback {
                    let addedScreenshotOID = addedScreenshot.objectID
                    DispatchQueue.main.async {
                        if let mainScreenshot = DataModel.sharedInstance.mainMoc().object(with: addedScreenshotOID) as? Screenshot {
                            callback(mainScreenshot)
                        }
                    }
                }
            }
        }
    }
    private func fillQueues(in context:NSManagedObjectContext){
        let displayingFetchRequest:NSFetchRequest<Matchstick> = Matchstick.fetchRequest()
        displayingFetchRequest.predicate = Matchstick.predicateForDisplayingMatchstick()
        displayingFetchRequest.sortDescriptors = nil
        
        let queuedFetchRequest:NSFetchRequest<Matchstick> = Matchstick.fetchRequest()
        queuedFetchRequest.predicate = Matchstick.predicateForQueuedMatchstick()
        queuedFetchRequest.sortDescriptors = [NSSortDescriptor.init(key: "recombeeRecommended", ascending: false)]
        
        if let displaying = try? context.fetch(displayingFetchRequest), let queued = try? context.fetch(queuedFetchRequest){
            let displayingMatchStickNeeded = (Matchstick.displayingSize - displaying.count)
            var itemsAdded = 0
            queued.forEach({ (item) in
                if itemsAdded < displayingMatchStickNeeded {
                    if item.imageData != nil {
                        item.isDisplaying = false
                        item.receivedAt = Date()
                        itemsAdded += 1
                    }
                }
            })

            let currentQueueSize = (queued.count - itemsAdded)
            var queueItemsNeeded =  (Matchstick.queueSize - currentQueueSize)
            var currentIndex = UserDefaults.standard.integer(forKey: UserDefaultsKeys.discoverCurrentIndex)
            
            var newDiscover = Set<String>()
            let loopLimit = 10
            var loopCount = 0
            while (queueItemsNeeded > 0 && loopCount < loopLimit) {
                loopCount += 1
                for i in 0...queueItemsNeeded {
                    if currentIndex > Constants.discoverTotal {
                        currentIndex = 0
                    }
                    newDiscover.insert("\(currentIndex+i)")
                }
                let existingFetchRequest:NSFetchRequest<Matchstick> = Matchstick.fetchRequest()
                existingFetchRequest.predicate = NSPredicate.init(format: "remoteId IN $@", newDiscover)
                if let existing = try? context.fetch(displayingFetchRequest){
                    queueItemsNeeded = existing.count
                    for matchstick in existing {
                        if let remoteId = matchstick.remoteId {
                            newDiscover.remove(remoteId)
                        }
                    }
                }else{
                    loopCount = loopLimit
                }
            }

            newDiscover.forEach { (remoteId) in
                let imageUrl = "https://s3.amazonaws.com/screenshop-ordered-discover/\(remoteId).jpg"
                DataModel.sharedInstance.saveMatchstick(managedObjectContext: context, remoteId: remoteId, imageUrl: imageURL, syteJson: nil, trackingInfo: nil)
                self.downloadIfNeeded(imageURL: imageUrl, priority: .low)
            }
            
            UserDefaults.standard.setValue(currentIndex, forKey: UserDefaultsKeys.discoverCurrentIndex)
            context.saveIfNeeded()

            
        }

    }
    func didSkip(_ item:Matchstick) {
        
        let managedObjectID = item.objectID
        
        DataModel.sharedInstance.performBackgroundTask { (context) in
            if let item = context.object(with: managedObjectID) as? Matchstick,
                let assetId = item.remoteId {
                // DisplayingItem -> GarbageItem
                item.dateSkipped = Date()
                item.isDisplaying = false
                //fill up queues
                self.fillQueues(in: context)
                
                // 4) send recombee rating = 0.5 completion { request more recombee }
                let event = AnalyticsTrackers.RecombeeAnalyticsTracker.RecombeeEvent.negativeRating
                NetworkingPromise.sharedInstance.recombeeRequest(path: event.path(), method: "POST", params: event.postData(itemId: assetId)).always {
                    NetworkingPromise.sharedInstance.recombeeRecommendation().then(execute: { (recommendations) -> Void in
                        self.recombeeRecommendation(recommendations)
                    })
                }
            }
        }
    }

    func discoverViewDidAppear() {
        DataModel.sharedInstance.performBackgroundTask { (context) in
            self.fillQueues(in: context)
        }
    }
    func downloadIfNeeded(imageURL:String, priority:Operation.QueuePriority) {
        if let op = self.currentOperationWith(imageUrl: imageURL){
            if op.queuePriority.rawValue < priority.rawValue {
                op.queuePriority = priority
            }
        }else{
            self.fetchImageData(imageUrl: imageURL, priority: priority).then { (data) -> Void in
                DataModel.sharedInstance.performBackgroundTask { (context) in
                    DataModel.sharedInstance.addImageDataToMatchstick(managedObjectContext: context, imageUrl: imageURL, imageData: data)
                    self.fillQueues(in: context)
                }
                }.catch { (error) in
                    // if 404 set item as 404
            }
        }
    }
    
    func recombeeRecommendation(_ recommendations:[NetworkingPromise.RecombeeRecommendation]){
        DataModel.sharedInstance.performBackgroundTask { (context) in
            let remoteIds = recommendations.map{ $0.remoteId }
            let fetchRequest: NSFetchRequest<Matchstick> = Matchstick.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "remoteId IN %@", remoteIds)
            fetchRequest.sortDescriptors = nil
            var matchstickLookup:[String:Matchstick] = [:]
            if let results = try? context.fetch(fetchRequest) {
                results.forEach { if let remoteId = $0.remoteId { matchstickLookup[remoteId] = $0  } }
            }

            recommendations.forEach({ (recomend) in
                if let matchstick = matchstickLookup[recomend.remoteId], matchstick.isInGarbage || matchstick.isDisplaying {
                    NetworkingPromise.sharedInstance.recombeeRecommendation().then(execute: { (recommendations) -> Void in
                        self.recombeeRecommendation(recommendations)
                    })
                }else {
                    let matchstick = matchstickLookup[recomend.remoteId] ?? DataModel.sharedInstance.saveMatchstick(managedObjectContext: context, remoteId: recomend.remoteId, imageUrl: recomend.imageURL, syteJson: nil, trackingInfo: nil)
                    if let matchstick = matchstick {
                        matchstick.recombeeRecommended += 1
                        matchstick.dateSkipped = nil
                        self.downloadIfNeeded(imageURL: recomend.imageURL, priority:.high)
                    }
                }
            })
        }
    }
    
    func currentDownloadingImageUrls() -> Set<String> {
        var toReturn:Set<String> = []
        for op in downloadMatchsitckQueue.operations {
            if let op = op as? AsyncOperation {
                if let url = op.tags.first?.value {
                    toReturn.insert(url)
                }
            }
        }
        return toReturn
    }

    func currentOperationWith(imageUrl:String) -> Operation? {
        for op in downloadMatchsitckQueue.operations {
            if let op = op as? AsyncOperation {
                for tag in op.tags {
                    if tag.value == imageUrl {
                        return op
                    }
                }
            }
        }
        return nil
    }
    func fetchImageData(imageUrl: String, priority:Operation.QueuePriority) -> Promise<Data> {
        return Promise.init(resolvers: { (fulfil, reject) in
            let tag = AsyncOperationTag.init(type: .assetId, value: imageUrl)
            let operation = AsyncOperation.init(timeout: 90.0, tags: [tag], completion: { (completed) in
                NetworkingPromise.sharedInstance.downloadImageData(urlString: imageUrl)
                    .then { imageData -> Void in
                        fulfil(imageData)
                        completed()
                    }.catch { error in
                        reject(error)
                        completed()
                }
            })
            operation.queuePriority = priority
            downloadMatchsitckQueue.addOperation(operation)
        })
    }
}
