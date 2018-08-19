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
import Whisper

class DiscoverManager {
    public static let shared = DiscoverManager()
    var makingLoadRecombeeRequest = false
    var downloadMatchsitckQueue:OperationQueue = {
        var queue = AsyncOperationQueue()
        queue.name = "Download matchsticks Queue"
        queue.maxConcurrentOperationCount = 4
        return queue
    }()
    var reloadingFilterQueue:AsyncOperationQueue = {
        var queue = AsyncOperationQueue()
        queue.name = "reloading filter matchsticks Queue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    var gender:ProductsOptionsGender = {
            if let genderNumber = UserDefaults.standard.value(forKey: UserDefaultsKeys.productGender) as? NSNumber,
                let gender = ProductsOptionsGender.init(rawValue: genderNumber.intValue){
                return gender
            }
            return .auto
        }() {
        didSet{
            UserDefaults.standard.set(gender.rawValue, forKey: UserDefaultsKeys.productGender)
        }
    }
    
    var discoverCategoryFilter:String? = {
        if let discoverCategoryFilter = UserDefaults.standard.value(forKey: UserDefaultsKeys.discoverCategoryFilter) as? String {
            return discoverCategoryFilter
        }
        return nil
        }() {
        didSet{
            
            UserDefaults.standard.set(discoverCategoryFilter, forKey: UserDefaultsKeys.discoverCategoryFilter)
            
        }
    }

    func createFilterChangingMonitor(delegate:AsyncOperationMonitorDelegate) -> AsyncOperationMonitor {
        return AsyncOperationMonitor.init(tags: [AsyncOperationTag.init(type: .filterChange, value: "DiscoverManager")], queues: [self.reloadingFilterQueue], delegate: delegate)
    }
    func didAdd(_ item:Matchstick, callback: ((_ screenshot: Screenshot) -> Void)? = nil ){
        let managedObjectID = item.objectID

        DataModel.sharedInstance.performBackgroundTask { (context) in
            if let item = context.object(with: managedObjectID) as? Matchstick,
                let assetId = item.remoteId,
                let uploadedImageURL = item.imageUrl {
                
                //create screesnhot
                let addedScreenshot = DataModel.sharedInstance.saveScreenshot(
                    upsert:true,
                    managedObjectContext: context,
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
                AssetSyncModel.sharedInstance.syteProcessing(imageData: nil, orImageUrlString: uploadedImageURL, assetId: assetId, optionsMask: ProductsOptionsMask.global)
                AssetSyncModel.sharedInstance.moveScreenshotToTopOfQueue(assetId: assetId)
                DispatchQueue.main.async {
                    AccumulatorModel.screenshotUninformed.incrementUninformedCount()
                }
                if callback == nil {
                    item.wasAdded = true
                    item.isDisplaying = false
                    self.fillQueues(in: context)
                }
                context.saveIfNeeded()
                
                
                // send recombee rating = 0.5 completion { request more recombee }
                self.sendrecombee(event: .positiveRating, assetId: assetId)
               
                
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
    func didDelayedAdd(_ item:Matchstick) {
        let managedObjectID = item.objectID
        
        DataModel.sharedInstance.performBackgroundTask { (context) in
            if let item = context.object(with: managedObjectID) as? Matchstick {
                
                item.wasAdded = true
                item.isDisplaying = false
                self.fillQueues(in: context)
                context.saveIfNeeded()
            }
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
                item.imageData = nil
                
                //fill up queues
                self.fillQueues(in: context)
                
                // send recombee rating = -0.5 completion { request more recombee }
                self.sendrecombee(event: .negativeRating, assetId: assetId)
                
                context.saveIfNeeded()
            }
        }
    }
    
    private func sendrecombee(event:AnalyticsTrackers.RecombeeAnalyticsTracker.RecombeeEvent, assetId:String){
        let isRecombeeId = (Int(assetId) != nil)
        if isRecombeeId {
            NetworkingPromise.sharedInstance.recombeeRequest(path: event.path(), method: "POST", params: event.postData(itemId: assetId)).always {
                self.recombeRequest(count:1)
            }
        }else{
            self.recombeRequest(count:1)
        }
        
    }
    
    @discardableResult private func recombeRequest(count:Int) -> Promise<Void>{
        let dateRequested = Date()
        return NetworkingPromise.sharedInstance.recombeeRecommendation(count:count, gender:self.gender, category:self.discoverCategoryFilter).then(execute: { (recommendations) -> Promise<Void> in
            return self.recombeeRecommendation(recommendations, dateRequested: dateRequested)
        }).catch(execute: { (error) in
            print("recombee error: \(error)")
        })
    }
    
    func updateFilterAndGetMoreIfNeeded(_ completion:@escaping (()->())){
        DataModel.sharedInstance.performBackgroundTask({ (context) in
            let displayingFetchRequest:NSFetchRequest<Matchstick> = Matchstick.fetchRequest()
            let displayingFetchRequestPredicate = Matchstick.predicateForDisplayingMatchstick()
            displayingFetchRequest.predicate = displayingFetchRequestPredicate
            if let displaying = try? context.fetch(displayingFetchRequest) {
                displaying.forEach{ $0.isDisplaying = false }
            }
            context.saveIfNeeded()

            let queuedFetchRequest:NSFetchRequest<Matchstick> = Matchstick.fetchRequest()
            let queuedFetchRequestPredicate = Matchstick.predicateForQueuedMatchstick(gender: self.gender, category: self.discoverCategoryFilter)
            queuedFetchRequest.predicate = queuedFetchRequestPredicate
            queuedFetchRequest.sortDescriptors = [NSSortDescriptor.init(key: "recombeeRecommended", ascending: false)]
            queuedFetchRequest.fetchLimit = Matchstick.recombeeQueueLowMark
            if let count = try? context.count(for: queuedFetchRequest), count >= Matchstick.recombeeQueueLowMark {
                self.fillQueues(in: context)
                context.saveIfNeeded()
                DispatchQueue.main.async {
                    completion()
                }
                return;
            }else{
                self.recombeRequest(count: 3).always {
                    DataModel.sharedInstance.performBackgroundTask({ (context) in
                        self.fillQueues(in: context)
                        context.saveIfNeeded()
                        DispatchQueue.main.async {
                            completion()
                        }
                    })
                }
            }
        })
    }
    func updateFilter(category:String?) {
        self.reloadingFilterQueue.addOperation(AsyncOperation.init(timeout: 90, tags: [AsyncOperationTag.init(type: .filterChange, value: "DiscoverManager")], completion: { (completion) in
            self.discoverCategoryFilter = category
            Analytics.trackMatchsticksFilterCategory(gender: self.gender.analyticsStringValue, category: self.discoverCategoryFilter)

            self.updateFilterAndGetMoreIfNeeded(completion)
        }))
    }
    
    func updateGender(gender:ProductsOptionsGender) {
        self.reloadingFilterQueue.addOperation(AsyncOperation.init(timeout: 90, tags: [AsyncOperationTag.init(type: .filterChange, value: "DiscoverManager")], completion: { (completion) in
           self.gender = gender
            Analytics.trackMatchsticksFilterGender(gender: self.gender.analyticsStringValue, category: self.discoverCategoryFilter)
           self.updateFilterAndGetMoreIfNeeded(completion)
        }))
    }
    
    private func fillQueues(in context:NSManagedObjectContext){
        let displayingFetchRequest:NSFetchRequest<Matchstick> = Matchstick.fetchRequest()
        let displayingFetchRequestPredicate = Matchstick.predicateForDisplayingMatchstick()
        displayingFetchRequest.predicate = displayingFetchRequestPredicate
        displayingFetchRequest.sortDescriptors = nil
        
        let queuedFetchRequest:NSFetchRequest<Matchstick> = Matchstick.fetchRequest()
        let queuedFetchRequestPredicate = Matchstick.predicateForQueuedMatchstick(gender: self.gender, category: self.discoverCategoryFilter)
        queuedFetchRequest.predicate = queuedFetchRequestPredicate
        queuedFetchRequest.sortDescriptors = [NSSortDescriptor.init(key: "recombeeRecommended", ascending: false)]
        queuedFetchRequest.fetchLimit = Matchstick.recombeeQueueSize + Matchstick.displayingSize
        
        if let displaying = try? context.fetch(displayingFetchRequest), let queued = try? context.fetch(queuedFetchRequest) {

            let displayingMatchStickNeeded = (Matchstick.displayingSize - displaying.count)
            var itemsAdded = 0
            let downloaded = queued.filter{ $0.imageData != nil }
            var downloadingAndDownloaded = self.downloadMatchsitckQueue.operationCount + downloaded.count
            queued.forEach({ (item) in
                if itemsAdded < displayingMatchStickNeeded {
                    if item.imageData != nil {
                        item.isDisplaying = true
                        item.receivedAt = Date()
                        itemsAdded += 1
                    }
                }else{
                    if item.imageData == nil,  let imageUrl = item.imageUrl, downloadingAndDownloaded < Matchstick.displayingSize  {
                        downloadingAndDownloaded += 1
                        self.downloadIfNeeded(imageURL: imageUrl, priority: .low)
                    }
                }
                if itemsAdded == displayingMatchStickNeeded {
                    context.saveIfNeeded()
                }
            })
            
            if queued.count == 0, let category = self.discoverCategoryFilter {
                Analytics.trackMatchsticksFilterNoResults(gender: self.gender.analyticsStringValue, category: category)
            }
            
            let currentQueueSize = (queued.count - itemsAdded)
            let queueItemsNeeded =  (Matchstick.queueSize - currentQueueSize)
            var currentIndex = UserDefaults.standard.integer(forKey: UserDefaultsKeys.discoverCurrentIndex)
            
            var newDiscover = Set<String>()
            let loopLimit = 10
            var loopCount = 0
            while (queueItemsNeeded >= newDiscover.count && loopCount < loopLimit) {
                loopCount += 1
                for _ in 0...queueItemsNeeded {
                    newDiscover.insert("\(currentIndex)")
                    currentIndex += 1
                    if currentIndex > Constants.discoverTotal {
                        currentIndex = 0
                    }
                }
                let existingFetchRequest:NSFetchRequest<Matchstick> = Matchstick.fetchRequest()
                existingFetchRequest.predicate = NSPredicate.init(format: "remoteId IN %@", newDiscover)
                if let existing = try? context.fetch(displayingFetchRequest){
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
                let imageUrl = "https://s3.amazonaws.com/screenshop-ordered-matchsticks/\(remoteId).jpg"
                let _ = DataModel.sharedInstance.saveMatchstick(managedObjectContext: context, remoteId: remoteId, imageUrl: imageUrl, properties: nil)
                self.downloadIfNeeded(imageURL: imageUrl, priority: .low)
            }
            
            UserDefaults.standard.setValue(currentIndex, forKey: UserDefaultsKeys.discoverCurrentIndex)
            
            
            if !makingLoadRecombeeRequest {
                let recombeeCount = queued.filter{ $0.recombeeRecommended != nil && $0.isDisplaying == false }.count
                if recombeeCount <= Matchstick.recombeeQueueLowMark {
                    self.makingLoadRecombeeRequest = true
                    self.recombeRequest(count:Matchstick.recombeeQueueSize - recombeeCount).always {
                        self.makingLoadRecombeeRequest = false
                    }
                }
            }
            
        }
    }
    
    func discoverViewDidAppear() {
        
        DataModel.sharedInstance.performBackgroundTask { (context) in
            self.fillQueues(in: context)
            context.saveIfNeeded()
        }
    }
    func downloadIfNeeded(imageURL:String, priority:Operation.QueuePriority) {
        if let op = self.currentOperationWith(imageUrl: imageURL){
            if op.queuePriority.rawValue < priority.rawValue {
                op.queuePriority = priority
            }
        }else{
            let tag = AsyncOperationTag.init(type: .assetId, value: imageURL)
            let operation = AsyncOperation.init(timeout: 90.0, tags: [tag], completion: { (completed) in
                NetworkingPromise.sharedInstance.downloadImageData(urlString: imageURL)
                    .then { imageData -> Void in
                        DataModel.sharedInstance.performBackgroundTask { (context) in
                            
                            if let matchstick = Matchstick.with(imageUrl: imageURL, in: context) {
                                matchstick.imageData = imageData
                                
                             
                            }else{
                                print("error: cannot find image to put data into!!!")
                            }

                            context.saveIfNeeded()
                            DataModel.sharedInstance.performBackgroundTask { (context) in
                                self.fillQueues(in: context)
                                context.saveIfNeeded()
                                completed()
                            }
                            
                        }
                    }.catch { error in
                        if case let PMKURLError.badResponse(_, _, response) = error,  let r = response as? HTTPURLResponse, r.statusCode == 404 {
                            DataModel.sharedInstance.performBackgroundTask { (context) in
                                if let matchstick = Matchstick.with(imageUrl: imageURL, in: context) {
                                    matchstick.was404 = true
                                    context.saveIfNeeded()
                                }
                            }
                        }
                        
                        completed()
                       
                }
            })
            operation.queuePriority = priority
            downloadMatchsitckQueue.addOperation(operation)
        }
    }
    
    func recombeeRecommendation(_ recommendations:[NetworkingPromise.RecombeeRecommendation], dateRequested:Date) -> Promise<Void>{
        return Promise.init(resolvers: { (fulfil, reject) in
            DataModel.sharedInstance.performBackgroundTask { (context) in
                let remoteIds = recommendations.map{ $0.remoteId }
                
                var matchstickLookup = Matchstick.lookupWith(remoteIds: remoteIds, in: context)
                
                var mayNeedToRequestMore = false
                recommendations.forEach({ (recomend) in
                    if let matchstick = matchstickLookup[recomend.remoteId], (matchstick.isInGarbage || matchstick.isDisplaying) {
                        mayNeedToRequestMore = true
                    }else {
                        let matchstick = matchstickLookup[recomend.remoteId] ?? DataModel.sharedInstance.saveMatchstick(managedObjectContext: context, remoteId: recomend.remoteId, imageUrl: recomend.imageURL, properties: recomend.properties)
                        if let matchstick = matchstick {
                            matchstick.recombeeRecommended = dateRequested
                            matchstick.dateSkipped = nil
                            self.downloadIfNeeded(imageURL: recomend.imageURL, priority:.high)
                        }
                    }
                })
                if mayNeedToRequestMore {
                    self.fillQueues(in: context)
                }
                context.saveIfNeeded()
                fulfil(())
            }
        })
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
    
}
