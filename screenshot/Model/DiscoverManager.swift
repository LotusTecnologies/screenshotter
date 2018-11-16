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
        queue.maxConcurrentOperationCount = 8
        return queue
    }()
    var databaseQueue:AsyncOperationQueue = {
        var queue = AsyncOperationQueue()
        queue.name = "DiscoverManager databaseQueue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    var apiCallQueue:AsyncOperationQueue = {
        var queue = AsyncOperationQueue()
        queue.name = "DiscoverManager apiCallQueue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
   
    var processing:Bool = false
    var failureStop:Bool = false
    var tags:[String:SortedArray<String>]?
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
        return AsyncOperationMonitor.init(tags: [AsyncOperationTag.init(type: .filterChange, value: "DiscoverManager")], queues: [self.databaseQueue], delegate: delegate)
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
        
        // Queue size limit must be set, currently API is returning 100 items so using 200 to be safe
        queuedFetchRequest.fetchLimit = 200
        
        if let displaying = try? context.fetch(displayingFetchRequest), let queued = try? context.fetch(queuedFetchRequest) {
           
            // Move items from "Queue" (data ready for display) to "Display" (cards rendered by UI)
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
                        if let imageUrl = item.imageUrl  {
                            self.downloadIfNeeded(imageURL: imageUrl, priority: (downloadingAndDownloaded < Matchstick.displayingSize) ? .high : .low)
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
            
            // If "Queue" falls below minimum allowed size, make an API call to get more items
            let currentQueueSize = (queued.count - itemsAdded)
            print("[SSC] Queue size = \(currentQueueSize)")
            let queueItemsNeeded:Bool = (Matchstick.minQueueSize >= currentQueueSize)
            
            if queueItemsNeeded {
                let userID:String! = UserDefaults.standard.string(forKey: UserDefaultsKeys.userID) ?? ""
                getProductIdsFromServer(userID: userID, algoID: UserDefaults.standard.string(forKey: UserDefaultsKeys.discoverAlgoUUID), context: context)
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
    
    // MARK: - Networking Calls
    
    /*
     * Make API call to server with user Id to get product recommendations for display in discover feed.
     */
    func getProductIdsFromServer(userID:String, algoID:String?, context: NSManagedObjectContext) {
        // 'processing' Bool is used to "lock" thread and prevent multiple calls race condition
        if processing || failureStop {
            return
        }
        processing = true
        
        print("[SSC] Making API Call to populate more items.")
        var jsonLiteral:[String:String] = ["user_ss_uuid": userID]
        if let algoUuid = algoID {
            jsonLiteral["discover_algorithm_ss_uuid"] = algoUuid
        }
        let jsonData = try? JSONSerialization.data(withJSONObject: jsonLiteral)
        
        // create post request
        let url = URL(string: HTTPHelper.FILL_DISCOVER_URL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // insert json data to the request
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var responseJSON:[[String:Any]]? = nil
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, res, error) in
            if error != nil {
                self.failureStop = true
            } else {
                if let d = data {
                    do {
                        responseJSON = try JSONSerialization.jsonObject(with: d, options: JSONSerialization.ReadingOptions.allowFragments) as? [[String:Any]]
                        if let r = responseJSON {
                            for dict in r {
                                if let remoteId = dict["picture_ss_uuid"] as! String?, let imageUrl = dict["image_url"] as! String? {
                                    print("REMOTE ID = \(remoteId)")
                                    let _ = DataModel.sharedInstance.saveMatchstick(managedObjectContext: context, remoteId: remoteId, imageUrl: imageUrl, properties: self.propertiesFor(id: remoteId))
                                    self.downloadIfNeeded(imageURL: imageUrl, priority: .low)
                                }
                            }
                            print("[SSC] Added \(r.count) items to queue.")
                        } else {
                            self.failureStop = true
                        }
                    } catch {
                        self.failureStop = true
                    }
                } else {
                    self.failureStop = true
                }
            }
            context.saveIfNeeded()
            self.processing = false
            self.discoverViewDidAppear()
        }
        task.resume()
    }
    
    /*
     * Make API call to server to record a user has swipped y/n on a discover card
     */
    func postUserActionToServer(userID:String, discoverPictureID:String, actionType:String, servingAlgorithmID:String, DiscoverSessionID:String, context: NSManagedObjectContext) {
        
    }
}
