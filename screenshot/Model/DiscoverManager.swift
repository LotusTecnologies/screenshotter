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
    public static let shared = DiscoverManager()
    var downloadMatchsitckQueue:AsyncOperationQueue = {
        var queue = AsyncOperationQueue()
        queue.name = "Download matchsticks Queue"
        queue.maxConcurrentOperationCount = 4
        return queue
    }()
    var databaseQueue:AsyncOperationQueue = {
        var queue = AsyncOperationQueue()
        queue.name = "DiscoverManager databaseQueue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
   

    var tags:[String:[String]]?
    var undisplayable:Set<String>?
    var gender:String = {
            return UserDefaults.standard.string(forKey: UserDefaultsKeys.discoverGenderFilter) ?? ""
        }() {
        didSet{
            UserDefaults.standard.set(gender, forKey: UserDefaultsKeys.discoverGenderFilter)
        }
    }
    
    var discoverCategoryFilter:String = {
            return UserDefaults.standard.string(forKey: UserDefaultsKeys.discoverCategoryFilter) ?? ""
        }() {
        didSet{
            UserDefaults.standard.set(discoverCategoryFilter, forKey: UserDefaultsKeys.discoverCategoryFilter)
            
        }
    }
    var isUnfiltered:Bool {
        return self.gender == "" && self.discoverCategoryFilter == ""
    }
    
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        self.databaseQueue.addOperation(AsyncOperation.init(timeout: nil, tags: [AsyncOperationTag.init(type: .filterChange, value: "DiscoverManager")], completion: { (completion) in
            DataModel.sharedInstance.performBackgroundTask({ (context) in
                block(context);
                completion()
            })
        }))
    }

    func createFilterChangingMonitor(delegate:AsyncOperationMonitorDelegate) -> AsyncOperationMonitor {
        return AsyncOperationMonitor.init(tags: [AsyncOperationTag.init(type: .filterChange, value: "DiscoverManager")], queues: [self.databaseQueue, self.downloadMatchsitckQueue], delegate: delegate)
    }
    func didAdd(_ item:Matchstick, callback: ((_ screenshot: Screenshot) -> Void)? = nil ){
        let managedObjectID = item.objectID

        self.performBackgroundTask { (context) in
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
                addedScreenshot.screenshotId = item.remoteId
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
        
        self.performBackgroundTask { (context) in
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
        
        self.performBackgroundTask { (context) in
            if let item = context.object(with: managedObjectID) as? Matchstick {
                // DisplayingItem -> GarbageItem
                item.dateSkipped = Date()
                item.isDisplaying = false
                item.imageData = nil
                
                //fill up queues
                self.fillQueues(in: context)
                
                context.saveIfNeeded()
            }
        }
    }
    
    func updateFilterAndGetMoreIfNeeded(){
        self.performBackgroundTask({ (context) in
            let displayingFetchRequest:NSFetchRequest<Matchstick> = Matchstick.fetchRequest()
            let displayingFetchRequestPredicate = Matchstick.predicateForDisplayingMatchstick()
            displayingFetchRequest.predicate = displayingFetchRequestPredicate
            if let displaying = try? context.fetch(displayingFetchRequest) {
                displaying.forEach{ $0.isDisplaying = false }
            }
            context.saveIfNeeded()

            let queuedFetchRequest:NSFetchRequest<Matchstick> = Matchstick.fetchRequest()
            let queuedFetchRequestPredicate = Matchstick.predicateForQueuedMatchstick(gender: self.gender, category: self.discoverCategoryFilter)
            queuedFetchRequest.predicate = NSCompoundPredicate.init(andPredicateWithSubpredicates: [NSPredicate.init(format: "imageData != NULL"), queuedFetchRequestPredicate])
            queuedFetchRequest.sortDescriptors = [NSSortDescriptor.init(key: "recombeeRecommended", ascending: false)]
            if let queued = try? context.fetch(queuedFetchRequest), queued.count > 0 {
                queued.prefix(Matchstick.displayingSize).forEach({
                    $0.isDisplaying = true
                    $0.receivedAt = Date()
                })
            }else{
                self.fillQueues(in: context)
            }
            
            context.saveIfNeeded()
        })
    }
    func updateFilter(category:String?) {
        self.discoverCategoryFilter = category ?? ""
        Analytics.trackMatchsticksFilterCategory(gender: self.gender, category: self.discoverCategoryFilter)
        
        self.updateFilterAndGetMoreIfNeeded()
    }
    
    func updateGender(gender:String) {
        self.gender = gender
        Analytics.trackMatchsticksFilterGender(gender: self.gender, category: self.discoverCategoryFilter)
        self.updateFilterAndGetMoreIfNeeded()
    }
    
    private func fillQueues(in context:NSManagedObjectContext) {
        let displayingFetchRequest:NSFetchRequest<Matchstick> = Matchstick.fetchRequest()
        let displayingFetchRequestPredicate = Matchstick.predicateForDisplayingMatchstick()
        displayingFetchRequest.predicate = displayingFetchRequestPredicate
        displayingFetchRequest.sortDescriptors = nil
        
        let queuedFetchRequest:NSFetchRequest<Matchstick> = Matchstick.fetchRequest()
        let queuedFetchRequestPredicate = Matchstick.predicateForQueuedMatchstick(gender: self.gender, category: self.discoverCategoryFilter)
        queuedFetchRequest.predicate = queuedFetchRequestPredicate
        queuedFetchRequest.sortDescriptors = [NSSortDescriptor.init(key: "recombeeRecommended", ascending: false)]
        queuedFetchRequest.fetchLimit = Matchstick.queueSize + Matchstick.displayingSize
        
        if let displaying = try? context.fetch(displayingFetchRequest), let queued = try? context.fetch(queuedFetchRequest) {
           
            
            let displayingMatchStickNeeded = (Matchstick.displayingSize - displaying.count)
            var itemsAdded = 0
            let downloaded = queued.filter{ $0.imageData != nil }
            queued.forEach({ (item) in
                var downloadingAndDownloaded = self.downloadMatchsitckQueue.operationCount + downloaded.count

                if itemsAdded < displayingMatchStickNeeded {
                    if item.imageData != nil {
                        item.isDisplaying = true
                        item.receivedAt = Date()
                        itemsAdded += 1
                    }else{
                        if let imageUrl = item.imageUrl, downloadingAndDownloaded < Matchstick.displayingSize  {
                            self.downloadIfNeeded(imageURL: imageUrl, priority: .high)
                        }
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
            if queued.count == 0 {
                Analytics.trackMatchsticksFilterNoResults(gender: self.gender, category: self.discoverCategoryFilter)
            }
            var newDiscover = Set<String>()
            let currentQueueSize = (queued.count - itemsAdded)
            let queueItemsNeeded =  (Matchstick.queueSize - currentQueueSize)

            if self.isUnfiltered {
                var currentIndex = UserDefaults.standard.integer(forKey: UserDefaultsKeys.discoverCurrentIndex)
                
                let loopLimit = 10
                var loopCount = 0
                while (queueItemsNeeded >= newDiscover.count && loopCount < loopLimit) {
                    loopCount += 1
                    for _ in 0...queueItemsNeeded {
                        if !self.isUndisplayable(index: "\(currentIndex)") {
                            newDiscover.insert("\(currentIndex)")
                            currentIndex += 1
                            if currentIndex > Constants.discoverTotal {
                                currentIndex = 0
                            }
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
                UserDefaults.standard.setValue(currentIndex, forKey: UserDefaultsKeys.discoverCurrentIndex)
            }else{
                let sortKey:String = {
                    if self.gender == "male" {
                        return "male"
                    }else{
                        return self.discoverCategoryFilter
                    }
                }()
                if let array = self.indexForCategory(sortKey) {
                    let arrayLength = array.count
                    var currentIndex = UserDefaults.standard.integer(forKey: "offset_\(sortKey)")
                    
                    let loopLimit = 10
                    var loopCount = 0
                    while (queueItemsNeeded >= newDiscover.count && loopCount < loopLimit) {
                        loopCount += 1
                        for _ in 0...queueItemsNeeded {
                            if arrayLength > currentIndex {
                                if !self.isUndisplayable(index: "\(currentIndex)") {
                                    let value = array[currentIndex]
                                    newDiscover.insert(value)
                                    currentIndex += 1
                                }
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
                    UserDefaults.standard.setValue(currentIndex, forKey: "offset_\(sortKey)")
                }
                
                
            }
            
            newDiscover.forEach { (remoteId) in
                
                let imageUrl = self.urlStringFor(index: remoteId)
                let _ = DataModel.sharedInstance.saveMatchstick(managedObjectContext: context, remoteId: remoteId, imageUrl: imageUrl, properties: self.propertiesFor(id: remoteId))
                self.downloadIfNeeded(imageURL: imageUrl, priority: .low)
            }
        }
    }
    
    func discoverViewDidAppear() {
        
        self.performBackgroundTask { (context) in
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
            let operation = AsyncOperation.init(timeout: 90.0, tags: [tag, AsyncOperationTag.init(type: .filterChange, value: "DiscoverManager")], completion: { (completed) in
                NetworkingPromise.sharedInstance.downloadImageData(urlString: imageURL)
                    .then { imageData -> Void in
                        self.performBackgroundTask { (context) in
                            
                            if let matchstick = Matchstick.with(imageUrl: imageURL, in: context) {
                                matchstick.imageData = imageData
                                
                             
                            }else{
                                print("error: cannot find image to put data into!!!")
                            }

                            context.saveIfNeeded()
                            self.performBackgroundTask { (context) in
                                let displayingFetchRequest:NSFetchRequest<Matchstick> = Matchstick.fetchRequest()
                                let displayingFetchRequestPredicate = Matchstick.predicateForDisplayingMatchstick()
                                displayingFetchRequest.predicate = displayingFetchRequestPredicate
                                displayingFetchRequest.sortDescriptors = nil
                                
                                if let displaying = try? context.fetch(displayingFetchRequest){
                                    if displaying.count == 0{
                                        self.fillQueues(in: context)
                                        context.saveIfNeeded()
                                    }
                                }
                            }
                            
                        }
                    }.catch { error in
                        if case let PMKURLError.badResponse(_, _, response) = error,  let r = response as? HTTPURLResponse, r.statusCode == 404 {
                            self.performBackgroundTask { (context) in
                                if let matchstick = Matchstick.with(imageUrl: imageURL, in: context) {
                                    matchstick.was404 = true
                                    context.saveIfNeeded()
                                }
                            }
                        }
                        
                    }.always {
                        completed()

                }
            })
            operation.queuePriority = priority
            downloadMatchsitckQueue.addOperation(operation)
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
    
}
