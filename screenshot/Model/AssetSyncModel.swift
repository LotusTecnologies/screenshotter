//
//  AssetSyncModel.swift
//  screenshot
//
//  Created by Gershon Kagan on 8/9/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit
import Photos
import MobileCoreServices // kUTTypeImage
import CoreData // NSManagedObjectContext
import PromiseKit
import UserNotifications


class AccumulatorModel: NSObject {
    
    public static let sharedInstance = AccumulatorModel()
    
    public func getNewScreenshotsCount() -> Int {
        return assetIds.count
    }
    
    var assetIds:Set<String> = {
        if let array = UserDefaults.standard.value(forKey: UserDefaultsKeys.newScreenshotsAssetIds) as? [String]{
            return Set(array)
        }else{
            let a:[String] = []
            UserDefaults.standard.setValue(a, forKey: UserDefaultsKeys.newScreenshotsAssetIds)
            return Set(a)
        }
        
    }()
    
    private func modifyCount(_ block:@escaping ()->()) {
        DispatchQueue.main.async {  //we want to post the notification on the main queue
            
            let countBefore = self.getNewScreenshotsCount()
            
            block()
            let countAfter = self.getNewScreenshotsCount()
            if countBefore != countAfter {
                UserDefaults.standard.set(Array(self.assetIds), forKey: UserDefaultsKeys.newScreenshotsAssetIds)
                NotificationCenter.default.post(name: .accumulatorModelDidUpdate, object: self)
            }
        }
    }
    public func resetNewScreenshotsCount() {
        modifyCount {
            self.assetIds.removeAll()
        }
    }
    
    fileprivate func removeAssetId(_ assetId:String){
        modifyCount {
            let isMany = self.getNewScreenshotsCount() > Constants.notificationProductToImportCountLimit
            if !isMany { // once it is 'many' it can only be cleared by user interaction, ie `resetNewScreenshotsCount`
                self.assetIds.remove(assetId)
            }
        }
    }
    
    fileprivate func addAssetId(_ assetId:String){
        modifyCount {
            self.assetIds.insert(assetId)
        }
    }
}

class BackgroundScreenshotData { // Is class, not struct, to save copying around the non-trivial imageData
    let assetId: String
    var imageData: Data?
    init(assetId: String, imageData: Data?) {
        self.assetId = assetId
        self.imageData = imageData
    }
}

class AssetSyncModel: NSObject {

    public static let sharedInstance = AssetSyncModel()
    public weak var networkingIndicatorDelegate: NetworkingIndicatorProtocol?
    public weak var screenshotDetectionDelegate: ScreenshotDetectionProtocol?
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
    
    var uploadScreenshotWithClarifaiQueue:OperationQueue = {
        var queue = OperationQueue()
        queue.name = "upload Screenshot With Clarifai Queue"
        queue.maxConcurrentOperationCount = 1
        queue.isSuspended = true
        ClarifaiModel.sharedInstance.kickoffModelDownload().always {
            queue.isSuspended = false
        }
        queue.qualityOfService = .utility

        return queue
    }()
    
    var uploadScreenshotWithClarifaiQueueFromUserScreenshot:OperationQueue = {
        var queue = OperationQueue()
        queue.name = "upload Screenshot With Clarifai Queue from user screenshot"
        queue.maxConcurrentOperationCount = 1
        queue.isSuspended = true
        ClarifaiModel.sharedInstance.kickoffModelDownload().always {
            queue.isSuspended = false
        }
        queue.qualityOfService = .userInitiated
        
        return queue
    }()
    
    
    var userInitiatedQueue:OperationQueue = {
        var queue = OperationQueue()
        queue.name = "retry Screenshot image processing Queue"
        queue.maxConcurrentOperationCount = 2
        queue.qualityOfService = .userInteractive
        return queue
    }()

    override init() {
        super.init()
        registerForPhotoChanges()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationUserDidTakeScreenshot), name: .UIApplicationUserDidTakeScreenshot, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: .UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(scanPhotoGalleryForFashion), name: .permissionsManagerDidUpdate, object: nil)

    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    func applicationDidBecomeActive(){
        self.lastDidBecomeActiveDate = Date()
        self.processingQ.async {
            self.shouldSendPushWhenFindFashionWithoutUserScreenshotAction = false
        }
        
    }
    
}

//User initiated Import
extension AssetSyncModel {
    
    public func importPhotosToScreenshot(assetIds:[String]) {
        assetIds.forEach {
            if let asset = PHAsset.assetWith(assetId: $0) {
                self.uploadPhoto(asset: asset)
            }
        }
    }
    
    public func importPhotosToScreenshot(assets:[PHAsset]) {
        assets.forEach{ self.uploadPhoto(asset: $0) }
    }
    
    func uploadPhoto(asset: PHAsset) {
        self.userInitiatedQueue.addOperation(AsyncOperation.init(timeout: 5.0, completion: { (completeOperation) in
            AccumulatorModel.sharedInstance.removeAssetId(asset.localIdentifier)
            asset.image(allowFromICloud: true).then(on: self.processingQ) { image -> Promise<(ClarifaiModel.ImageClassification, Data?)> in
                AnalyticsTrackers.standard.track(.bypassedClarifai)
                let imageData: Data? = self.data(for: image)
                return Promise { fulfill, reject in
                    DataModel.sharedInstance.performBackgroundTask { (managedObjectContext) in
                        if let screenshot = managedObjectContext.screenshotWith(assetId: asset.localIdentifier) {
                            //this is retry screenshot
                            var imageClassification: ClarifaiModel.ImageClassification
                            if let classification = screenshot.syteJson,
                                classification.utf8.count == 1 { // Dual-purposing syteJson for imageClassification, if one character
                                screenshot.syteJson = nil
                                
                                switch classification {
                                case "h":
                                    imageClassification = .human
                                case "f":
                                    imageClassification = .furniture
                                default:
                                    imageClassification = .human
                                }
                            } else {
                                imageClassification = .human
                            }
                            
                            if screenshot.shoppablesCount > 0 {
                                screenshot.hideWorkhorse(managedObjectContext: managedObjectContext)
                            }
                            screenshot.shoppablesCount = 0
                            screenshot.imageData = imageData as NSData?
                            screenshot.isHidden = false
                            screenshot.isRecognized = true
                            screenshot.lastModified = NSDate()

                            managedObjectContext.saveIfNeeded()
                            fulfill((imageClassification, imageData))
                        }else{
                            let screenshot = Screenshot(context: managedObjectContext)
                            screenshot.assetId = asset.localIdentifier
                            let now = NSDate()
                            if let date =  asset.creationDate as NSDate? {
                                screenshot.createdAt = date
                            }else{
                                screenshot.createdAt = now
                                
                            }
                            screenshot.isHidden = true
                            screenshot.isNew = true
                            screenshot.lastModified = now
                            screenshot.isRecognized = true
                            screenshot.isFromShare = false
                            screenshot.isHidden = false
                            screenshot.imageData = imageData as NSData?
                            
                            managedObjectContext.saveIfNeeded()
                            fulfill(ClarifaiModel.ImageClassification.human, imageData)
                        }
                    }
                }
            }.then (on: self.processingQ) { imageClassification, imageData -> Promise<Bool> in
                self.syteProcessing(imageClassification: imageClassification, imageData: imageData, assetId: asset.localIdentifier)
                return Promise.init(value: true)
            }.catch { error in
                print("uploadPhoto outer catch error:\(error)")
            }.always(on: self.serialQ) {
                completeOperation()
            }
        }))
    }
    
    //From share
    public func downloadScreenshot(shareId: String) {
        self.userInitiatedQueue.addOperation(AsyncOperation.init(timeout: 20.0, completion: { (completeOperation) in
            firstly { _ -> Promise<[String : Any]> in
                // Get screenshot dict from Craze server.
                // See end https://docs.google.com/document/d/16WsJMepl0Z3YrsRKxcFqkASUieRLKy_Aei8lmbpD2bo
                guard let encoded = shareId.addingPercentEncoding(withAllowedCharacters: .alphanumerics),
                    let screenshotInfoUrl = URL(string: Constants.screenShotLambdaDomain + "shares/" + encoded) else {
                        let urlError = NSError(domain: "Craze", code: 8, userInfo: [NSLocalizedDescriptionKey : "Could not form URL from shareId:\(shareId)"])
                        return Promise(error: urlError)
                }
                print("downloadScreenshot shareId:\(shareId)  encode:\(encoded)  screenshotInfoUrl:\(screenshotInfoUrl)")
                return NetworkingPromise.sharedInstance.downloadInfo(url: screenshotInfoUrl)
            }.then(on: self.processingQ) { jsonDict -> Promise<(Data, [String : Any])> in
                // Download image from Syte S3.
                guard let share = jsonDict["share"] as? [String : Any],
                    let screenshotDict = share["screenshot"] as? [String : Any],
                    let imageURLString = screenshotDict["image"] as? String
                    else {
                        let imageURLError = NSError(domain: "Craze", code: 9, userInfo: [NSLocalizedDescriptionKey : "Could not form image URL from jsonDict:\(jsonDict)"])
                        return Promise(error: imageURLError)
                }
                return when(fulfilled:  NetworkingPromise.sharedInstance.downloadImageData(urlString: imageURLString), Promise.init(value: screenshotDict))
            }.then(on: self.processingQ) { (imageData, screenshotDict) -> Promise<(NSManagedObject, [String : Any])> in
                // Save screenshot to db.
                return DataModel.sharedInstance.backgroundPromise(dict: screenshotDict) { (managedObjectContext) -> NSManagedObject in
                    return DataModel.sharedInstance.saveScreenshot(managedObjectContext: managedObjectContext,
                                                    assetId: shareId,
                                                    createdAt: Date(),
                                                    isRecognized: true,
                                                    source: .share,
                                                    isHidden: false,
                                                    imageData: imageData,
                                                    classification: nil)
                }
            }.then(on: self.processingQ) { screenshotManagedObject, screenshotDict -> Void in
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
        var dates:[Date] = []
        
        var installDate: Date
        if let UserDefaultsInstallDate = UserDefaults.standard.object(forKey: UserDefaultsKeys.dateInstalled) as? Date {
            installDate = UserDefaultsInstallDate
        } else {
            installDate = Date()
            UserDefaults.standard.set(installDate, forKey: UserDefaultsKeys.dateInstalled)
        }
        
        dates.append(installDate)
        dates.append(Date(timeIntervalSinceNow: -60*60*24))
        
        if let date = UserDefaults.standard.value(forKey: UserDefaultsKeys.processBackgroundImagesForFashionAfterDate) as? Date {
            dates.append(date)
        }
        
        let cutOffDate = (dates.max { a, b -> Bool in a < b  } ?? installDate )as NSDate
        
        fetchOptions.predicate = NSPredicate(format: "creationDate > %@ AND (mediaSubtype & %d) != 0", cutOffDate, PHAssetMediaSubtype.photoScreenshot.rawValue)
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 25
        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        self.backgroundProcessFetchedResults = assets
        registerForPhotoChanges()  //just in case we got permissions since init
    }
    
    @objc func scanPhotoGalleryForFashion() {
        guard PermissionsManager.shared.hasPermission(for: .photo) else {
            print("scanPhotoGalleryForFashion refused by guard")
            return
        }
        
        updatePhotoGalleryFetch()
        
        if let assets = self.backgroundProcessFetchedResults {
            var assetIds = Set<String>()
            assets.enumerateObjects({ (asset: PHAsset, index: Int, stop: UnsafeMutablePointer<ObjCBool>) in
                assetIds.insert(asset.localIdentifier)
            })
            let startedInBackground = ApplicationStateModel.sharedInstance.isBackground()
            DataModel.sharedInstance.performBackgroundTask { (context) in
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
        guard PermissionsManager.shared.hasPermission(for: .photo) else {
            print("registerForPhotoChanges refused by guard")
            return
        }
        if isRegistered == false {
            PHPhotoLibrary.shared().register(self)
            isRegistered = true
        }
    }
    
     func applicationUserDidTakeScreenshot() {
        print("AssetSyncModel applicationUserDidTakeScreenshot")
        isNextScreenshotForeground = ApplicationStateModel.sharedInstance.isActive()
    }
    

    func uploadScreenshotWithClarifaiFromUserScreenshotAction(asset: PHAsset) {
        let isForeground = self.foregroundScreenshotAssetIds.contains(asset.localIdentifier)
        self.foregroundScreenshotAssetIds.remove(asset.localIdentifier)
        self.uploadScreenshotWithClarifaiQueueFromUserScreenshot.addOperation(AsyncOperation.init(timeout: 20.0, completion: { (completeOperation) in
            asset.image(allowFromICloud: false).then (on: self.processingQ) { image -> Promise<(ClarifaiModel.ImageClassification, UIImage)> in
                AnalyticsTrackers.standard.track(.sentImageToClarifai)
                return ClarifaiModel.sharedInstance.classify(image: image).then(execute: { (c) -> Promise<(ClarifaiModel.ImageClassification, UIImage)>  in
                    return Promise.init(value: (c, image))
                })
                }.then(on: self.processingQ) { imageClassification, image -> Promise<(ClarifaiModel.ImageClassification, Data?)> in
                    let isRecognized = (imageClassification != .unrecognized)
                    let classification = imageClassification.shortString()
                    
                    AnalyticsTrackers.standard.track(.receivedResponseFromClarifai, properties: ["isFashion" : imageClassification == .human, "isFurniture" : imageClassification == .furniture])
                    return Promise { fulfill, reject in
                        DataModel.sharedInstance.performBackgroundTask { (managedObjectContext) in
                            if let _ = managedObjectContext.screenshotWith(assetId: asset.localIdentifier) {
                                //do nothing if already exsists
                                let error = NSError.init(domain: "Craze", code: -90, userInfo: [NSLocalizedDescriptionKey:"already have screenshot in database"])
                                reject(error)
                            }else{
                                let isHidden = ( !isRecognized || !isForeground)
                                let imageData:Data? = isRecognized ? self.data(for: image) : nil
                                
                                let _ = DataModel.sharedInstance.saveScreenshot(managedObjectContext: managedObjectContext,
                                                                                assetId: asset.localIdentifier,
                                                                                createdAt: asset.creationDate,
                                                                                isRecognized: isRecognized,
                                                                                source: .gallery,
                                                                                isHidden: isHidden,
                                                                                imageData: imageData,
                                                                                classification: classification)
                                
                                fulfill((imageClassification, imageData))
                            }
                        }
                        
                    }
                }.then (on: self.processingQ) { imageClassification, imageData -> Void in
                    if imageClassification != .unrecognized {
                        if isForeground { // Screenshot taken while app in foregorund
                            DispatchQueue.main.async {
                                self.screenshotDetectionDelegate?.foregroundScreenshotTaken(assetId: asset.localIdentifier)
                            }
                            self.syteProcessing(imageClassification: imageClassification, imageData: imageData, assetId: asset.localIdentifier)
                        } else { // Screenshot taken while app in background (or killed)
                            AccumulatorModel.sharedInstance.addAssetId(asset.localIdentifier)
                            if  ApplicationStateModel.sharedInstance.isBackground() {
                                self.sendScreenshotAddedLocalNotification(backgroundScreenshotData: [BackgroundScreenshotData(assetId: asset.localIdentifier, imageData: imageData)])
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
        self.uploadScreenshotWithClarifaiQueue.addOperation(AsyncOperation.init(timeout: 20.0, completion: { (completeOperation) in
            firstly{ () -> Promise<Bool> in
                if !isScreenshotUserJustTook {
                    if let date = asset.creationDate {
                        if let currentValue = UserDefaults.standard.value(forKey: UserDefaultsKeys.processBackgroundImagesForFashionAfterDate) as? Date {
                            if date < currentValue {
                                let error = NSError.init(domain: "Craze", code: -81, userInfo: [NSLocalizedDescriptionKey : "asset is too old to process"])
                                throw error
                            }
                        }
                    }
                    if AccumulatorModel.sharedInstance.getNewScreenshotsCount() > Constants.notificationProductToImportCountLimit && !self.shouldSendPushWhenFindFashionWithoutUserScreenshotAction {
                        let error = NSError.init(domain: "Craze", code: -82, userInfo: [NSLocalizedDescriptionKey : "already have enough images"])
                        throw error
                    }
                }
                return Promise.init(value: true)
            }.then(on: self.processingQ) { success -> Promise<UIImage> in
                return asset.image(allowFromICloud: false)
            }.then (on: self.processingQ) { image -> Promise<(ClarifaiModel.ImageClassification, UIImage)> in
                AnalyticsTrackers.standard.track(.sentImageToClarifai)
                return ClarifaiModel.sharedInstance.classify(image: image).then(execute: { (c) -> Promise<(ClarifaiModel.ImageClassification, UIImage)>  in
                    return Promise.init(value: (c, image))
                })
            }.then(on: self.processingQ) { (imageClassification, image) -> Void in
                if imageClassification != .unrecognized {
                    DataModel.sharedInstance.performBackgroundTask { (managedObjectContext) in
                        if managedObjectContext.screenshotWith(assetId: asset.localIdentifier) == nil {
                            AccumulatorModel.sharedInstance.addAssetId(asset.localIdentifier)
                            if self.shouldSendPushWhenFindFashionWithoutUserScreenshotAction && ApplicationStateModel.sharedInstance.isBackground(){
                                self.processingQ.async {
                                    if self.shouldSendPushWhenFindFashionWithoutUserScreenshotAction && ApplicationStateModel.sharedInstance.isBackground(){  //need to check twice due to async craziness
                                        self.shouldSendPushWhenFindFashionWithoutUserScreenshotAction = false
                                        self.sendScreenshotAddedLocalNotification(backgroundScreenshotData: [BackgroundScreenshotData.init(assetId: asset.localIdentifier, imageData: self.data(for: image))])
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
    
    
    func sendScreenshotAddedLocalNotification(backgroundScreenshotData: [BackgroundScreenshotData]) {
        guard PermissionsManager.shared.hasPermission(for: .push) else {
            print("sendScreenshotAddedLocalNotification refused by guard")
            return
        }
        print("should display notification")
        let content = UNMutableNotificationContent()
        content.title = "notification.title".localized
        content.body = "notification.message".localized
        if let lastNotificationSound = UserDefaults.standard.object(forKey: UserDefaultsKeys.dateLastSound) as? Date,
            -lastNotificationSound.timeIntervalSinceNow < 60 { // 1 minute
            content.sound = nil
        } else {
            content.sound = UNNotificationSound.default()
        }
        UserDefaults.standard.setValue(Date(), forKey: UserDefaultsKeys.dateLastSound)
        content.userInfo = [Constants.openingScreenKey  : Constants.openingScreenValueScreenshot]
        
        var identifier = "CrazeLocal"
        if let representativeScreenshotData = backgroundScreenshotData.reversed().first(where: { $0.imageData != nil }), // Last taken screenshot that has imageData.
            let representativeImageData = representativeScreenshotData.imageData {
            
            content.userInfo = [Constants.openingScreenKey  : Constants.openingScreenValueScreenshot,
                                Constants.openingAssetIdKey : representativeScreenshotData.assetId]

            identifier += representativeScreenshotData.assetId.replacingOccurrences(of: "/", with: "-")
            // Add image url
            let tmpImageFileUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(identifier).appendingPathExtension("jpg")
            do {
                try representativeImageData.write(to: tmpImageFileUrl)
                let attachment = try UNNotificationAttachment(identifier: identifier,
                                                              url: tmpImageFileUrl,
                                                              options: [UNNotificationAttachmentOptionsTypeHintKey : kUTTypeImage])
                content.attachments = [attachment]
            } catch {
                print("Local notification attachment error:\(error)")
            }
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content,
                                            trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: { (error) in
            if let error = error {
                print("sendScreenshotAddedLocalNotification identifier:\(identifier)  error:\(error)")
            } else {
                AnalyticsTrackers.standard.track(.appSentLocalPushNotification)
            }
        })
    }
    
}

extension AssetSyncModel {

    
    func resaveScreenshot(assetId: String, imageData: Data?) -> Promise<(Data?, ClarifaiModel.ImageClassification)> {
        let dataModel = DataModel.sharedInstance
        return Promise { fulfill, reject in
            dataModel.performBackgroundTask { (managedObjectContext) in
                if let screenshot = dataModel.retrieveScreenshot(managedObjectContext: managedObjectContext, assetId: assetId) {
                    var imageClassification: ClarifaiModel.ImageClassification
                    if let classification = screenshot.syteJson,
                        classification.utf8.count == 1 { // Dual-purposing syteJson for imageClassification, if one character
                        screenshot.syteJson = nil
                        
                        switch classification {
                        case "h":
                            imageClassification = .human
                        case "f":
                            imageClassification = .furniture
                        default:
                            imageClassification = .human
                        }
                    } else {
                        imageClassification = .human
                    }
                    if screenshot.shoppablesCount > 0 {
                        screenshot.hideWorkhorse(managedObjectContext: managedObjectContext)
                    }
                    screenshot.shoppablesCount = 0
                    screenshot.imageData = imageData as NSData?
                    screenshot.isHidden = false
                    screenshot.isRecognized = true
                    screenshot.lastModified = NSDate()
                    managedObjectContext.saveIfNeeded()
                    fulfill((imageData, imageClassification))
                } else {
                    let error = NSError(domain: "Craze", code: 18, userInfo: [NSLocalizedDescriptionKey : "Could not retreive screenshot with assetId:\(assetId)"])
                    reject(error)
                }
            }
        }
    }
    
    func rescanClassification(assetId: String, imageData: Data?, optionsMask: ProductsOptionsMask = ProductsOptionsMask.global) {
        AnalyticsTrackers.standard.track(.bypassedClarifaiOnRetry)
        firstly {
            self.resaveScreenshot(assetId: assetId, imageData: imageData)
            }.then (on: processingQ) { (imageData, imageClassification) -> Void in
                print("rescanClassification imageClassification:\(imageClassification)")
                self.syteProcessing(imageClassification: imageClassification, imageData: imageData, assetId: assetId, optionsMask: optionsMask)
            }.catch { error in
                print("rescanClassification catch error:\(error)")
        }
    }
    
    func syteProcessing(imageClassification: ClarifaiModel.ImageClassification, imageData: Data?, assetId: String, optionsMask: ProductsOptionsMask = ProductsOptionsMask.global) {
        var localImageData = imageData
        if assetId.hasPrefix("shamrock") {
            if let imageData = imageData, let image = UIImage.init(data: imageData),  let image2 = image.shamrock(), let data = self.data(for: image2) {
                localImageData = data
            }
        }
        
        if imageClassification != .unrecognized {
            DispatchQueue.main.async {
                self.networkingIndicatorDelegate?.networkingIndicatorDidStart(type: .Product)
            }
            firstly { _ -> Promise<(String, [[String : Any]])> in
                return NetworkingPromise.sharedInstance.uploadToSyte(imageData: localImageData, imageClassification: imageClassification)
                }.then(on: self.processingQ) { uploadedURLString, segments -> Void in
                    let categories = segments.map({ (segment: [String : Any]) -> String? in segment["label"] as? String}).flatMap({$0}).joined(separator: ",")
                    AnalyticsTrackers.standard.track(.receivedResponseFromSyte, properties: ["imageUrl" : uploadedURLString, "segmentCount" : segments.count, "categories" : categories])
#if STORE_NEW_TUTORIAL_SCREENSHOT
                    print("uploadedURLString:\(uploadedURLString)\nsegments:\(segments)")
#endif
                    self.saveShoppables(assetId: assetId, uploadedURLString: uploadedURLString, segments: segments, optionsMask: optionsMask)
                }.always {
                    self.networkingIndicatorDelegate?.networkingIndicatorDidComplete(type: .Product)
                }.catch { error in
                    let nsError = error as NSError
                    if nsError.domain == "Craze" {
                        switch nsError.code {
                        case 3, 4, 22:
                            // Syte returned no segments
                            let uploadedURLString = nsError.userInfo[Constants.uploadedURLStringKey] as? String
                            let imageUrl: String = uploadedURLString ?? ""
                            DataModel.sharedInstance.setNoShoppables(assetId: assetId, uploadedURLString: uploadedURLString)
                            AnalyticsTrackers.standard.track(.receivedResponseFromSyte, properties: nsError.code == 22 ? ["imageUrl" : imageUrl, "segmentCount" : 0, "timeout" : 1] : ["imageUrl" : imageUrl, "segmentCount" : 0])
                        default:
                            break
                        }
                    }
                    print("uploadScreenshot inner uploadToSyte catch error:\(error)")
            }
        }
    }
  
    
    
    func currencyParam() -> String {
        guard let productCurrency = UserDefaults.standard.string(forKey: UserDefaultsKeys.productCurrency),
            (!productCurrency.isEmpty && productCurrency != CurrencyMap.autoCode) else {
                return ""
        }
        return "&force_currency=\(productCurrency)"
    }
    
    func augmentedUrl(offersURL: String, optionsMask: ProductsOptionsMask) -> URL? {
        let isChild = optionsMask.rawValue & ProductsOptionsMask.sizeChild.rawValue > 0
        let isPlus = optionsMask.rawValue & ProductsOptionsMask.sizePlus.rawValue > 0
        let sizeParamString = isPlus ? "&feed=craze_plus_size" : isChild ? "&feed=kids_craze" : ""
        var genderParamString = ""
        if optionsMask.rawValue & ProductsOptionsMask.genderMale.rawValue > 0 {
            genderParamString = isChild ? "&force_gender=boy" : "&force_gender=male"
        } else if optionsMask.rawValue & ProductsOptionsMask.genderFemale.rawValue > 0 {
            genderParamString = isChild ? "&force_gender=girl" : "&force_gender=female"
        }
        return URL(string: (offersURL.hasPrefix("//") ? "https:" : "") + offersURL + currencyParam() + sizeParamString + genderParamString)
    }
    
    func saveShoppables(assetId: String, uploadedURLString: String, segments: [[String : Any]], optionsMask: ProductsOptionsMask = ProductsOptionsMask.global) { //-> Promise<[String]> {
        for segment in segments {
            guard let offersURL = segment["offers"] as? String,
                let url = augmentedUrl(offersURL: offersURL, optionsMask: optionsMask),
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
            let label = segment["label"] as? String
            self.extractProducts(assetId: assetId,
                                 uploadedURLString: uploadedURLString,
                                 segments: segments,
                                 offersURL: offersURL,
                                 optionsMask: optionsMask,
                                 url: url,
                                 label: label,
                                 b0x: b0x,
                                 b0y: b0y,
                                 b1x: b1x,
                                 b1y: b1y)
        }
    }

    func saveProduct(managedObjectContext: NSManagedObjectContext,
                     shoppable: Shoppable,
                     productOrder: Int16,
                     prod: [String : Any],
                     optionsMask: Int32) {
        let extractedCategories = prod["categories"] as? [String]
        let _ = DataModel.sharedInstance.saveProduct(managedObjectContext: managedObjectContext,
                                                     shoppable: shoppable,
                                                     order: productOrder,
                                                     productDescription: prod["description"] as? String,
                                                     price: prod["price"] as? String,
                                                     originalPrice: prod["originalPrice"] as? String,
                                                     floatPrice: prod["floatPrice"] as? Float ?? 0,
                                                     floatOriginalPrice: prod["floatOriginalPrice"] as? Float ?? 0,
                                                     categories: extractedCategories?.first,
                                                     brand: prod["brand"] as? String,
                                                     offer: prod["offer"] as? String,
                                                     imageURL: prod["imageUrl"] as? String,
                                                     merchant: prod["merchant"] as? String,
                                                     optionsMask: optionsMask)
    }
    
    func extractProducts(assetId: String,
                         uploadedURLString: String,
                         segments: [[String : Any]],
                         offersURL: String,
                         optionsMask: ProductsOptionsMask,
                         url: URL,
                         label: String?,
                         b0x: Double,
                         b0y: Double,
                         b1x: Double,
                         b1y: Double) {
        let optionsMask32 = Int32(optionsMask.rawValue)
        let dataModel = DataModel.sharedInstance
        
        func embeddedSaveShoppableWithProducts(productsArray: [[String : Any]]) {
            dataModel.performBackgroundTask { (managedObjectContext) in
                guard let screenshot = dataModel.retrieveScreenshot(managedObjectContext: managedObjectContext, assetId: assetId) else {
                    print("AssetSyncModel extractProducts error retreiving screenshot:\(assetId) to which to add shoppable and products")
                    return
                }
                let shoppable = dataModel.saveShoppable(managedObjectContext: managedObjectContext,
                                                        screenshot: screenshot,
                                                        label: label,
                                                        offersURL: offersURL,
                                                        b0x: b0x,
                                                        b0y: b0y,
                                                        b1x: b1x,
                                                        b1y: b1y,
                                                        optionsMask: optionsMask)
                var productOrder: Int16 = 0
                for prod in productsArray {
                    self.saveProduct(managedObjectContext: managedObjectContext,
                                     shoppable: shoppable,
                                     productOrder: productOrder,
                                     prod: prod,
                                     optionsMask: optionsMask32)
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
                screenshot.shoppablesCount += 1
                if screenshot.shoppablesCount == 1 {
                    screenshot.syteJson = NetworkingPromise.sharedInstance.jsonStringify(object: segments)
                    screenshot.uploadedImageURL = uploadedURLString
                }
                managedObjectContext.saveIfNeeded()
            }
            AnalyticsTrackers.standard.track(.receivedProductsFromSyte, properties: ["productCount" : productsArray.count, "optionsMask" : optionsMask.rawValue])
        }
            
        NetworkingPromise.sharedInstance.downloadProductsWithRetry(url: url)
            .then(on: self.processingQ) { productsDict -> Void in
                if let adsArray = productsDict["ads"] as? [[String : Any]],
                  adsArray.count > 0 {
                    embeddedSaveShoppableWithProducts(productsArray: adsArray)
                } else {
                    print("AssetSyncModel extractProducts no products in ads, when NetworkPromise checks. productsDict:\(productsDict)")
                    embeddedSaveShoppableWithProducts(productsArray: [])
                }
            }.catch { error in
                print("AssetSyncModel extractProducts parsing products error:\(error)")
                embeddedSaveShoppableWithProducts(productsArray: [])
        }
    }
    
    func updateShoppableWithProducts(shoppableId: NSManagedObjectID,
                                     optionsMask32: Int32,
                                     productsArray: [[String : Any]]) {
        let dataModel = DataModel.sharedInstance
        dataModel.performBackgroundTask { (managedObjectContext) in
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

    func reExtractProducts(shoppableId: NSManagedObjectID,
                           optionsMask: ProductsOptionsMask,
                           offersURL: String) {
        let optionsMask32 = Int32(optionsMask.rawValue)
        guard let url = augmentedUrl(offersURL: offersURL, optionsMask: optionsMask) else {
            print("AssetSyncModel reExtractProducts no url from offersURL:\(offersURL)")
            updateShoppableWithProducts(shoppableId: shoppableId, optionsMask32: optionsMask32, productsArray: [])
            return
        }
        NetworkingPromise.sharedInstance.downloadProductsWithRetry(url: url)
            .then(on: self.processingQ) { productsDict -> Void in
                if let productsArray = productsDict["ads"] as? [[String : Any]], productsArray.count > 0 {
                    self.updateShoppableWithProducts(shoppableId: shoppableId, optionsMask32: optionsMask32, productsArray: productsArray)
                } else {
                    print("AssetSyncModel reExtractProducts no products in ads. productsDict:\(productsDict)")
                    self.updateShoppableWithProducts(shoppableId: shoppableId, optionsMask32: optionsMask32, productsArray: [])
                }
            }.catch { error in
                print("AssetSyncModel reExtractProducts error parsing product:\(error)")
                self.updateShoppableWithProducts(shoppableId: shoppableId, optionsMask32: optionsMask32, productsArray: [])
        }
    }
    
    public func refetchShoppables(screenshot: Screenshot, classificationString: String) {
        guard let assetId = screenshot.assetId, let asset = PHAsset.assetWith(assetId: assetId) else {
            return
        }
        
        let dataModel = DataModel.sharedInstance
        let oid = screenshot.objectID
        dataModel.performBackgroundTask { (managedObjectContext) in
            let backgroundScreenshot = managedObjectContext.object(with: oid) as? Screenshot
            backgroundScreenshot?.syteJson = classificationString
            backgroundScreenshot?.shoppables?.forEach { shoppable in
                if let shoppableManagedObject = shoppable as? NSManagedObject {
                    managedObjectContext.delete(shoppableManagedObject)
                } else {
                    print("WTF? Cannot cast as NSManagedObject:\(shoppable)")
                }
            }
            backgroundScreenshot?.shoppablesCount = 0
            managedObjectContext.saveIfNeeded()
            self.uploadPhoto(asset: asset)
        }
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
        print("image.size:\(image.size)  desiredSize:\(desiredSize)  imageForData.size\(imageForData.size)  actualToTargetRatio:\(actualToTargetRatio)  data.count:\(data?.count ?? 0)")
        return data
    }
        
}

//Tutorial photo
extension AssetSyncModel {
     public func syncTutorialPhoto(image: UIImage) {
        self.serialQ.async {
            let dataModel = DataModel.sharedInstance
            
            self.processingQ.async {
                firstly { _ -> Promise<Data?> in
                    let imageData: Data?
#if STORE_NEW_TUTORIAL_SCREENSHOT
                        imageData = self.data(for: TutorialTrySlideView.rawGraphic ?? image)
#else
                        imageData = self.data(for: image)
#endif
                    return Promise(value: imageData)
                    }.then(on: self.processingQ) { imageData -> Promise<Data?> in
                        return Promise { fulfill, reject in
                            dataModel.performBackgroundTask { (managedObjectContext) in
                                let _ = dataModel.saveScreenshot(managedObjectContext: managedObjectContext,
                                                                 assetId: Constants.tutorialScreenshotAssetId,
                                                                 createdAt: Date(),
                                                                 isRecognized: true,
                                                                 source: .tutorial,
                                                                 isHidden: false,
                                                                 imageData: imageData,
                                                                 classification: nil)
                                fulfill(imageData)
                            }
                        }
                    }.then (on: self.processingQ) { imageData -> Void in
#if STORE_NEW_TUTORIAL_SCREENSHOT
                            self.syteProcessing(imageClassification: .human, imageData: imageData, assetId: Constants.tutorialScreenshotAssetId)
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
        let imageURL = "https://s3.amazonaws.com/s3-file-store/generated/-hJEtepr-0ctvjWrtAs28"
        let segments = [
            ["label":"Shoes","gender":"female","b0":[0.385934054851532, 0.6467227935791016],"b1":[0.4655290246009827, 0.7181835174560547],
             "offers":"//d1wt9iscpot47x.cloudfront.net/offers?image_url=aHR0cHM6Ly9zMy5hbWF6b25hd3MuY29tL3MzLWZpbGUtc3RvcmUvZ2VuZXJhdGVkLy1oSkV0ZXByLTBjdHZqV3J0QXMyOA%3D%3D&crop=eyJ5MiI6MC43Mzc3MTAxMTgyOTM3NjIyLCJ5IjowLjYyNzE5NjE5Mjc0MTM5NCwieDIiOjAuNDg3Mjc4MzEyNDQ0Njg2OSwieCI6MC4zNjQxODQ3NjcwMDc4Mjc3Nn0%3D&cats=WyJCb290cyIsIkZsYXRTYW5kYWxzIiwiRmxhdFNob2VzIiwiSGVlbFNhbmRhbHMiLCJIZWVsU2hvZXMiLCJTcG9ydFNob2VzIl0%3D&prob=0.6160&gender=female&feed=default&country=IL&account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D"],
            ["label":"Shoes","gender":"female","b0":[0.514782726764679, 0.6339549422264099],"b1":[0.6010540127754211, 0.7061108946800232],
             "offers":"//d1wt9iscpot47x.cloudfront.net/offers?image_url=aHR0cHM6Ly9zMy5hbWF6b25hd3MuY29tL3MzLWZpbGUtc3RvcmUvZ2VuZXJhdGVkLy1oSkV0ZXByLTBjdHZqV3J0QXMyOA%3D%3D&crop=eyJ5MiI6MC43MjUyNTQ1OTUyNzk2OTM2LCJ5IjowLjYxNDgxMTI0MTYyNjczOTUsIngyIjowLjYyMzk0MjY3MzIwNjMyOTMsIngiOjAuNDkxODk0MDY2MzMzNzcwNzV9&cats=WyJCb290cyIsIkZsYXRTYW5kYWxzIiwiRmxhdFNob2VzIiwiSGVlbFNhbmRhbHMiLCJIZWVsU2hvZXMiLCJTcG9ydFNob2VzIl0%3D&prob=0.6405&gender=female&feed=default&country=IL&account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D"],
            ["label":"Bags","gender":"female","b0":[0.3161032795906067, 0.4687742590904236],"b1":[0.4117679595947266, 0.5696807503700256],
             "offers":"//d1wt9iscpot47x.cloudfront.net/offers?image_url=aHR0cHM6Ly9zMy5hbWF6b25hd3MuY29tL3MzLWZpbGUtc3RvcmUvZ2VuZXJhdGVkLy1oSkV0ZXByLTBjdHZqV3J0QXMyOA%3D%3D&crop=eyJ5MiI6MC41OTI2NjM5NDM3Njc1NDc2LCJ5IjowLjQ0NTc5MTA2NTY5MjkwMTYsIngyIjowLjQzMzU1NzIxMjM1Mjc1MjcsIngiOjAuMjk0MzE0MDI2ODMyNTgwNTd9&cats=WyJIYW5kYmFncyJd&prob=0.7384&gender=female&feed=default&country=IL&account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D"],
            ["label":"Jackets","gender":"female","b0":[0.319490909576416, 0.2713195383548737],"b1":[0.6690635085105896, 0.4435304701328278],
             "offers":"//d1wt9iscpot47x.cloudfront.net/offers?image_url=aHR0cHM6Ly9zMy5hbWF6b25hd3MuY29tL3MzLWZpbGUtc3RvcmUvZ2VuZXJhdGVkLy1oSkV0ZXByLTBjdHZqV3J0QXMyOA%3D%3D&crop=eyJ5MiI6MC40NTQyMTExNzU0NDE3NDE5NCwieSI6MC4yNjA2Mzg4MzMwNDU5NTk1LCJ4MiI6MC42OTA3NDQ0MDAwMjQ0MTQxLCJ4IjowLjI5NzgxMDA3NzY2NzIzNjMzfQ%3D%3D&cats=WyJDb2F0c0phY2tldHNTdWl0cyJd&prob=0.7578&gender=female&feed=default&country=IL&account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D"],
            ["label":"Skirts","gender":"female","b0":[0.3360975980758667, 0.3655535876750946],"b1":[0.7115286588668823, 0.6397957801818848],
             "offers":"//d1wt9iscpot47x.cloudfront.net/offers?image_url=aHR0cHM6Ly9zMy5hbWF6b25hd3MuY29tL3MzLWZpbGUtc3RvcmUvZ2VuZXJhdGVkLy1oSkV0ZXByLTBjdHZqV3J0QXMyOA%3D%3D&crop=eyJ5MiI6MC42NDk5OTM1OTg0NjExNTExLCJ5IjowLjM1NTM1NTc5OTE5ODE1MDYzLCJ4MiI6MC43MjU0ODkxOTkxNjE1Mjk1LCJ4IjowLjMyMjEzNzA1Nzc4MTIxOTV9&cats=WyJTa2lydHMiXQ%3D%3D&prob=0.8272&gender=female&feed=default&country=IL&account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D"]
        ]
        return (imageURL, segments)
    }
}

extension Screenshot {
    
    public func share() -> Promise<String> {
        if let shareLink = self.shareLink {
            return Promise(value: shareLink)
        }
        guard let assetId = self.assetId else {
            let error = NSError(domain: "Craze", code: 14, userInfo: [NSLocalizedDescriptionKey: "share with no assetId"])
            print(error)
            return Promise(error: error)
        }
        let dataModel = DataModel.sharedInstance
        let assetSyncModel = AssetSyncModel.sharedInstance
        return firstly { _ -> Promise<(String, String)> in
            // Post to Craze server, which returns deep share link.
            return self.shareOrReshare()
            }.then(on: assetSyncModel.processingQ) { shareId, shareLink -> Promise<String> in
                // Return the promise as soon as we have the shareLink, and concurrently or afterwards save shareLink to DB.
                NSLog("shareId:\(shareId)  shareLink:\(shareLink)")
                dataModel.performBackgroundTask { (managedObjectContext) in
                    if let screenshot = dataModel.retrieveScreenshot(managedObjectContext: managedObjectContext, assetId: assetId) {
                        screenshot.shareLink = shareLink
                        managedObjectContext.saveIfNeeded()
                    }
                }
                return Promise(value: shareLink)
        }
    }
    
    private func shareOrReshare() -> Promise<(String, String)> {
        let userName = UserDefaults.standard.string(forKey: UserDefaultsKeys.name)
        if self.isFromShare {
            return NetworkingPromise.sharedInstance.reshare(userName: userName, shareId: self.assetId)
        } else {
            return NetworkingPromise.sharedInstance.share(userName: userName, imageURLString: self.uploadedImageURL, syteJson: self.syteJson)
        }
    }
    
     public func shareViaLink() -> AnyPromise {
        return AnyPromise(share())
    }
    
    public func submitToDiscover(){
        let screenshot = self
        let now = NSDate()
        if let image = screenshot.uploadedImageURL {
            let objectId = screenshot.objectID
            let promise = NetworkingPromise.sharedInstance.submitToDiscover(image: image, userName: AnalyticsUser.current.name, intercomUserId: AnalyticsUser.current.identifier, email: AnalyticsUser.current.email)
            
            promise.then { (dictionary) -> Void in
                DataModel.sharedInstance.performBackgroundTask { (context) in
                    if let screenshot = context.screenshotWith(objectId:objectId) {
                        if let screenshotId = dictionary["screenshotId"] as? String {
                            
                            screenshot.screenshotId = screenshotId
                        }
                        screenshot.submittedDate = now
                    }
                }
            }
        }
    }
    var canSubmitToDiscover:Bool {
        get{
            return (source == .gallery || source == .share) && submittedDate == nil
        }
    }
    
}
