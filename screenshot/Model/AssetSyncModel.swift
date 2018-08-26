//
//  AssetSyncModel.swift
//  screenshot
//
//  Created by Gershon Kagan on 8/9/17.
//  Copyright (c) 2017 crazeapp. All rights reserved.
//

import UIKit
import Photos
import CoreData // NSManagedObjectContext
import PromiseKit
import SDWebImage

class AssetSyncModel: NSObject {
    
    public static let sharedInstance = AssetSyncModel()
    public weak var networkingIndicatorDelegate: NetworkingIndicatorProtocol?
    let serialQ = DispatchQueue(label: "io.crazeapp.screenshot.syncPhotos.serial")
    let processingQ = DispatchQueue.global(qos: .default) // .utility // DispatchQueue(label: "io.crazeapp.screenshot.syncPhotos.processing")
    var foregroundScreenshotAssetIds = Set<String>()
    var userJustTookScreenshotAssetIds = Set<String>()
    var shouldSendPushWhenFindFashionWithoutUserScreenshotAction = true
    var isRegistered = false
    var isNextScreenshotForeground = false
    var isRecentlyForeground = false
    var backgroundProcessFetchedResults:PHFetchResult<PHAsset>?
    var lastDidBecomeActiveDate:Date?
    var screenshotQueuePriotiyList:[String:Date] = [:]
    
    let uploadScreenshotWithClarifaiQueue:AsyncOperationQueue = {
        var queue = AsyncOperationQueue()
        queue.name = "upload Screenshot With Clarifai Queue"
        queue.maxConcurrentOperationCount = 1
        queue.isSuspended = false
        queue.qualityOfService = .utility
        return queue
    }()
    
    let uploadScreenshotWithClarifaiQueueFromUserScreenshot:AsyncOperationQueue = {
        var queue = AsyncOperationQueue()
        queue.name = "upload Screenshot With Clarifai Queue from user screenshot"
        queue.maxConcurrentOperationCount = 1
        queue.isSuspended = false
        queue.qualityOfService = .userInitiated
        
        return queue
    }()
    
    let syteProcessingQueue:AsyncOperationQueue = {
        var queue = AsyncOperationQueue()
        queue.name = "Syte processing Queue"
        queue.maxConcurrentOperationCount = 5
        queue.qualityOfService = .userInteractive
        return queue
    }()
    
    let downloadProductQueue:AsyncOperationQueue = {
        var queue = AsyncOperationQueue()
        queue.name = "download products Queue"
        queue.maxConcurrentOperationCount = 2
        queue.qualityOfService = .userInteractive
        return queue
    }()
    
    let coreDataProcessingQueue:AsyncOperationQueue = {
        var queue = AsyncOperationQueue()
        queue.name = "core data processing Queue"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInteractive
        return queue
    }()
    
    var userInitiatedQueue:AsyncOperationQueue = {
        var queue = AsyncOperationQueue()
        queue.name = "retry Screenshot image processing Queue"
        queue.maxConcurrentOperationCount = 2
        queue.qualityOfService = .userInteractive
        return queue
    }()
    
    var relatedLooksQueue:AsyncOperationQueue = {
        var queue = AsyncOperationQueue()
        queue.name = "relatedLooksQueue"
        queue.maxConcurrentOperationCount = 2
        queue.qualityOfService = .userInteractive
        return queue
    }()
    
    let queues:[AsyncOperationQueue]
    override init() {
        queues = [userInitiatedQueue,coreDataProcessingQueue, downloadProductQueue, syteProcessingQueue, uploadScreenshotWithClarifaiQueueFromUserScreenshot, uploadScreenshotWithClarifaiQueue, relatedLooksQueue ]
        super.init()
        registerForPhotoChanges()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationUserDidTakeScreenshot), name: .UIApplicationUserDidTakeScreenshot, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: .UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(scanPhotoGalleryForFashion), name: .permissionsManagerDidUpdate, object: nil)
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func applicationDidBecomeActive(){
        self.lastDidBecomeActiveDate = Date()
        self.processingQ.async {
            self.shouldSendPushWhenFindFashionWithoutUserScreenshotAction = false
        }
        self.backgroundProcessFetchedResults?.enumerateObjects({ (asset, index, pointer) in
            if asset.isVeryRecent {
                DataModel.sharedInstance.performBackgroundTask({ (context) in
                    if let screenshot = context.screenshotWith(assetId: asset.localIdentifier) {
                        if screenshot.isRecognized && screenshot.isNew{
                            self.importPhotosToScreenshot(assets: [asset], source: .screenshot)
                        }
                    }else{
                        // will be added when "clarifai" style processing is done
                    }
                })
            }
        })
        
    }
    
    func performBackgroundTask(assetId:String?, shoppableId:String?,  _ block: @escaping (NSManagedObjectContext) -> Void ) {
        self.coreDataProcessingQueue.addOperation(AsyncOperation.init(timeout: 20, assetId: assetId, shoppableId: shoppableId, completion: { (completion) in
            DataModel.sharedInstance.performBackgroundTask({ (context) in
                block(context)
                completion()
            })
        }))
    }
    
}

//User initiated Import
extension AssetSyncModel {
    
    public func importPhotosToScreenshot(assetIds:[String], source:ScreenshotSource) {
        assetIds.forEach {
            if let asset = PHAsset.assetWith(assetId: $0) {
                self.uploadPhoto(asset: asset, source: source)
            }
        }
    }
    public func addFromRelatedLook(urlString:String, callback: ((_ screenshot: Screenshot) -> Void)? = nil) {
        self.addScreenshotFrom(source: .shuffle, urlString: urlString, callback: callback)
    }
    public func addScreenshotFrom(source:ScreenshotSource, urlString:String, callback: ((_ screenshot: Screenshot) -> Void)? = nil) {

        if Thread.isMainThread {
            if let mainScreenshot = DataModel.sharedInstance.mainMoc().screenshotWith(assetId: urlString) {
                if let callback =  callback{
                    callback(mainScreenshot)
                    return;
                }
            }else if let mainScreenshot = DataModel.sharedInstance.mainMoc().screenshotWith(imageUrl: urlString){
                if let callback =  callback{
                    callback(mainScreenshot)
                    return;
                }
            }
        }
        
        
        self.relatedLooksQueue.addOperation(AsyncOperation.init(timeout: 30, assetId: urlString, shoppableId: nil, completion: { (completion) in
            self.performBackgroundTask(assetId: urlString, shoppableId: nil) { (managedObjectContext) in
                if let screenshot = managedObjectContext.screenshotWith(assetId: urlString) {
                    if screenshot.source != source {
                        screenshot.source = source
                    }
                    if let callback = callback {
                        let addedScreenshotOID = screenshot.objectID
                        DispatchQueue.main.async {
                            if let mainScreenshot = DataModel.sharedInstance.mainMoc().object(with: addedScreenshotOID) as? Screenshot {
                                callback(mainScreenshot)
                                
                            }
                            completion()
                        }
                    }else{
                        completion()
                    }
                    managedObjectContext.saveIfNeeded()
                }else{
                   
                    SDWebImageManager.shared().loadImage(with: URL.init(string: urlString), options: [SDWebImageOptions.fromCacheOnly], progress: nil, completed: { (image, data, error, cache, bool, url) in
                        
                        let imageData:Data? =  {
                            if let data = data {
                                return data
                            }else if let i = image {
                                return AssetSyncModel.sharedInstance.data(for: i)
                            }
                            return nil
                        }()
                        if let imageData = imageData {
                            self.performBackgroundTask(assetId: urlString, shoppableId: nil, { (managedObjectContext) in
                                
                                let addedScreenshot = DataModel.sharedInstance.saveScreenshot(upsert: true,
                                                                                              managedObjectContext: managedObjectContext,
                                                                                              assetId: urlString,
                                                                                              createdAt: Date(),
                                                                                              isRecognized: true,
                                                                                              source: source,
                                                                                              isHidden: false,
                                                                                              imageData: imageData,
                                                                                              uploadedImageURL: urlString,
                                                                                              syteJsonString: nil)
                                addedScreenshot.isNew = false //Always entered immediatly when added
                                
                                managedObjectContext.saveIfNeeded()
                                // download stye stuff for URL
                                AssetSyncModel.sharedInstance.syteProcessing(imageData: nil, orImageUrlString: urlString, assetId: urlString)

                                if let callback = callback {
                                    let addedScreenshotOID = addedScreenshot.objectID
                                    DispatchQueue.main.async {
                                        if let mainScreenshot = DataModel.sharedInstance.mainMoc().object(with: addedScreenshotOID) as? Screenshot {
                                            callback(mainScreenshot)
                                        }
                                        completion()
                                    }
                                }else{
                                    completion()
                                }
                            })
                        }else{
                            completion()
                        }
                    })
                }
            }
        }))
    }
    
    public func importPhotosToScreenshot(assets:[PHAsset], source:ScreenshotSource) {
        assets.forEach{ self.uploadPhoto(asset: $0, source: source) }
    }
    
    public func importImageFromCamera(image:UIImage) {
        let uuid = NSUUID.init().uuidString
        let assetId = "camera|\(uuid)"
        let largeImageData = UIImageJPEGRepresentation(image, 0.9)
        let smallImageData = self.data(for: image)
        self.userInitiatedQueue.addOperation(AsyncOperation.init(timeout: 15.0,  assetId: assetId, shoppableId: nil, completion: { (completeOperation) in
            self.performBackgroundTask(assetId: assetId, shoppableId: nil) { (managedObjectContext) in
                let now = Date()
                let screenshot = DataModel.sharedInstance.saveScreenshot(upsert: true, managedObjectContext: managedObjectContext, assetId: assetId, createdAt: now, isRecognized: true, source: .camera, isHidden: false, imageData: largeImageData, uploadedImageURL: nil, syteJsonString: nil)
                

                screenshot.isNew = true
                screenshot.lastModified = now

                managedObjectContext.saveIfNeeded()
                self.syteProcessing(imageData: smallImageData, orImageUrlString:nil, assetId: assetId)
                
                Analytics.trackCreatedPhoto()
            }
        }))
    }
    
    private func uploadPhoto(assetId: String, source: ScreenshotSource, photoPromise: Promise<UIImage>, creationDate: Date? = Date()) {
        self.userInitiatedQueue.addOperation(AsyncOperation.init(timeout: 5.0,  assetId: assetId, shoppableId: nil, completion: { (completeOperation) in
            AccumulatorModel.screenshot.removeAssetId(assetId)
            photoPromise
                .then(on: self.processingQ) { image -> Promise<(Data?, String?, String?)> in
                    Analytics.trackBypassedClarifai()
                    let imageData: Data? = self.data(for: image)
                    return Promise { fulfill, reject in
                        self.performBackgroundTask(assetId: assetId, shoppableId: nil) { (managedObjectContext) in
                            if let screenshot = managedObjectContext.screenshotWith(assetId: assetId) {
                                //this is retry screenshot
                                if let classification = screenshot.syteJson,
                                    classification.utf8.count == 1 { // Previously dual-purposed syteJson for imageClassification of "h" (human) or "f" (furniture)
                                    screenshot.syteJson = nil
                                }
                                let wasHidden = screenshot.isHidden
                                
                                if screenshot.shoppablesCount > 0 {
                                    screenshot.hideWorkhorse()
                                }
                                screenshot.shoppablesCount = 0
                                screenshot.imageData = imageData
                                screenshot.isHidden = false
                                screenshot.isRecognized = true
                                screenshot.lastModified = Date()
                                screenshot.source = source
                                screenshot.submittedDate = nil
                                screenshot.submittedFeedbackCount = 0
                                screenshot.submittedFeedbackCountDate = nil
                                screenshot.submittedFeedbackCountGoal = 0
                                screenshot.submittedFeedbackCountDate = nil
                                
                                managedObjectContext.saveIfNeeded()
                                if wasHidden {
                                    Analytics.trackScreenshotCreated(screenshot: screenshot)
                                }
                                fulfill((imageData, screenshot.uploadedImageURL, screenshot.syteJson))
                            }else{
                                let screenshot = Screenshot(context: managedObjectContext)
                                screenshot.assetId = assetId
                                screenshot.createdAt = creationDate
                                screenshot.isNew = true
                                screenshot.lastModified = creationDate
                                screenshot.isRecognized = true
                                screenshot.isHidden = false
                                screenshot.imageData = imageData
                                screenshot.source = source
                                
                                Analytics.trackScreenshotCreated(screenshot: screenshot)
                                
                                managedObjectContext.saveIfNeeded()
                                fulfill((imageData, nil, nil))
                            }
                        }
                    }
                }.then (on: self.processingQ) { imageData, uploadedImageURL, syteJsonString -> Promise<Bool> in
                    let syteJson: [[String : Any]]? = (syteJsonString == nil ? nil : NetworkingPromise.sharedInstance.jsonDestringify(string: syteJsonString!))
                    self.syteProcessing(imageData: imageData, orImageUrlString:nil, assetId: assetId, optionsMask: ProductsOptionsMask.global, gottenUploadedURLString: uploadedImageURL, gottenSegments: syteJson)
                    return Promise.init(value: true)
                }.catch { error in
                    print("uploadPhoto outer catch error:\(error)")
                }.always(on: self.serialQ) {
                    completeOperation()
            }
        }))
    }
    
    func uploadPhoto(imageUrlString: String, source: ScreenshotSource) {
        let promise = NetworkingPromise.sharedInstance.downloadImageData(urlString: imageUrlString)
            .then(on: self.processingQ) { imageData -> Promise<UIImage> in
                if let image = UIImage(data: imageData) {
                    return Promise(value: image)
                } else {
                    return Promise(error: NSError(domain: "Craze", code: 97, userInfo: [NSLocalizedDescriptionKey: "Failed resizing image data"]))
                }
        }
        uploadPhoto(assetId: imageUrlString, source: source, photoPromise: promise)
    }
    
    func uploadPhoto(asset: PHAsset, source:ScreenshotSource) {
        uploadPhoto(assetId: asset.localIdentifier, source: source, photoPromise: asset.image(allowFromICloud: true), creationDate: Date())
    }
    
    //From share
    public func downloadScreenshot(shareId: String) {
        self.userInitiatedQueue.addOperation(AsyncOperation.init(timeout: 20.0, completion: { (completeOperation) in
            let networkRequest:Promise<[String : Any]> = {
                // Get screenshot dict from Craze server.
                // See end https://docs.google.com/document/d/16WsJMepl0Z3YrsRKxcFqkASUieRLKy_Aei8lmbpD2bo
                guard let encoded = shareId.addingPercentEncoding(withAllowedCharacters: .alphanumerics),
                    let screenshotInfoUrl = URL(string: Constants.screenShotLambdaDomain + "shares/" + encoded) else {
                        let urlError = NSError(domain: "Craze", code: 8, userInfo: [NSLocalizedDescriptionKey : "Could not form URL from shareId:\(shareId)"])
                        return Promise(error: urlError)
                }
                return NetworkingPromise.sharedInstance.downloadInfo(url: screenshotInfoUrl)
            }()
            networkRequest.then(on: self.processingQ) { jsonDict -> Promise<(Data, [String : Any])> in
                // Download image from Syte S3.
                guard let share = jsonDict["share"] as? [String : Any],
                    let screenshotDict = share["screenshot"] as? [String : Any],
                    let imageURLString = screenshotDict["image"] as? String
                    else {
                        let imageURLError = NSError(domain: "Craze", code: 9, userInfo: [NSLocalizedDescriptionKey : "Could not form image URL from jsonDict:\(jsonDict)"])
                        return Promise(error: imageURLError)
                }
                return when(fulfilled:  NetworkingPromise.sharedInstance.downloadImageData(urlString: imageURLString), Promise.init(value: screenshotDict))
                }.then(on: self.processingQ) { (imageData, screenshotDict) -> Promise< [String : Any]> in
                    return Promise(resolvers: { (fulfil, reject) in
                        self.performBackgroundTask(assetId: shareId, shoppableId: nil) { (context) in
                            let _ = DataModel.sharedInstance.saveScreenshot(upsert: true,
                                                                            managedObjectContext: context,
                                                                            assetId: shareId,
                                                                            createdAt: Date(),
                                                                            isRecognized: true,
                                                                            source: .share,
                                                                            isHidden: false,
                                                                            imageData: imageData,
                                                                            uploadedImageURL: nil,
                                                                            syteJsonString: nil)
                            context.saveIfNeeded()
                            fulfil(screenshotDict)
                        }
                    })
                }.then(on: self.processingQ) { screenshotDict -> Void in
                    // Save shoppables to db.
                    guard let syteJsonString = screenshotDict["syteJson"] as? String,
                        let segments = NetworkingPromise.sharedInstance.jsonDestringify(string: syteJsonString),
                        let imageURLString = screenshotDict["image"] as? String else {
                            let jsonError = NSError(domain: "Craze", code: 10, userInfo: [NSLocalizedDescriptionKey : "Could not extract syteJson from screenshotDict:\(screenshotDict)"])
                            print(jsonError)
                            return
                    }
                    self.saveShoppables(assetId: shareId, uploadedURLString: imageURLString, segments: segments)
                }.catch { error in
                    print("downloadScreenshot catch error:\(error)")
                }.always(on: self.serialQ) {
                    completeOperation()
            }
        }))
    }
}

//Background image processing
extension AssetSyncModel: PHPhotoLibraryChangeObserver {
    func updatePhotoGalleryFetch() {
        let fetchOptions = PHFetchOptions()
        let cutOffDate = DataModel.sharedInstance.cutOffDate()
        
        fetchOptions.predicate = NSPredicate(format: "creationDate > %@ AND (mediaSubtype & %d) != 0", cutOffDate, PHAssetMediaSubtype.photoScreenshot.rawValue)
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 25
        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        self.backgroundProcessFetchedResults = assets
        registerForPhotoChanges()  //just in case we got permissions since init
    }
    
    @objc func scanPhotoGalleryForFashion() {
        guard PermissionsManager.shared.hasPermission(for: .photo),
          UserDefaults.standard.bool(forKey: UserDefaultsKeys.gdpr_agreedToImageDetection) else {
            return
        }
        
        updatePhotoGalleryFetch()
        
        if let assets = self.backgroundProcessFetchedResults {
            var assetIds = Set<String>()
            assets.enumerateObjects({ (asset: PHAsset, index: Int, stop: UnsafeMutablePointer<ObjCBool>) in
                assetIds.insert(asset.localIdentifier)
            })
            let startedInBackground = ApplicationStateModel.sharedInstance.isBackground()
            self.performBackgroundTask(assetId: nil, shoppableId: nil) { (context) in
                let dbSet = DataModel.sharedInstance.retrieveAssetIds(assetIds:Array(assetIds), managedObjectContext: context)
                assetIds.subtract(dbSet)
                assets.enumerateObjects(options: [.reverse], using: { (asset: PHAsset, index: Int, stop: UnsafeMutablePointer<ObjCBool>) in
                    if assetIds.contains(asset.localIdentifier) {
                        self.uploadScreenshotWithClarifai(asset: asset, startedInBackground:startedInBackground )
                    }
                })
            }
            
        }
    }
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let backgroundProcessFetchedResults = self.backgroundProcessFetchedResults else {
            //huh?
            print("photoLibraryDidChange ignored - no fetch results")
            return
        }
        
        if let change = changeInstance.changeDetails(for: backgroundProcessFetchedResults), change.hasIncrementalChanges {
            if isNextScreenshotForeground {
                if let asset = change.insertedObjects.last {
                    self.foregroundScreenshotAssetIds.insert(asset.localIdentifier)
                    isNextScreenshotForeground = false
                }
            }
            change.insertedObjects.forEach({ (asset) in
                var isOld = false
                if let dateCreated = asset.creationDate, let lastDidBecomeActiveDate = self.lastDidBecomeActiveDate {
                    if dateCreated < lastDidBecomeActiveDate {
                        isOld = true
                    }
                }
                if !isOld{
                    self.userJustTookScreenshotAssetIds.insert(asset.localIdentifier)
                    self.uploadScreenshotWithClarifaiFromUserScreenshotAction(asset:asset)
                }
            })
            updatePhotoGalleryFetch()
        }
    }
    
    
    func registerForPhotoChanges() {
        guard PermissionsManager.shared.hasPermission(for: .photo),
          UserDefaults.standard.bool(forKey: UserDefaultsKeys.gdpr_agreedToImageDetection) else {
            return
        }
        if isRegistered == false {
            PHPhotoLibrary.shared().register(self)
            isRegistered = true
        }
    }
    
    @objc func applicationUserDidTakeScreenshot() {
        isNextScreenshotForeground = ApplicationStateModel.sharedInstance.isActive()
    }
    
    
    func uploadScreenshotWithClarifaiFromUserScreenshotAction(asset: PHAsset) {
        let isForeground = self.foregroundScreenshotAssetIds.contains(asset.localIdentifier)
        self.foregroundScreenshotAssetIds.remove(asset.localIdentifier)
        guard !isForeground else {
            return
        }
        var imageData: Data?
        self.uploadScreenshotWithClarifaiQueueFromUserScreenshot.addOperation(AsyncOperation.init(timeout: 20.0,  assetId: asset.localIdentifier, shoppableId: nil, completion: { (completeOperation) in
            Promise.init { fulfill, reject in
                self.performBackgroundTask(assetId: asset.localIdentifier, shoppableId: nil) { (managedObjectContext) in
                    if let _ = managedObjectContext.screenshotWith(assetId: asset.localIdentifier) {
                        //do nothing if already exsists
                        let error = NSError.init(domain: "Craze", code: -90, userInfo: [NSLocalizedDescriptionKey:"already have screenshot in database"])
                        reject(error)
                    }else{
                        fulfill(())
                    }
                }
            }.then (on: self.processingQ)  { () -> (Promise<UIImage>) in
                return asset.image(allowFromICloud: false)
            }.then (on: self.processingQ) { image -> Promise<(String, [[String : Any]])> in
                Analytics.trackSentImageToClarifai()
                //                return ClarifaiModel.sharedInstance.classify(image: image).then(execute: { (c) -> Promise<(ClarifaiModel.ImageClassification, UIImage)>  in
                //                    return Promise.init(value: (c, image))
                //                })
                imageData = self.data(for: image)
                return NetworkingPromise.sharedInstance.uploadToSyte(imageData: imageData, orImageUrlString: nil, retry:false)
                }.then(on: self.processingQ) { uploadedImageURL, syteJson -> Promise<(Data?, String, [[String : Any]])> in
                    let isRecognized = true
                    Analytics.trackReceivedResponseFromClarifai(isFashion: true, isFurniture: false)
                    return Promise { fulfill, reject in
                        self.performBackgroundTask(assetId: asset.localIdentifier, shoppableId: nil) { (managedObjectContext) in
                            if let _ = managedObjectContext.screenshotWith(assetId: asset.localIdentifier) {
                                //do nothing if already exsists
                                let error = NSError.init(domain: "Craze", code: -90, userInfo: [NSLocalizedDescriptionKey:"already have screenshot in database"])
                                reject(error)
                            }else{
                                let syteJsonString = NetworkingPromise.sharedInstance.jsonStringify(object: syteJson)
                                let _ = DataModel.sharedInstance.saveScreenshot(upsert: false,
                                                                                managedObjectContext: managedObjectContext,
                                                                                assetId: asset.localIdentifier,
                                                                                createdAt: asset.creationDate,
                                                                                isRecognized: isRecognized,
                                                                                source: .screenshot,
                                                                                isHidden: true,
                                                                                imageData: imageData,
                                                                                uploadedImageURL: uploadedImageURL,
                                                                                syteJsonString: syteJsonString)
                                
                                managedObjectContext.saveIfNeeded()
                                
                                fulfill((imageData, uploadedImageURL, syteJson))
                            }
                        }
                        
                    }
                }.then (on: self.processingQ) { imageData, gottenUploadedURLString, gottenSegments -> Void in
                    if let lastDidBecomeActiveDate = self.lastDidBecomeActiveDate, let creationDate = asset.creationDate,  creationDate.timeIntervalSince(lastDidBecomeActiveDate) > -60.0 && ApplicationStateModel.sharedInstance.isActive(){
                        self.uploadPhoto(asset: asset, source: .screenshot)
                    }else{
                        // Screenshot taken while app in background (or killed)
                        AccumulatorModel.screenshot.addAssetId(asset.localIdentifier)
                        AccumulatorModel.screenshotUninformed.incrementUninformedCount()
                        if  ApplicationStateModel.sharedInstance.isBackground() {
                            DispatchQueue.main.async {
                                // The accumulator updates the count in an async block.
                                // Without a delay the count is wrong when setting the content.badge.
                                LocalNotificationModel.shared.sendScreenshotAddedLocalNotification(assetId: asset.localIdentifier, imageData: imageData)
                            }
                        }
                    }
                }.catch { error in
                    print("uploadScreenshotWithClarifai catch error:\(error)")
                }.always(on: self.serialQ) {
                    completeOperation()
            }
        }))
    }
    
    func uploadScreenshotWithClarifai(asset: PHAsset, startedInBackground:Bool) {
        let isScreenshotUserJustTook = self.userJustTookScreenshotAssetIds.contains(asset.localIdentifier)
        if isScreenshotUserJustTook {
            return // processed by other function
        }
        var imageData: Data?
        self.uploadScreenshotWithClarifaiQueue.addOperation(AsyncOperation(timeout: 20.0, assetId: asset.localIdentifier, shoppableId: nil, completion: { (completeOperation) in
            
            
            firstly{ () -> Promise<Void> in
                if !isScreenshotUserJustTook {
                    if let date = asset.creationDate {
                        if let currentValue = UserDefaults.standard.value(forKey: UserDefaultsKeys.processBackgroundImagesForFashionAfterDate) as? Date {
                            if date < currentValue {
                                let error = NSError.init(domain: "Craze", code: -81, userInfo: [NSLocalizedDescriptionKey : "asset is too old to process"])
                                throw error
                            }
                        }
                    }
                    if AccumulatorModel.screenshot.newCount > Constants.notificationProductToImportCountLimit && !self.shouldSendPushWhenFindFashionWithoutUserScreenshotAction {
                        let error = NSError.init(domain: "Craze", code: -82, userInfo: [NSLocalizedDescriptionKey : "already have enough images"])
                        throw error
                    }
                }
                return Promise.init(value: ())
                }.then(on: self.processingQ) { success -> Promise<Void> in
                   return Promise.init { fulfill, reject in
                        self.performBackgroundTask(assetId: asset.localIdentifier, shoppableId: nil) { (managedObjectContext) in
                            if let _ = managedObjectContext.screenshotWith(assetId: asset.localIdentifier) {
                                //do nothing if already exsists
                                let error = NSError.init(domain: "Craze", code: -90, userInfo: [NSLocalizedDescriptionKey:"already have screenshot in database"])
                                reject(error)
                            }else{
                                fulfill(())
                            }
                        }
                    }
                }.then(on: self.processingQ) { () -> Promise<UIImage> in
                    return asset.image(allowFromICloud: false)
                }.then (on: self.processingQ) { image -> Promise<(String, [[String : Any]])> in
                    Analytics.trackSentImageToClarifai()
                    //                return ClarifaiModel.sharedInstance.classify(image: image).then(execute: { (c) -> Promise<(ClarifaiModel.ImageClassification, UIImage)>  in
                    //                    return Promise.init(value: (c, image))
                    //                })
                    imageData = self.data(for: image)
                    return NetworkingPromise.sharedInstance.uploadToSyte(imageData: imageData, orImageUrlString: nil, retry:false)
                }.then (on: self.processingQ) { args -> Promise<Bool> in
                    let (uploadedImageUrl, json) = args
                    // Store screenshot and syteJson to DB.
                    return Promise { fulfill, reject in
                        self.performBackgroundTask(assetId: asset.localIdentifier, shoppableId: nil) { (managedObjectContext) in
                            if let _ = managedObjectContext.screenshotWith(assetId: asset.localIdentifier) {
                                //do nothing if already exsists
                                let error = NSError.init(domain: "Craze", code: -90, userInfo: [NSLocalizedDescriptionKey:"already have screenshot in database"])
                                reject(error)
                            } else {
                                let syteJsonString = NetworkingPromise.sharedInstance.jsonStringify(object: json)
                                let _ = DataModel.sharedInstance.saveScreenshot(upsert: false,
                                                                                managedObjectContext: managedObjectContext,
                                                                                assetId: asset.localIdentifier,
                                                                                createdAt: asset.creationDate,
                                                                                isRecognized: true,
                                                                                source: .screenshot,
                                                                                isHidden: true,
                                                                                imageData: imageData,
                                                                                uploadedImageURL: uploadedImageUrl,
                                                                                syteJsonString: syteJsonString)
                                managedObjectContext.saveIfNeeded()
                                fulfill(true)
                            }
                        }
                    }
                }.then(on: self.processingQ) { aBool -> Void in
                    self.performBackgroundTask(assetId: nil, shoppableId: nil) { (managedObjectContext) in
                        if let _ = managedObjectContext.screenshotWith(assetId: asset.localIdentifier) {
                            
                            if let lastDidBecomeActiveDate = self.lastDidBecomeActiveDate, let creationDate = asset.creationDate,  creationDate.timeIntervalSince(lastDidBecomeActiveDate) > -60.0 && ApplicationStateModel.sharedInstance.isActive(){
                                self.uploadPhoto(asset: asset, source: .screenshot)
                            }else{
                                AccumulatorModel.screenshot.addAssetId(asset.localIdentifier)
                                AccumulatorModel.screenshotUninformed.incrementUninformedCount()
                                if self.shouldSendPushWhenFindFashionWithoutUserScreenshotAction && ApplicationStateModel.sharedInstance.isBackground(){
                                    self.processingQ.async {
                                        if self.shouldSendPushWhenFindFashionWithoutUserScreenshotAction && ApplicationStateModel.sharedInstance.isBackground(){  //need to check twice due to async craziness
                                            self.shouldSendPushWhenFindFashionWithoutUserScreenshotAction = false
                                            LocalNotificationModel.shared.sendScreenshotAddedLocalNotification(assetId: asset.localIdentifier, imageData: imageData)
                                        }
                                    }
                                }
                            }
                            
                            
                        }
                    }
                }.catch { error in
                    print("uploadScreenshotWithClarifai catch error:\(error)")
                }.always(on: self.serialQ) {
                    if let date = asset.creationDate {
                        let currentValue = UserDefaults.standard.value(forKey: UserDefaultsKeys.processBackgroundImagesForFashionAfterDate) as? Date ?? Date.distantPast
                        if currentValue < date {
                            UserDefaults.standard.setValue(date, forKey: UserDefaultsKeys.processBackgroundImagesForFashionAfterDate)
                        }
                    }
                    completeOperation()
            }
        }))
    }
    
    
}

extension AssetSyncModel {
    
    
    func resaveScreenshot(assetId: String, imageData: Data?) -> Promise<Data?> {
        let dataModel = DataModel.sharedInstance
        return Promise { fulfill, reject in
            self.performBackgroundTask(assetId: nil, shoppableId: nil) { (managedObjectContext) in
                if let screenshot = dataModel.retrieveScreenshot(managedObjectContext: managedObjectContext, assetId: assetId) {
                    if let classification = screenshot.syteJson,
                        classification.utf8.count == 1 { // Previously dual-purposed syteJson for imageClassification of "h" (human) or "f" (furniture)
                        screenshot.syteJson = nil
                    }
                    let wasHidden  = screenshot.isHidden
                    if screenshot.shoppablesCount > 0 {
                        screenshot.hideWorkhorse()
                    }
                    screenshot.shoppablesCount = 0
                    screenshot.imageData = imageData
                    screenshot.isHidden = false
                    screenshot.isRecognized = true
                    screenshot.lastModified = Date()
                    managedObjectContext.saveIfNeeded()
                    if wasHidden {
                        Analytics.trackScreenshotCreated(screenshot: screenshot)
                    }
                    fulfill(imageData)
                } else {
                    let error = NSError(domain: "Craze", code: 18, userInfo: [NSLocalizedDescriptionKey : "Could not retreive screenshot with assetId:\(assetId)"])
                    reject(error)
                }
            }
        }
    }
    
    func rescanClassification(assetId: String, imageData: Data?, optionsMask: ProductsOptionsMask = ProductsOptionsMask.global) {
        Analytics.trackBypassedClarifaiOnRetry()
        self.userInitiatedQueue.addOperation(AsyncOperation.init(timeout: 90, assetId: assetId, shoppableId: nil, completion: { (completion) in
            firstly {
                self.resaveScreenshot(assetId: assetId, imageData: imageData)
                }.then (on: self.processingQ) { imageData -> Void in
                    return self.syteProcessing(imageData: imageData, orImageUrlString:nil, assetId: assetId, optionsMask: optionsMask)
                }.catch { error in
                    print("rescanClassification catch error:\(error)")
                }.always {
                    completion()
            }
            
        }))
    }
    
    func syteProcessing(imageData: Data?,
                        orImageUrlString:String?,
                        assetId: String,
                        optionsMask: ProductsOptionsMask = ProductsOptionsMask.global,
                        gottenUploadedURLString: String? = nil,
                        gottenSegments: [[String : Any]]? = nil) {
        let localImageData: Data?
        if assetId.hasPrefix("shamrock"), let imageData = imageData, let image = UIImage.init(data: imageData), let image2 = image.shamrock(), let data = self.data(for: image2) {
            localImageData = data
        } else {
            localImageData = imageData
        }
        
        let count = AsyncOperationMonitorCenter.shared.countFor(tag: AsyncOperationTag.init(type: .assetId, value: assetId), queue: self.syteProcessingQueue.uuid)
        if count > 0 {
            return
        }
        
        DispatchQueue.main.async {
            self.networkingIndicatorDelegate?.networkingIndicatorDidStart(type: .Product)
        }
        self.syteProcessingQueue.addOperation(AsyncOperation(timeout: 90, assetId: assetId, shoppableId: nil, completion: { (completion) in
            Promise<(Data?, String?)>.init(resolvers: { (fulfil, reject) in
                if let data = localImageData {
                    UserAccountManager.shared.uploadImage(data: data).then(execute: { (url) -> () in
                        fulfil((nil, url.absoluteString))
                    }).catch{error in
                        //If the firebase upload fails, still try to upload it via syte
                        fulfil((data, orImageUrlString))
                    }
                }else {
                    fulfil((localImageData, orImageUrlString))
                }
            }).then(on: self.processingQ) { (arg) -> Promise<(String, [[String : Any]])> in
                
                let (localImageData, orImageUrlString) = arg
                return (gottenUploadedURLString != nil && gottenSegments != nil) ? Promise(value: (gottenUploadedURLString!, gottenSegments!)) : NetworkingPromise.sharedInstance.uploadToSyte(imageData: localImageData, orImageUrlString:orImageUrlString, retry:true)
                
                }.then(on: self.processingQ) { uploadedURLString, segments -> Void in
                    let categoriesArray = segments.map({ (segment: [String : Any]) -> String? in segment["label"] as? String}).compactMap({$0})
                    let categories = categoriesArray.joined(separator: ",")
                    
                    Analytics.trackReceivedResponseFromSyte(imageUrl: uploadedURLString, segmentCount: segments.count, categories: categories)
                    
                    DataModel.sharedInstance.performBackgroundTask({ (context) in
                        guard let screenshot = context.screenshotWith(assetId: assetId) else {
                            return
                        }
                        categoriesArray.forEach({ category in
                            Analytics.trackScreenshotCreatedPerCategory(screenshot: screenshot, category: category)
                        })
                    })
                    
                    #if STORE_NEW_TUTORIAL_SCREENSHOT

                    print("uploadedURLString:\(uploadedURLString)\nsegments:\(segments)")
                    #endif
                    self.saveShoppables(assetId: assetId, uploadedURLString: uploadedURLString, segments: segments, optionsMask: optionsMask)
                }.catch { error in
                    let nsError = error as NSError
                    if nsError.domain == "Craze" {
                        switch nsError.code {
                        case 3, 4, 22:
                            // Syte returned no segments
                            print("Syte returned no segments:\(error)")
                        default:
                            break
                        }
                    }
                    let uploadedURLString = nsError.userInfo[NSURLErrorFailingURLStringErrorKey] as? String
                    let imageUrl: String = uploadedURLString ?? orImageUrlString ?? gottenUploadedURLString ?? ""
                    DataModel.sharedInstance.setNoShoppables(assetId: assetId, uploadedURLString: uploadedURLString)
                    Analytics.trackReceivedResponseFromSyte(imageUrl: imageUrl, segmentCount: 0, categories: nil)
                    if let e = error as? PMKURLError {
                        Analytics.trackError(type: nil, domain: nsError.domain, code: nsError.code, localizedDescription: e.errorDescription)
                    }else{
                        Analytics.trackError(type: nil, domain: nsError.domain, code: nsError.code, localizedDescription: nsError.localizedDescription)
                    }
                    
                    
                    print("uploadScreenshot inner uploadToSyte catch error:\(error)")
                }.always {
                    self.networkingIndicatorDelegate?.networkingIndicatorDidComplete(type: .Product)
                    completion()
            }
            
        }))
    }
    
    func augmentedUrl(offersURL: String, optionsMask: ProductsOptionsMask) -> URL? {
        guard var components = URLComponents(string: offersURL) else {
            return nil
        }
        if components.scheme == nil || !components.scheme!.hasPrefix("http") {
            components.scheme = "https"
        }
        // Strip out any existing currency, feed or gender query parameters.
        let filterOutNames = Set<String>(arrayLiteral: "currency", "feed", "gender")
        var fixedQueryitems: [URLQueryItem] = components.queryItems?.filter { !filterOutNames.contains($0.name) } ?? []
        let isChild = optionsMask.rawValue & ProductsOptionsMask.sizeChild.rawValue > 0
        let isPlus = optionsMask.rawValue & ProductsOptionsMask.sizePlus.rawValue > 0
        if let productCurrency = UserDefaults.standard.string(forKey: UserDefaultsKeys.productCurrency),
            (!productCurrency.isEmpty && productCurrency != CurrencyMap.autoCode) {
            fixedQueryitems.append(URLQueryItem(name: "force_currency", value: productCurrency))
        }
       
        let sizeValue = isPlus ? "craze_plus_size" : isChild ? "kids_craze" : Constants.syteFeed
        fixedQueryitems.append(URLQueryItem(name: "feed", value: sizeValue))
        if optionsMask.rawValue & ProductsOptionsMask.genderMale.rawValue > 0 {
            fixedQueryitems.append(URLQueryItem(name: "force_gender", value: isChild ? "boy" : "male"))
        } else if optionsMask.rawValue & ProductsOptionsMask.genderFemale.rawValue > 0 {
            fixedQueryitems.append(URLQueryItem(name: "force_gender", value: isChild ? "girl" : "female"))
        }
        components.queryItems = fixedQueryitems
        return components.url
    }
    
    func saveShoppables(assetId: String, uploadedURLString: String, segments: [[String : Any]], optionsMask: ProductsOptionsMask = ProductsOptionsMask.global) { //-> Promise<[String]> {
        let dataModel = DataModel.sharedInstance
        self.performBackgroundTask(assetId: assetId, shoppableId: nil) { (managedObjectContext) in
            guard let screenshot = dataModel.retrieveScreenshot(managedObjectContext: managedObjectContext, assetId: assetId) else {
                print("AssetSyncModel saveShoppables error retreiving screenshot:\(assetId) to which to add shoppable and products")
                return
            }
            for segment in segments {
                guard let offersURL = segment["offers"] as? String,
                    let b0 = segment["b0"] as? [Any],
                    b0.count >= 2,
                    let b1 = segment["b1"] as? [Any],
                    b1.count >= 2,
                    let b0x = b0[0] as? Double,
                    let b0y = b0[1] as? Double,
                    let b1x = b1[0] as? Double,
                    let b1y = b1[1] as? Double else {
                        print("AssetSyncModel error parsing offers, b0, b1")
                        continue
                }
                let relatedImagesURL = segment["related_looks"] as? String
                let label = segment["label"] as? String
                let _ = dataModel.saveShoppable(managedObjectContext: managedObjectContext,
                                                screenshot: screenshot,
                                                label: label,
                                                offersURL: offersURL,
                                                relatedImagesURL: relatedImagesURL,
                                                b0x: b0x,
                                                b0y: b0y,
                                                b1x: b1x,
                                                b1y: b1y,
                                                optionsMask: optionsMask)
                screenshot.shoppablesCount += 1
                if screenshot.shoppablesCount == 1 {
                    screenshot.syteJson = NetworkingPromise.sharedInstance.jsonStringify(object: segments)
                    screenshot.uploadedImageURL = uploadedURLString
                    UserAccountManager.shared.uploadScreenshots(screenshot: screenshot)
                }
            }
            for segment in segments {
                if let offersURL = segment["offers"] as? String,
                    let url = self.augmentedUrl(offersURL: offersURL, optionsMask: optionsMask) {
                    self.extractProducts(assetId: assetId,
                                         offersURL: offersURL,
                                         url: url,
                                         optionsMask: optionsMask)
                } else {
                    print("AssetSyncModel saveShoppables error forming augmentedUrl for shoppable offersURL:\(String(describing: segment["offers"]))")
                }
            }
            managedObjectContext.saveIfNeeded()

        }
    }
    
    func calcFallbackPrice(originalData: [String : Any]) -> Float {
        let parseFloat: (Any?) -> Float? = DataModel.sharedInstance.parseFloat
        return parseFloat(originalData["price"]) ?? parseFloat(originalData["sale_price"]) ?? parseFloat(originalData["discount_price"]) ?? parseFloat(originalData["retail_price"]) ?? 0
    }
    
    func saveProduct(managedObjectContext: NSManagedObjectContext,
                     shoppable: Shoppable,
                     productOrder: Int16,
                     prod: [String : Any],
                     optionsMask: Int32) {
        let dataModel = DataModel.sharedInstance
        let extractedCategories = prod["categories"] as? [String]
        var fallbackPrice: Float = 0
        var partNumber: String? = nil
        var id: String? = nil
        var color: String? = nil
        var sku: String? = nil
        if let originalData = prod["original_data"] as? [String : Any] {
            fallbackPrice = calcFallbackPrice(originalData: originalData)
            partNumber = originalData["part_number"] as? String
            id = originalData["Product ID"] as? String ?? originalData["sku"] as? String ?? originalData["merchant_product_id"] as? String
            color = originalData["color"] as? String
            sku = originalData["id"] as? String
        }
        let _ = dataModel.saveProduct(managedObjectContext: managedObjectContext,
                                      shoppable: shoppable,
                                      order: productOrder,
                                      productDescription: prod["description"] as? String,
                                      price: prod["price"] as? String,
                                      originalPrice: prod["originalPrice"] as? String,
                                      floatPrice: dataModel.parseFloat(prod["floatPrice"]) ?? 0,
                                      floatOriginalPrice: dataModel.parseFloat(prod["floatOriginalPrice"]) ?? 0,
                                      categories: extractedCategories?.first,
                                      brand: prod["brand"] as? String,
                                      offer: prod["offer"] as? String,
                                      imageURL: prod["imageUrl"] as? String,
                                      merchant: prod["merchant"] as? String,
                                      partNumber: partNumber,
                                      id: id,
                                      color: color,
                                      sku: sku,
                                      fallbackPrice: fallbackPrice,
                                      optionsMask: optionsMask)
    }
    
    func embeddedSaveShoppableWithProducts(assetId: String,
                                           offersURL: String,
                                           optionsMask: ProductsOptionsMask,
                                           productsArray: [[String : Any]]) {
        let dataModel = DataModel.sharedInstance
        self.performBackgroundTask(assetId: assetId, shoppableId: offersURL) { (managedObjectContext) in
            guard let screenshot = dataModel.retrieveScreenshot(managedObjectContext: managedObjectContext, assetId: assetId),
                let shoppablesSet = screenshot.shoppables as? Set<Shoppable>,
                let shoppable = shoppablesSet.first(where: { $0.offersURL == offersURL }) else {
                    print("AssetSyncModel embeddedSaveShoppableWithProducts error retreiving screenshot:\(assetId) shoppable:\(offersURL) to which to add products")
                    return
            }
            var productOrder: Int16 = 0
            for prod in productsArray {
                self.saveProduct(managedObjectContext: managedObjectContext,
                                 shoppable: shoppable,
                                 productOrder: productOrder,
                                 prod: prod,
                                 optionsMask: Int32(optionsMask.rawValue))
                productOrder += 1
            }
            shoppable.productCount = productOrder
            if productOrder == 0 {
                productOrder = -1
            }
            shoppable.productFilterCount = productOrder
            if let productFilter = shoppable.productFilters?.anyObject() as? ProductFilter {
                productFilter.productCount = productOrder
            } else {
                print("AssetSyncModel extractProducts no productFilter, productCount:\(productOrder)")
            }
            managedObjectContext.saveIfNeeded()
        }
        Analytics.trackReceivedProductsFromSyte(productCount: productsArray.count, optionsMask: optionsMask.rawValue)
    }
    
    func extractProducts(assetId: String,
                         offersURL: String,
                         url: URL,
                         optionsMask: ProductsOptionsMask) {
        self.downloadProductQueue.addOperation(AsyncOperation.init(timeout: 90, assetId: assetId, shoppableId: offersURL, completion: { (completion) in
            NetworkingPromise.sharedInstance.downloadProductsWithRetry(url: url)
                .then(on: self.processingQ) { productsDict -> Void in
                    if let adsArray = productsDict["ads"] as? [[String : Any]],
                        adsArray.count > 0 {
                        self.embeddedSaveShoppableWithProducts(assetId: assetId, offersURL: offersURL, optionsMask: optionsMask, productsArray: adsArray)
                    } else {
                        print("AssetSyncModel extractProducts no products in ads, when NetworkPromise checks. productsDict:\(productsDict)")
                        self.embeddedSaveShoppableWithProducts(assetId: assetId, offersURL: offersURL, optionsMask: optionsMask, productsArray: [])
                    }
                }.catch { error in
                    print("AssetSyncModel extractProducts parsing products error:\(error)")
                    self.embeddedSaveShoppableWithProducts(assetId: assetId, offersURL: offersURL, optionsMask: optionsMask, productsArray: [])
                }.always {
                    completion()
            }
        }))
    }
    
    func updateShoppableWithProducts(assetId:String?,
                                     shoppableOfferURL:String,
                                     shoppableId: NSManagedObjectID,
                                     optionsMask32: Int32,
                                     productsArray: [[String : Any]]) {
        let dataModel = DataModel.sharedInstance
        self.performBackgroundTask(assetId: assetId, shoppableId: shoppableOfferURL) { (managedObjectContext) in
            guard let shoppable = dataModel.retrieveShoppable(managedObjectContext: managedObjectContext, objectId: shoppableId) else {
                print("AssetSyncModel reExtractProducts error retreiving shoppable:\(shoppableId) to which to add products")
                return
            }
            var addedProductCount: Int16 = 0
            var existingProductCount: Int16 = 0
            let existingProducts = shoppable.products as? Set<Product>
            for prod in productsArray {
                let offer = prod["offer"] as? String
                if let identicalProduct = existingProducts?.filter({ $0.offer == offer }).first {
                    identicalProduct.optionsMask |= optionsMask32
                    existingProductCount += 1
                    continue
                }
                self.saveProduct(managedObjectContext: managedObjectContext,
                                 shoppable: shoppable,
                                 productOrder: shoppable.productCount + addedProductCount,
                                 prod: prod,
                                 optionsMask: optionsMask32)
                addedProductCount += 1
            }
            shoppable.productCount += addedProductCount
            var changedProductCount = addedProductCount + existingProductCount
            if changedProductCount == 0 {
                changedProductCount = -1
            }
            shoppable.productFilterCount = changedProductCount
            if let productFilter = shoppable.productFilters?.filtered(using: NSPredicate(format: "optionsMask == %d", optionsMask32)).first as? ProductFilter {
                productFilter.productCount = changedProductCount
            } else {
                print("AssetSyncModel reExtractProducts no productFilter, changedProductCount:\(changedProductCount)")
            }
            managedObjectContext.saveIfNeeded()
        }
    }
    
    func reExtractProducts(assetId:String?,
                           shoppableId: NSManagedObjectID,
                           optionsMask: ProductsOptionsMask,
                           offersURL: String) {
        let optionsMask32 = Int32(optionsMask.rawValue)
        guard let url = augmentedUrl(offersURL: offersURL, optionsMask: optionsMask) else {
            print("AssetSyncModel reExtractProducts no url from offersURL:\(offersURL)")
            updateShoppableWithProducts(assetId:assetId, shoppableOfferURL:offersURL, shoppableId: shoppableId, optionsMask32: optionsMask32, productsArray: [])
            return
        }
        self.downloadProductQueue.addOperation(AsyncOperation.init(timeout: 90, assetId: nil, shoppableId: offersURL, completion: { (completion) in
            NetworkingPromise.sharedInstance.downloadProductsWithRetry(url: url)
                .then(on: self.processingQ) { productsDict -> Void in
                    if let productsArray = productsDict["ads"] as? [[String : Any]], productsArray.count > 0 {
                        self.updateShoppableWithProducts(assetId:assetId,shoppableOfferURL:offersURL, shoppableId: shoppableId, optionsMask32: optionsMask32, productsArray: productsArray)
                    } else {
                        print("AssetSyncModel reExtractProducts no products in ads. productsDict:\(productsDict)")
                        self.updateShoppableWithProducts(assetId:assetId, shoppableOfferURL:offersURL, shoppableId: shoppableId, optionsMask32: optionsMask32, productsArray: [])
                    }
                }.catch { error in
                    print("AssetSyncModel reExtractProducts error parsing product:\(error)")
                    self.updateShoppableWithProducts(assetId:assetId, shoppableOfferURL:offersURL, shoppableId: shoppableId, optionsMask32: optionsMask32, productsArray: [])
                }.always {
                    completion()
            }
        }))
        
    }
    
    public func refetchShoppables(screenshot: Screenshot) {
        guard let assetId = screenshot.assetId else {
            return
        }
        
        let oid = screenshot.objectID
        self.performBackgroundTask(assetId: screenshot.assetId, shoppableId: nil) { (managedObjectContext) in
            let backgroundScreenshot = managedObjectContext.object(with: oid) as? Screenshot
            backgroundScreenshot?.syteJson = nil
            backgroundScreenshot?.shoppables?.forEach { shoppable in
                if let shoppableManagedObject = shoppable as? NSManagedObject {
                    managedObjectContext.delete(shoppableManagedObject)
                } else {
                    print("WTF? Cannot cast as NSManagedObject:\(shoppable)")
                }
            }
            backgroundScreenshot?.shoppablesCount = 0
            managedObjectContext.saveIfNeeded()
            
            self.syteProcessing(imageData: backgroundScreenshot?.imageData, orImageUrlString: backgroundScreenshot?.uploadedImageURL, assetId: assetId)
        }
    }
    
    //Return the subshoppable (on the main thread) BEFORE the network requests are made on
    public func reloadSubShoppable(shoppable:Shoppable) -> Promise<Shoppable> {
        let productImageUrl = shoppable.imageUrl
        let mask = (shoppable.productFilters?.anyObject() as? ProductFilter)?.optionsMask
        let optionsMask:ProductsOptionsMask = {
            if let mask = mask {
                return ProductsOptionsMask.init(rawValue:Int(mask))
            }else{
                return ProductsOptionsMask.global
            }
        }()
        return self.addSubShoppable(productImageUrl: productImageUrl, label:shoppable.label, shoppable: shoppable, optionsMask: optionsMask)
        
    }
    public func addSubShoppable(fromProduct:Product) -> Promise<Shoppable> {
        let productImageUrl = fromProduct.imageURL
        let shoppable = fromProduct.shoppable
        let optionsMask = ProductsOptionsMask.init(rawValue: Int(fromProduct.optionsMask))
        let label = shoppable?.label ?? fromProduct.label ?? fromProduct.categories
        return self.addSubShoppable(productImageUrl: productImageUrl, label:label, shoppable: shoppable, optionsMask: optionsMask)
    }
    
    public func clearSubShoppables(screenshot:Screenshot) {
        let objectId = screenshot.objectID
        DataModel.sharedInstance.performBackgroundTask { (context) in
            if let screenshot = context.screenshotWith(objectId: objectId) {
                var objectsToDelete:[NSManagedObject] = []
                var productsToNilOutShoppable:[Product] = []
                screenshot.shoppables?.forEach({ (shoppable) in
                    if let shoppable = shoppable as? Shoppable {
                        if let _ = shoppable.parentShoppable {
                            objectsToDelete.append(shoppable)
                            shoppable.products?.forEach({ (product) in
                                if let product = product as? Product {
                                    if product.isFavorite {
                                        product.screenshot = shoppable.screenshot
                                        productsToNilOutShoppable.append(product)
                                    }else{
                                        objectsToDelete.append(product)
                                    }
                                }
                            })
                        }
                    }
                })
                productsToNilOutShoppable.forEach({ $0.shoppable = nil })
                objectsToDelete.forEach({ (object) in
                    context.delete(object)
                })
                context.saveIfNeeded()
            }
        }
    }
    private func addSubShoppable(productImageUrl:String?, label:String?, shoppable:Shoppable?, optionsMask:ProductsOptionsMask) -> Promise<Shoppable> {
        var rootShoppable = shoppable
        if let parent = rootShoppable?.parentShoppable {
            rootShoppable = parent
        }
        let rootShoppableObjectId = rootShoppable?.objectID
        let rootShoppableLabel = label?.lowercased()
        return Promise.init(resolvers: { (fulfil, reject) in
            self.performBackgroundTask(assetId: nil, shoppableId: productImageUrl, { (context) in
                var alreadyExsistingSubShoppable:Shoppable? = nil
                var rootShoppable:Shoppable?
                var minOrder = 999999
                if let rootShoppableObjectId = rootShoppableObjectId, let root = context.shoppableWith(objectId: rootShoppableObjectId)
                {
                    rootShoppable = root
                    if let subShoppables = root.subShoppables as? Set<Shoppable> {
                        minOrder = subShoppables.reduce(999999, { min($0, Int($1.order ?? "999999") ?? 0 ) })
                        for s in subShoppables {
                            if s.imageUrl == productImageUrl {
                                alreadyExsistingSubShoppable = s
                            }
                        }
                    }
                }else if let productImageUrl = productImageUrl  {
                    let request:NSFetchRequest<Shoppable> = Shoppable.fetchRequest()
                    request.predicate = NSPredicate.init(format: "imageUrl == %@", productImageUrl)
                    let result = try? context.fetch(request)
                    alreadyExsistingSubShoppable = result?.first
                }
                
                
                let shoppableToDisplay = alreadyExsistingSubShoppable ?? {
                    let shoppableToSave = Shoppable(context: context)
                    shoppableToSave.order = String.init(format: "%03d", minOrder )
                    shoppableToSave.label = rootShoppable?.label
                    shoppableToSave.imageUrl = productImageUrl
                    shoppableToSave.b0x = 0
                    shoppableToSave.b0x = 0
                    shoppableToSave.b1x = 1
                    shoppableToSave.b1y = 1
                    shoppableToSave.relatedImagesURLString = nil
                    shoppableToSave.screenshot = rootShoppable?.screenshot
                    shoppableToSave.offersURL = nil
                    shoppableToSave.parentShoppable = rootShoppable
                    shoppableToSave.addProductFilter(managedObjectContext: context, optionsMask: optionsMask)
                    
                    return shoppableToSave
                    }()
                if context.saveIfNeeded() {
                    let createdSubShopableObjectId = shoppableToDisplay.objectID
                    DispatchQueue.main.async {
                        if let shoppable = DataModel.sharedInstance.mainMoc().shoppableWith(objectId: createdSubShopableObjectId) {
                            fulfil(shoppable)
                        }else{
                            let error = NSError.init(domain: "Craze-addSubShoppableTo", code: -91, userInfo: [NSLocalizedDescriptionKey:"cannot find sub shoppable after saving"])
                            reject(error)
                        }
                    }
                    if alreadyExsistingSubShoppable?.products?.count ?? 0 == 0 {
                        self.userInitiatedQueue.addOperation(AsyncOperation.init(timeout: 90, assetId: nil, shoppableId: productImageUrl, completion: { (completion) in
                            NetworkingPromise.sharedInstance.uploadToSyte(imageData: nil, orImageUrlString: productImageUrl, retry:true).then(execute: { (uploadedURLString, segments) -> Void in
                                var segment:[String:Any]? = nil
                                
                                
                                if segments.count == 1 {
                                    segment = segments.first
                                }
                                
                                if let rootShoppableLabel = rootShoppableLabel, segment == nil {
                                    segment = segments.first(where: { (segDict) -> Bool in
                                        if let label = segDict["label"] as? String {
                                            return rootShoppableLabel.contains(label.lowercased())
                                        }
                                        return false
                                    })
                                }
                                
                                if segment == nil {
                                    segment = segments.sorted(by: { (dict1, dict2) -> Bool in
                                        if let rect1 = CGRect.rectFrom(syteDict: dict1),
                                            let rect2 = CGRect.rectFrom(syteDict: dict2) {
                                            return rect1.size.area > rect2.size.area
                                        }
                                        return false
                                        
                                    }).first
                                }
                                
                                // Analytics
                                if let selectedSegment = segment {
                                    var selectedSegmentLabelWithArea = selectedSegment["label"] as? String
                                    if let label = selectedSegmentLabelWithArea {
                                        if let rect1 = CGRect.rectFrom(syteDict: selectedSegment) {
                                            selectedSegmentLabelWithArea = "\(label)(\(rect1.size.area))"
                                        }
                                    }
                                    let otherLabels = segments.filter{ $0["offers"] as? String != selectedSegment["offers"] as? String }.compactMap({ (dict) -> String? in
                                        if let label = dict["label"] as? String {
                                            if let rect1 = CGRect.rectFrom(syteDict: dict) {
                                                return "\(label)(\(rect1.size.area))"
                                            }
                                            return label
                                        }
                                        return nil
                                    }).joined(separator: ", ")
                                    
                                    if  let rootShoppableLabel = rootShoppableLabel {
                                        if let selectedSegmentLabel = selectedSegment["label"] as? String,  rootShoppableLabel.contains(selectedSegmentLabel.lowercased()) {
                                            Analytics.trackDevBurrowSelectedShoppable(rootShoppableLabel: rootShoppableLabel, productImageUrl: productImageUrl, selectedShoppableLabel: selectedSegmentLabelWithArea, otherLabels: otherLabels)
                                        }else{
                                            Analytics.trackDevBurrowSelectedShoppableMismatch(rootShoppableLabel: rootShoppableLabel, productImageUrl: productImageUrl, selectedShoppableLabel: selectedSegmentLabelWithArea, otherLabels: otherLabels)
                                        }
                                    }
                                }else{
                                    Analytics.trackDevBurrowErrorNoShoppables(productImageUrl: productImageUrl)
                                }
                                
                                
                                if  let segment = segment , let offersURL = segment["offers"] as? String,
                                    let url = AssetSyncModel.sharedInstance.augmentedUrl(offersURL: offersURL, optionsMask:optionsMask ) {
                                    
                                    //Save the updated data for the shoppable - eventhough it is not used.
                                    self.performBackgroundTask(assetId: nil, shoppableId: productImageUrl, { (context) in
                                        if let shopable = context.shoppableWith(objectId:createdSubShopableObjectId) {
                                            shopable.offersURL = offersURL
                                            if let b0 = segment["b0"] as? [Any],
                                                b0.count >= 2,
                                                let b1 = segment["b1"] as? [Any],
                                                b1.count >= 2,
                                                let b0x = b0[0] as? Double,
                                                let b0y = b0[1] as? Double,
                                                let b1x = b1[0] as? Double,
                                                let b1y = b1[1] as? Double {
                                                shopable.b0x = b0x
                                                shopable.b0y = b0y
                                                shopable.b1x = b1x
                                                shopable.b1y = b1y
                                            }
                                            shopable.relatedImagesURLString = segment["related_looks"] as? String
                                            context.saveIfNeeded()
                                        }
                                    })
                                    NetworkingPromise.sharedInstance.downloadProductsWithRetry(url: url).then(execute:                                                                               { productsDict -> Void in
                                        if let productsArray = productsDict["ads"] as? [[String : Any]],
                                            productsArray.count > 0 {
                                            self.performBackgroundTask(assetId: nil, shoppableId: productImageUrl, { (context) in
                                                if let shopable = context.shoppableWith(objectId:createdSubShopableObjectId) {
                                                    
                                                    shopable.products = NSSet.init()
                                                    var productOrder: Int16 = 0
                                                    for prod in productsArray {
                                                        AssetSyncModel.sharedInstance.saveProduct(managedObjectContext: context,
                                                                                                  shoppable: shopable,
                                                                                                  productOrder: productOrder,
                                                                                                  prod: prod,
                                                                                                  optionsMask: Int32(optionsMask.rawValue))
                                                        productOrder += 1
                                                    }
                                                    
                                                    context.saveIfNeeded()
                                                }
                                                
                                                completion()
                                                
                                                
                                            })
                                        } else{
                                            self.performBackgroundTask(assetId: nil, shoppableId: nil, { (context) in
                                                let shopable = context.shoppableWith(objectId:createdSubShopableObjectId)
                                                Analytics.trackDevBurrowErrorNoProducts(shoppable: shopable)
                                            })
                                            completion()
                                        }
                                    }).catch { (error) in
                                        let error = error as NSError
                                        self.performBackgroundTask(assetId: nil, shoppableId: nil, { (context) in
                                            let shopable = context.shoppableWith(objectId:createdSubShopableObjectId)
                                            Analytics.trackDevBurrowErrorGetProducts(shoppable: shopable, domain: error.domain, code: error.code, localizedDescription: error.localizedDescription)
                                        })
                                        completion()
                                    }
                                }else{
                                    print("can't find segment for label \(String(describing: rootShoppableLabel)) in \( segments.map{$0["label"] ?? ""} )")
                                    completion()
                                }
                            }).catch { (error) in
                                let error = error as NSError
                                Analytics.trackDevBurrowErrorGetShoppable(productImageUrl: productImageUrl, domain: error.domain, code: error.code, localizedDescription: error.localizedDescription)
                                completion()
                            }
                            
                        }))
                    }
                    
                }else {
                    let error = NSError.init(domain: "Craze-addSubShoppableTo", code: -90, userInfo: [NSLocalizedDescriptionKey:"cannot save sub shoppable to db"])
                    reject(error)
                }
            })
        })
    }
}

//Image processing
extension AssetSyncModel {
    func targetSize() -> CGSize {
        // The width really determines the amount of data uploaded, to look good even if shared to other device sizes.
        // Experimenting gives a decent tradeoff between smallest amount of data ~200k and quality of Syte analyzing image.
        // Go with the squattest height we support, iPhone 5.
        return CGSize(width: 675, height: 1200)
    }
    
    func landscapeTargetSize() -> CGSize {
        let portraitSize = targetSize()
        return CGSize(width: portraitSize.height, height: portraitSize.width)
    }
    
    func data(for image: UIImage) -> Data? {
        let desiredSize = image.size.width > image.size.height ? landscapeTargetSize() : targetSize()
        let actualToTargetRatio = image.size.width / desiredSize.width
        let compressionQuality: CGFloat = 0.99
        var imageForData = image
        #if STORE_NEW_TUTORIAL_SCREENSHOT
        #else
        if actualToTargetRatio > 1.2 {
            let originalRect = CGRect(origin: .zero, size: image.size)
            let downSampledRect = CGRect(origin: .zero, size: desiredSize)
            let downSampleSize = originalRect.aspectFit(in: downSampledRect).size
            imageForData = image.downSample(toSize: downSampleSize)
        }
        #endif
        let data = UIImageJPEGRepresentation(imageForData, compressionQuality)
        return data
    }
    
}

//Tutorial photo
extension AssetSyncModel {
    public func syncTutorialPhoto(image: UIImage) {
        self.serialQ.async {
            let dataModel = DataModel.sharedInstance
            
            self.processingQ.async {
                let getData:Promise<Data?> = Promise.init(resolvers: { (fulfill, reject) in
                    let imageData: Data?
                    #if STORE_NEW_TUTORIAL_SCREENSHOT
                    imageData = self.data(for: TutorialTrySlideViewController.rawGraphic ?? image)
                    #else
                    imageData = self.data(for: image)
                    #endif
                    fulfill(imageData)
                })
                getData.then(on: self.processingQ) { imageData -> Promise<Data?> in
                    return Promise { fulfill, reject in
                        self.performBackgroundTask(assetId: Constants.tutorialScreenshotAssetId, shoppableId: nil) { (managedObjectContext) in
                            let assetId = Constants.tutorialScreenshotAssetId
                            let _ = dataModel.saveScreenshot(upsert:true,
                                                             managedObjectContext: managedObjectContext,
                                                             assetId: assetId,
                                                             createdAt: Date(),
                                                             isRecognized: true,
                                                             source: .tutorial,
                                                             isHidden: false,
                                                             imageData: imageData,
                                                             uploadedImageURL: nil,
                                                             syteJsonString: nil)
                            managedObjectContext.saveIfNeeded()
                            fulfill(imageData)
                        }
                    }
                    }.then (on: self.processingQ) { imageData -> Void in
                        #if STORE_NEW_TUTORIAL_SCREENSHOT
                        self.syteProcessing(imageData: imageData, orImageUrlString:nil, assetId: Constants.tutorialScreenshotAssetId)
                        #else
                        let tuple = self.tupleForRawGraphic()
                        self.saveShoppables(assetId: Constants.tutorialScreenshotAssetId, uploadedURLString: tuple.0, segments: tuple.1)
                        #endif
                    }.catch { error in
                        print("syncTutorialPhoto outer catch error:\(error)")
                }
            }
            
        }
    }
    
    
    func tupleForRawGraphic() -> (String, [[String : Any]]) {
        let imageURL = "https://s3-us-west-2.amazonaws.com/syte-image-uploads-west/-hJEtepr-0ctvjWrtAs28"
        let segments = [
            ["label":"Skirts","gender":"female","b0":[0.3360975980758667, 0.3655535876750946],"b1":[0.7115286588668823, 0.6397957801818848],
             "offers":"https://d1wt9iscpot47x.cloudfront.net/offers?image_url=aHR0cHM6Ly9zMy11cy13ZXN0LTIuYW1hem9uYXdzLmNvbS9zeXRlLWltYWdlLXVwbG9hZHMtd2VzdC8taEpFdGVwci0wY3R2aldydEFzMjg%3D&crop=eyJ5MiI6MC42NDk5OTM1OTg0NjExNTExLCJ5IjowLjM1NTM1NTc5OTE5ODE1MDYzLCJ4MiI6MC43MjU0ODkxOTkxNjE1Mjk1LCJ4IjowLjMyMjEzNzA1Nzc4MTIxOTV9&cats=WyJTa2lydHMiXQ%3D%3D&prob=0.8272&catalog=fashion&gender=female&feed=shoppable_production&country=IL&account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D"],
            ["label":"Jackets","gender":"female","b0":[0.3194908499717712, 0.2713195383548737],"b1":[0.6690635085105896, 0.4435304701328278],
             "offers":"https://d1wt9iscpot47x.cloudfront.net/offers?image_url=aHR0cHM6Ly9zMy11cy13ZXN0LTIuYW1hem9uYXdzLmNvbS9zeXRlLWltYWdlLXVwbG9hZHMtd2VzdC8taEpFdGVwci0wY3R2aldydEFzMjg%3D&crop=eyJ5MiI6MC40NTQyMTExNzU0NDE3NDE5NCwieSI6MC4yNjA2Mzg4MzMwNDU5NTk1LCJ4MiI6MC42OTA3NDQzNDA0MTk3NjkzLCJ4IjowLjI5NzgxMDAxODA2MjU5MTU1fQ%3D%3D&cats=WyJDb2F0c0phY2tldHNTdWl0cyJd&prob=0.7578&catalog=fashion&gender=female&feed=shoppable_production&country=IL&account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D"],
            ["label":"Bags","gender":"female","b0":[0.3161032795906067, 0.4687742590904236],"b1":[0.4117679595947266, 0.5696807503700256],
             "offers":"https://d1wt9iscpot47x.cloudfront.net/offers?image_url=aHR0cHM6Ly9zMy11cy13ZXN0LTIuYW1hem9uYXdzLmNvbS9zeXRlLWltYWdlLXVwbG9hZHMtd2VzdC8taEpFdGVwci0wY3R2aldydEFzMjg%3D&crop=eyJ5MiI6MC41OTI2NjM5NDM3Njc1NDc2LCJ5IjowLjQ0NTc5MTA2NTY5MjkwMTYsIngyIjowLjQzMzU1NzIxMjM1Mjc1MjcsIngiOjAuMjk0MzE0MDI2ODMyNTgwNTd9&cats=WyJIYW5kYmFncyJd&prob=0.7384&catalog=fashion&gender=female&feed=shoppable_production&country=IL&account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D"],
            ["label":"Shoes","gender":"female","b0":[0.514782726764679, 0.6339548826217651],"b1":[0.6010540127754211, 0.7061108350753784],
             "offers":"https://d1wt9iscpot47x.cloudfront.net/offers?image_url=aHR0cHM6Ly9zMy11cy13ZXN0LTIuYW1hem9uYXdzLmNvbS9zeXRlLWltYWdlLXVwbG9hZHMtd2VzdC8taEpFdGVwci0wY3R2aldydEFzMjg%3D&crop=eyJ5MiI6MC43MjUyNTQ1MzU2NzUwNDg4LCJ5IjowLjYxNDgxMTE4MjAyMjA5NDcsIngyIjowLjYyMzk0MjY3MzIwNjMyOTMsIngiOjAuNDkxODk0MDY2MzMzNzcwNzV9&cats=WyJCb290cyIsIkZsYXRTYW5kYWxzIiwiRmxhdFNob2VzIiwiSGVlbFNhbmRhbHMiLCJIZWVsU2hvZXMiLCJTcG9ydFNob2VzIl0%3D&prob=0.6405&catalog=fashion&gender=female&feed=shoppable_production&country=IL&account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D"],
            ["label":"Shoes","gender":"female","b0":[0.3859340250492096, 0.6467227935791016],"b1":[0.4655289947986603, 0.7181835174560547],
             "offers":"https://d1wt9iscpot47x.cloudfront.net/offers?image_url=aHR0cHM6Ly9zMy11cy13ZXN0LTIuYW1hem9uYXdzLmNvbS9zeXRlLWltYWdlLXVwbG9hZHMtd2VzdC8taEpFdGVwci0wY3R2aldydEFzMjg%3D&crop=eyJ5MiI6MC43Mzc3MTAxMTgyOTM3NjIyLCJ5IjowLjYyNzE5NjE5Mjc0MTM5NCwieDIiOjAuNDg3Mjc4MjgyNjQyMzY0NSwieCI6MC4zNjQxODQ3MzcyMDU1MDUzN30%3D&cats=WyJCb290cyIsIkZsYXRTYW5kYWxzIiwiRmxhdFNob2VzIiwiSGVlbFNhbmRhbHMiLCJIZWVsU2hvZXMiLCJTcG9ydFNob2VzIl0%3D&prob=0.6160&catalog=fashion&gender=female&feed=shoppable_production&country=IL&account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D"]
        ]
        return (imageURL, segments)
    }
}

extension Screenshot {
    
    public func share() -> Promise<String> {
        if let shareLink = self.shareLink {
            return Promise(value: shareLink)
        }
        
        let assetSyncModel = AssetSyncModel.sharedInstance
        let objectId = self.objectID
        
        return firstly {
            // Post to Craze server, which returns deep share link.
            return self.shareOrReshare()
            }.then(on: assetSyncModel.processingQ) { shareId, shareLink -> Promise<String> in
                // Return the promise as soon as we have the shareLink, and concurrently or afterwards save shareLink to DB.
                NSLog("shareId:\(shareId)  shareLink:\(shareLink)")
                AssetSyncModel.sharedInstance.performBackgroundTask(assetId: nil, shoppableId: nil) { (context) in
                    if let screenshot = context.screenshotWith(objectId:objectId) {
                        screenshot.shareLink = shareLink
                        screenshot.shareId = shareId
                        context.saveIfNeeded()
                    }
                }
                return Promise(value: shareLink)
        }
    }
    
    private func shareOrReshare() -> Promise<(String, String)> {
        let userName = UserDefaults.standard.string(forKey: UserDefaultsKeys.name)
        if let shareId = self.shareId {
            return NetworkingPromise.sharedInstance.reshare(userName: userName, shareId: shareId)
        } else {
            return NetworkingPromise.sharedInstance.share(userName: userName, imageURLString: self.uploadedImageURL, syteJson: self.syteJson)
        }
    }
    
    public func shareViaLink() -> AnyPromise {
        return AnyPromise(share())
    }
    
    public func submitToDiscover(){
        let screenshot = self
        let now = Date()
        if let image = screenshot.uploadedImageURL {
            let objectId = screenshot.objectID
            DataModel.sharedInstance.performBackgroundTask { (context) in
                if let screenshot = context.screenshotWith(objectId:objectId), screenshot.submittedDate == nil {
                    screenshot.submittedDate = now
                    context.saveIfNeeded()
                    
                    let promise = NetworkingPromise.sharedInstance.submitToDiscover(image: image, userName: AnalyticsUser.current.name, intercomUserId: AnalyticsUser.current.identifier, email: AnalyticsUser.current.email)
                    
                    promise.then { (dictionary) -> Void in
                        DataModel.sharedInstance.performBackgroundTask { (context) in
                            if let screenshot = context.screenshotWith(objectId:objectId) {
                                if let sucess = dictionary["success"] as? Bool, sucess, let matchstick =  dictionary["matchstick"] as? NSDictionary, let screenshotId = matchstick["screenshotId"] as? String {
                                    screenshot.screenshotId = screenshotId
                                    screenshot.submittedDate = now
                                    screenshot.submittedFeedbackCountDate = now
                                    context.saveIfNeeded()
                                    
                                }else{
                                    screenshot.submittedDate = nil
                                }
                            }
                        }
                        }.catch { (error) in
                            DataModel.sharedInstance.performBackgroundTask { (context) in
                                if let screenshot = context.screenshotWith(objectId:objectId) {
                                    screenshot.submittedDate = nil
                                }
                            }
                    }
                    
                }
            }
            
        }
    }
    
    var canSubmitToDiscover:Bool {
        get{
            return (source.isUserGenerated && submittedDate == nil)
        }
    }
    
}

//Queue priority
extension AssetSyncModel {
    static func operationPrioritySorting(screenshotQueuePriotiyList:[String:Date], op1:AsyncOperation, op2:AsyncOperation) -> Bool?{
        if let screenshotId1 = op1.userInfo["assetId"] as? String,
            let screenshotId2 = op2.userInfo["assetId"] as? String{
            let index1 = screenshotQueuePriotiyList[screenshotId1] ?? Date.init(timeIntervalSince1970: 0 )
            let index2 = screenshotQueuePriotiyList[screenshotId2] ?? Date.init(timeIntervalSince1970: 0 )
            if index1 == index2 {
                return nil
            }
            return index1 > index2
        }
        return nil
    }

    func moveScreenshotToTopOfQueue(assetId:String){
        self.screenshotQueuePriotiyList[assetId] = Date()
        let copy = self.screenshotQueuePriotiyList
        self.syteProcessingQueue.operationPrioritySorting = { op1, op2 -> Bool? in
            AssetSyncModel.operationPrioritySorting(screenshotQueuePriotiyList: copy, op1: op1, op2: op2)
        }
        self.downloadProductQueue.operationPrioritySorting = {op1, op2 -> Bool? in
            AssetSyncModel.operationPrioritySorting(screenshotQueuePriotiyList: copy, op1: op1, op2: op2)
        }
    }
}

