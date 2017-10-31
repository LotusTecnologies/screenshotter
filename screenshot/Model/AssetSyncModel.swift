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
    
    private var newScreenshotsCount: Int = UserDefaults.standard.integer(forKey: UserDefaultsKeys.newScreenshotsCount)
    
    @objc public func getNewScreenshotsCount() -> Int {
        return newScreenshotsCount
    }
    
    @objc public func resetNewScreenshotsCount() {
        newScreenshotsCount = 0
        UserDefaults.standard.set(newScreenshotsCount, forKey: UserDefaultsKeys.newScreenshotsCount)
    }
    
    fileprivate func addToNewScreenshots(count: Int) {
        newScreenshotsCount += count
        UserDefaults.standard.set(newScreenshotsCount, forKey: UserDefaultsKeys.newScreenshotsCount)
    }
    
}

class AssetSyncModel: NSObject {

    public static let sharedInstance = AssetSyncModel()
    public weak var networkingIndicatorDelegate: NetworkingIndicatorProtocol?
    var futureScreenshotAssets: PHFetchResult<PHAsset>?
    var selectedScreenshotAssets = Set<PHAsset>()
//    var changedAssetIds: [String] = []
    var incomingDynamicLinks: [String] = []
    let serialQ = DispatchQueue(label: "io.crazeapp.screenshot.syncPhotos.serial")
    let processingQ = DispatchQueue.global(qos: .default) // .utility // DispatchQueue(label: "io.crazeapp.screenshot.syncPhotos.processing")
    var isRegistered = false
    var isSyncing = false
    var shouldSyncAgain = false
    var screenshotsToProcess: Int = 0
    var shoppablesToProcess: Int = 0
    
    let imageMediaType = kUTTypeImage as String;
    
    override init() {
        super.init()
        registerForPhotoChanges()
    }
    
    func registerForPhotoChanges() {
        guard PermissionsManager.shared().hasPermission(for: .photo) else {
            print("registerForPhotoChanges refused by guard")
            return
        }
        PHPhotoLibrary.shared().register(self)
        isRegistered = true
    }
    
    func uploadScreenshotWithClarifai(asset: PHAsset) {
        let dataModel = DataModel.sharedInstance
        firstly {
            return image(asset: asset)
            }.then (on: processingQ) { image -> Promise<(Bool, UIImage)> in
                track("sent image to Clarifai")
                return ClarifaiModel.sharedInstance.isFashion(image: image)
            }.then(on: processingQ) { isFashion, image -> Promise<Bool> in
                track("received response from Clarifai", properties: ["isFashion" : isFashion])
                let imageData: Data? = isFashion ? self.data(for: image) : nil
                return Promise { fulfill, reject in
                    dataModel.performBackgroundTask { (managedObjectContext) in
                        let _ = dataModel.saveScreenshot(managedObjectContext: managedObjectContext,
                                                         assetId: asset.localIdentifier,
                                                         createdAt: asset.creationDate,
                                                         isFashion: isFashion,
                                                         isFromShare: false,
                                                         isHidden: true,
                                                         imageData: imageData)
                        fulfill(isFashion)
                    }
                }
            }.then (on: processingQ) { isFashion -> Void in
                if isFashion {
                    self.sendScreenshotAddedLocalNotification(assetId: asset.localIdentifier)
                }
            }.always(on: self.serialQ) {
                self.decrementScreenshots()
            }.catch { error in
                print("uploadScreenshotWithClarifai catch error:\(error)")
        }
    }
    
    func uploadPhotoBypassClarifai(asset: PHAsset) {
        let dataModel = DataModel.sharedInstance
        firstly {
            return image(asset: asset)
            }.then(on: processingQ) { image -> Promise<Data?> in
                track("bypassed Clarifai")
                let imageData: Data? = self.data(for: image)
                return Promise { fulfill, reject in
                    dataModel.performBackgroundTask { (managedObjectContext) in
                        let _ = dataModel.saveScreenshot(managedObjectContext: managedObjectContext,
                                                         assetId: asset.localIdentifier,
                                                         createdAt: asset.creationDate,
                                                         isFashion: true,
                                                         isFromShare: false,
                                                         isHidden: false,
                                                         imageData: imageData)
                        fulfill(imageData)
                    }
                }
            }.then (on: processingQ) { imageData -> Void in
                self.syteProcessing(shouldProcess: true, imageData: imageData, assetId: asset.localIdentifier)
            }.always(on: self.serialQ) {
                self.decrementScreenshots()
            }.catch { error in
                print("uploadPhotoBypassClarifai outer catch error:\(error)")
        }
    }
    
    func retryScreenshot(asset: PHAsset) {
        let dataModel = DataModel.sharedInstance
        firstly {
            return image(asset: asset)
            }.then (on: processingQ) { image -> Promise<Data?> in
                track("bypassed Clarifai on retry")
                let imageData = self.data(for: image)
                return Promise(value: imageData)
            }.then (on: processingQ) { imageData -> Promise<(Data?, Bool)> in
                return Promise { fulfill, reject in
                    dataModel.performBackgroundTask { (managedObjectContext) in
                        if let screenshot = dataModel.retrieveScreenshot(managedObjectContext: managedObjectContext, assetId: asset.localIdentifier) {
                            if screenshot.imageData == nil {
                                screenshot.imageData = imageData as NSData?
                            }
                            screenshot.isHidden = false
                            screenshot.isFashion = true
                            screenshot.lastModified = NSDate()
                            if screenshot.shoppablesCount < 0 {
                                screenshot.shoppablesCount = 0
                            }
                            dataModel.saveMoc(managedObjectContext: managedObjectContext)
                            fulfill((imageData, screenshot.shoppablesCount <= 0))
                        } else {
                            let error = NSError(domain: "Craze", code: 18, userInfo: [NSLocalizedDescriptionKey : "Could not retreive screenshot with assetId:\(asset.localIdentifier)"])
                            reject(error)
                        }
                    }
                }
            }.then (on: processingQ) { (imageData, shouldProcess) -> Void in
                print("retryScreenshot shouldProcess:\(shouldProcess)")
                self.syteProcessing(shouldProcess: shouldProcess, imageData: imageData, assetId: asset.localIdentifier)
            }.always(on: self.serialQ) {
                self.decrementScreenshots()
            }.catch { error in
                print("retryScreenshot catch error:\(error)")
        }
    }
    
    func syteProcessing(shouldProcess: Bool, imageData: Data?, assetId: String) {
        if shouldProcess {
            DispatchQueue.main.async {
                self.networkingIndicatorDelegate?.networkingIndicatorDidStart(type: .Product)
            }
            firstly { _ -> Promise<(String, [[String : Any]])> in
                return NetworkingPromise.uploadToSyte(imageData: imageData)
                }.then(on: self.processingQ) { uploadedURLString, segments -> Void in
                    track("received response from Syte", properties: ["segmentCount" : segments.count])
                    self.saveShoppables(assetId: assetId, uploadedURLString: uploadedURLString, segments: segments)
                }.always {
                    self.networkingIndicatorDelegate?.networkingIndicatorDidComplete(type: .Product)
                }.catch { error in
                    let nsError = error as NSError
                    if nsError.domain == "Craze" {
                        switch nsError.code {
                        case 3, 4:
                            // Syte returned no segments
                            let uploadedURLString = nsError.userInfo[Constants.uploadedURLStringKey] as? String
                            DataModel.sharedInstance.setNoShoppables(assetId: assetId, uploadedURLString: uploadedURLString)
                        default:
                            break
                        }
                    }
                    print("uploadScreenshot inner uploadToSyte catch error:\(error)")
            }
        }
    }
    
    func decrementScreenshots() {
        self.screenshotsToProcess -= 1
        if self.screenshotsToProcess == 0 {
            DispatchQueue.main.async {
                self.networkingIndicatorDelegate?.networkingIndicatorDidComplete(type: .Screenshot)
            }
            self.endSync()
        } else if self.screenshotsToProcess < 0 {
            print("WTF? negative screenshotsToProcess:\(self.screenshotsToProcess) after subtracting one")
        }
    }
    
    func downloadScreenshot(shareId: String) {
        let dataModel = DataModel.sharedInstance
        firstly { _ -> Promise<[String : Any]> in
            // Get screenshot dict from Craze server.
            // See end https://docs.google.com/document/d/12_IrBskNTGY8zQSM88uA6h0QjLnUtZF7yiUdzv0nxT8/
            // and https://docs.google.com/document/d/16WsJMepl0Z3YrsRKxcFqkASUieRLKy_Aei8lmbpD2bo
            guard let encoded = shareId.addingPercentEncoding(withAllowedCharacters: .alphanumerics),
              let screenshotInfoUrl = URL(string: Constants.screenShotLambdaDomain + "shares/" + encoded) else {
                    let urlError = NSError(domain: "Craze", code: 8, userInfo: [NSLocalizedDescriptionKey : "Could not form URL from shareId:\(shareId)"])
                    return Promise(error: urlError)
            }
            print("downloadScreenshot shareId:\(shareId)  encode:\(encoded)  screenshotInfoUrl:\(screenshotInfoUrl)")
            return NetworkingPromise.downloadInfo(url: screenshotInfoUrl)
            }.then(on: self.processingQ) { jsonDict -> Promise<(Data, [String : Any])> in
                // Download image from Syte S3.
                guard let share = jsonDict["share"] as? [String : Any],
                  let screenshotDict = share["screenshot"] as? [String : Any],
                  let imageURLString = screenshotDict["image"] as? String,
                  let imageURL = URL(string: imageURLString) else {
                        let imageURLError = NSError(domain: "Craze", code: 9, userInfo: [NSLocalizedDescriptionKey : "Could not form image URL from jsonDict:\(jsonDict)"])
                        return Promise(error: imageURLError)
                }
                return NetworkingPromise.downloadImage(url: imageURL, screenshotDict: screenshotDict)
            }.then(on: self.processingQ) { imageData, screenshotDict -> Promise<(NSManagedObject, [String : Any])> in
                // Save screenshot to db.
                guard let screenshotId = screenshotDict["id"] as? String else {
                    let error = NSError(domain: "Craze", code: 15, userInfo: [NSLocalizedDescriptionKey : "Could not form screenshotId from screenshotDict:\(screenshotDict)"])
                    return Promise(error: error)
                }
                return dataModel.backgroundPromise(dict: screenshotDict) { (managedObjectContext) -> NSManagedObject in
                    return dataModel.saveScreenshot(managedObjectContext: managedObjectContext,
                                                    assetId: screenshotId,
                                                    createdAt: Date(),
                                                    isFashion: true,
                                                    isFromShare: true,
                                                    isHidden: false,
                                                    imageData: imageData)
                }
            }.then(on: self.processingQ) { screenshotManagedObject, screenshotDict -> Void in
                // Save shoppables to db.
                guard let screenshotId = screenshotDict["id"] as? String,
                  let syteJsonString = screenshotDict["syteJson"] as? String,
                  let segments = NetworkingPromise.jsonDestringify(string: syteJsonString),
                  let imageURLString = screenshotDict["image"] as? String else {
                    let jsonError = NSError(domain: "Craze", code: 10, userInfo: [NSLocalizedDescriptionKey : "Could not extract syteJson from screenshotDict:\(screenshotDict)"])
                    print(jsonError)
                    return
                }
                self.saveShoppables(assetId: screenshotId, uploadedURLString: imageURLString, segments: segments)
            }.always(on: self.serialQ) {
                self.decrementScreenshots()
            }.catch { error in
                print("downloadScreenshot catch error:\(error)")
        }
    }
    
    func tupleForRatio17750() -> (String, [[String : Any]]) {
        let imageURL = "https://s3.amazonaws.com/s3-file-store/generated/1nfaMAuRYUUcVz1SZJmN6"
        let segments = [
            ["label":"Bags","gender":"female","b0":[0.3559979498386383,0.5867233872413635],"b1":[0.4344922006130219,0.6679672598838806],
             "offers":"//d1wt9iscpot47x.cloudfront.net/offers?image_url=aHR0cHM6Ly9zMy5hbWF6b25hd3MuY29tL3MzLWZpbGUtc3RvcmUvZ2VuZXJhdGVkLzFuZmFNQXVSWVVVY1Z6MVNaSm1ONg%3D%3D&crop=eyJ5MiI6MC42Njg5ODI4MDgyOTE5MTIsInkiOjAuNTg1NzA3ODM4ODMzMzMyMSwieDIiOjAuNDM1NDczMzc4NzQ3NzAxNjQsIngiOjAuMzU1MDE2NzcxNzAzOTU4NX0%3D&cats=WyJIYW5kYmFncyJd&prob=0.4663&gender=female&feed=default&country=IL&account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D"],
            ["label":"Jackets","gender":"female","b0":[0.3828337788581848,0.4187996685504913],"b1":[0.6517795920372009,0.5956178903579712],
             "offers":"//d1wt9iscpot47x.cloudfront.net/offers?image_url=aHR0cHM6Ly9zMy5hbWF6b25hd3MuY29tL3MzLWZpbGUtc3RvcmUvZ2VuZXJhdGVkLzFuZmFNQXVSWVVVY1Z6MVNaSm1ONg%3D%3D&crop=eyJ5MiI6MC41OTc4MjgxMTgxMzA1NjQ3LCJ5IjowLjQxNjU4OTQ0MDc3Nzg5NzgzLCJ4MiI6MC42NTUxNDE0MTQ3MDE5Mzg3LCJ4IjowLjM3OTQ3MTk1NjE5MzQ0NzE1fQ%3D%3D&cats=WyJDb2F0c0phY2tldHNTdWl0cyJd&prob=0.6450&gender=female&feed=default&country=IL&account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D"],
            ["label":"Shirts","gender":"female","b0":[0.4629025161266327,0.4479158520698547],"b1":[0.5702998638153076,0.5158113837242126],
             "offers":"//d1wt9iscpot47x.cloudfront.net/offers?image_url=aHR0cHM6Ly9zMy5hbWF6b25hd3MuY29tL3MzLWZpbGUtc3RvcmUvZ2VuZXJhdGVkLzFuZmFNQXVSWVVVY1Z6MVNaSm1ONg%3D%3D&crop=eyJ5MiI6MC41MTY2NjAwNzc4Njk4OTIxLCJ5IjowLjQ0NzA2NzE1NzkyNDE3NTMsIngyIjowLjU3MTY0MjMzMDY2MTQxNiwieCI6MC40NjE1NjAwNDkyODA1MjQyNH0%3D&cats=WyJQdWxsb3ZlckFuZFNoaXJ0cyJd&prob=0.5469&gender=female&feed=default&country=IL&account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D"],
            ["label":"Skirts","gender":"female","b0":[0.3978304862976074,0.5245752334594727],"b1":[0.6558108329772949,0.7177786827087402],
             "offers":"//d1wt9iscpot47x.cloudfront.net/offers?image_url=aHR0cHM6Ly9zMy5hbWF6b25hd3MuY29tL3MzLWZpbGUtc3RvcmUvZ2VuZXJhdGVkLzFuZmFNQXVSWVVVY1Z6MVNaSm1ONg%3D%3D&crop=eyJ5MiI6MC43MjAxOTM3MjU4MjQzNTYsInkiOjAuNTIyMTYwMTkwMzQzODU2OSwieDIiOjAuNjU5MDM1NTg3MzEwNzkxLCJ4IjowLjM5NDYwNTczMTk2NDExMTM2fQ%3D%3D&cats=WyJTa2lydHMiXQ%3D%3D&prob=0.7699&gender=female&feed=default&country=IL&account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D"],
           ["label":"Shoes","gender":"female","b0":[0.5260283350944519,0.7322256565093994],"b1":[0.5960294604301453,0.782284140586853],
             "offers":"//d1wt9iscpot47x.cloudfront.net/offers?image_url=aHR0cHM6Ly9zMy5hbWF6b25hd3MuY29tL3MzLWZpbGUtc3RvcmUvZ2VuZXJhdGVkLzFuZmFNQXVSWVVVY1Z6MVNaSm1ONg%3D%3D&crop=eyJ5MiI6MC43ODI5MDk4NzE2Mzc4MjEyLCJ5IjowLjczMTU5OTkyNTQ1ODQzMTIsIngyIjowLjU5NjkwNDQ3NDQ5Njg0MTUsIngiOjAuNTI1MTUzMzIxMDI3NzU1N30%3D&cats=WyJCb290cyIsIkZsYXRTYW5kYWxzIiwiRmxhdFNob2VzIiwiSGVlbFNhbmRhbHMiLCJIZWVsU2hvZXMiLCJTcG9ydFNob2VzIl0%3D&prob=0.5192&gender=female&feed=default&country=IL&account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D"],
            ["label":"Shoes","gender":"female","b0":[0.420631468296051,0.7285764217376709],"b1":[0.4867706298828125,0.7937597036361694],
             "offers":"//d1wt9iscpot47x.cloudfront.net/offers?image_url=aHR0cHM6Ly9zMy5hbWF6b25hd3MuY29tL3MzLWZpbGUtc3RvcmUvZ2VuZXJhdGVkLzFuZmFNQXVSWVVVY1Z6MVNaSm1ONg%3D%3D&crop=eyJ5MiI6MC43OTQ1NzQ0OTQ2NTk5MDA3LCJ5IjowLjcyNzc2MTYzMDcxMzkzOTYsIngyIjowLjQ4NzU5NzM2OTQwMjY0NzAzLCJ4IjowLjQxOTgwNDcyODc3NjIxNjV9&cats=WyJCb290cyIsIkZsYXRTYW5kYWxzIiwiRmxhdFNob2VzIiwiSGVlbFNhbmRhbHMiLCJIZWVsU2hvZXMiLCJTcG9ydFNob2VzIl0%3D&prob=0.6263&gender=female&feed=default&country=IL&account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D"]
        ]
        return (imageURL, segments)
    }
    
    func tupleForRatio17777() -> (String, [[String : Any]]) {
        let imageURL = "https://s3.amazonaws.com/s3-file-store/generated/WB42KwmBD9R5PBlwBJcc4"
        let segments = [
            ["label":"Dresses","gender":"female","b0":[0.3939443826675415,0.4749177694320679],"b1":[0.6968114376068115,0.7054287195205688],
             "offers":"//d1wt9iscpot47x.cloudfront.net/offers?image_url=aHR0cHM6Ly9zMy5hbWF6b25hd3MuY29tL3MzLWZpbGUtc3RvcmUvZ2VuZXJhdGVkL1dCNDJLd21CRDlSNVBCbHdCSmNjNA%3D%3D&crop=eyJ5MiI6MC43MDgzMTAxMDYzOTY2NzUxLCJ5IjowLjQ3MjAzNjM4MjU1NTk2MTY0LCJ4MiI6MC43MDA1OTcyNzU3OTM1NTI0LCJ4IjowLjM5MDE1ODU0NDQ4MDgwMDZ9&cats=WyJEcmVzc2VzIiwiTmlnaHRNb3JuaW5nRHJlc3NlcyJd&prob=0.4820&gender=female&feed=default&country=IL&account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D"],
            ["label":"Jackets","gender":"female","b0":[0.3839874267578125,0.4090573787689209],"b1":[0.6477440595626831,0.5754011273384094],
             "offers":"//d1wt9iscpot47x.cloudfront.net/offers?image_url=aHR0cHM6Ly9zMy5hbWF6b25hd3MuY29tL3MzLWZpbGUtc3RvcmUvZ2VuZXJhdGVkL1dCNDJLd21CRDlSNVBCbHdCSmNjNA%3D%3D&crop=eyJ5MiI6MC41Nzc0ODA0MjQxOTU1MjgsInkiOjAuNDA2OTc4MDgxOTExODAyMywieDIiOjAuNjUxMDQxMDE3NDcyNzQ0LCJ4IjowLjM4MDY5MDQ2ODg0Nzc1MTY1fQ%3D%3D&cats=WyJDb2F0c0phY2tldHNTdWl0cyJd&prob=0.4667&gender=female&feed=default&country=IL&account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D"],
            ["label":"Shoes","gender":"female","b0":[0.5229871273040771,0.7103928923606873],"b1":[0.5969663858413696,0.7615106701850891],
             "offers":"//d1wt9iscpot47x.cloudfront.net/offers?image_url=aHR0cHM6Ly9zMy5hbWF6b25hd3MuY29tL3MzLWZpbGUtc3RvcmUvZ2VuZXJhdGVkL1dCNDJLd21CRDlSNVBCbHdCSmNjNA%3D%3D&crop=eyJ5MiI6MC43NjIxNDk2NDI0MDc4OTQyLCJ5IjowLjcwOTc1MzkyMDEzNzg4MjIsIngyIjowLjU5Nzg5MTEyNjU3MzA4NTcsIngiOjAuNTIyMDYyMzg2NTcyMzYxfQ%3D%3D&cats=WyJCb290cyIsIkZsYXRTYW5kYWxzIiwiRmxhdFNob2VzIiwiSGVlbFNhbmRhbHMiLCJIZWVsU2hvZXMiLCJTcG9ydFNob2VzIl0%3D&prob=0.5856&gender=female&feed=default&country=IL&account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D"],
            ["label":"Shoes","gender":"female","b0":[0.4234914183616638,0.712901771068573],"b1":[0.4835497140884399,0.7732203602790833],
             "offers":"//d1wt9iscpot47x.cloudfront.net/offers?image_url=aHR0cHM6Ly9zMy5hbWF6b25hd3MuY29tL3MzLWZpbGUtc3RvcmUvZ2VuZXJhdGVkL1dCNDJLd21CRDlSNVBCbHdCSmNjNA%3D%3D&crop=eyJ5MiI6MC43NzM5NzQzNDI2NDQyMTQ2LCJ5IjowLjcxMjE0Nzc4ODcwMzQ0MTYsIngyIjowLjQ4NDMwMDQ0Mjc4NTAyNDY1LCJ4IjowLjQyMjc0MDY4OTY2NTA3OTF9&cats=WyJCb290cyIsIkZsYXRTYW5kYWxzIiwiRmxhdFNob2VzIiwiSGVlbFNhbmRhbHMiLCJIZWVsU2hvZXMiLCJTcG9ydFNob2VzIl0%3D&prob=0.6671&gender=female&feed=default&country=IL&account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D"]
        ]
        return (imageURL, segments)
    }
    
    func tupleForRatio17786() -> (String, [[String : Any]]) {
        let imageURL = "https://s3.amazonaws.com/s3-file-store/generated/Lb7vNFNqo_YLrpG4SZjHW"
        let segments = [
            ["label":"Dresses","gender":"female","b0":[0.3925015330314636,0.4712252020835876],"b1":[0.6986575722694397,0.7028000950813293],
             "offers":"//d1wt9iscpot47x.cloudfront.net/offers?image_url=aHR0cHM6Ly9zMy5hbWF6b25hd3MuY29tL3MzLWZpbGUtc3RvcmUvZ2VuZXJhdGVkL0xiN3ZORk5xb19ZTHJwRzRTWmpIVw%3D%3D&crop=eyJ5MiI6MC43MDU2OTQ3ODEyNDM4MDExLCJ5IjowLjQ2ODMzMDUxNTkyMTExNTksIngyIjowLjcwMjQ4NDUyMjc1OTkxNDQsIngiOjAuMzg4Njc0NTgyNTQwOTg4OX0%3D&cats=WyJEcmVzc2VzIiwiTmlnaHRNb3JuaW5nRHJlc3NlcyJd&prob=0.5303&gender=female&feed=default&country=IL&account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D"],
            ["label":"Jackets","gender":"female","b0":[0.3785334825515747,0.4049455225467682],"b1":[0.6530630588531494,0.5816818475723267],
             "offers":"//d1wt9iscpot47x.cloudfront.net/offers?image_url=aHR0cHM6Ly9zMy5hbWF6b25hd3MuY29tL3MzLWZpbGUtc3RvcmUvZ2VuZXJhdGVkL0xiN3ZORk5xb19ZTHJwRzRTWmpIVw%3D%3D&crop=eyJ5MiI6MC41ODM4OTEwNTE2MzUxNDYxLCJ5IjowLjQwMjczNjMxODQ4Mzk0ODcsIngyIjowLjY1NjQ5NDY3ODU1NjkxOTEsIngiOjAuMzc1MTAxODYyODQ3ODA1MDZ9&cats=WyJDb2F0c0phY2tldHNTdWl0cyJd&prob=0.5320&gender=female&feed=default&country=IL&account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D"],
            ["label":"Shoes","gender":"female","b0":[0.5189570784568787,0.7087295651435852], "b1":[0.5980026125907898,0.7619832158088684],
             "offers":"//d1wt9iscpot47x.cloudfront.net/offers?image_url=aHR0cHM6Ly9zMy5hbWF6b25hd3MuY29tL3MzLWZpbGUtc3RvcmUvZ2VuZXJhdGVkL0xiN3ZORk5xb19ZTHJwRzRTWmpIVw%3D%3D&crop=eyJ5MiI6MC43NjI2NDg4ODY0NDIxODQ0LCJ5IjowLjcwODA2Mzg5NDUxMDI2OTIsIngyIjowLjU5ODk5MDY4MTc2NzQ2MzcsIngiOjAuNTE3OTY5MDA5MjgwMjA0N30%3D&cats=WyJCb290cyIsIkZsYXRTYW5kYWxzIiwiRmxhdFNob2VzIiwiSGVlbFNhbmRhbHMiLCJIZWVsU2hvZXMiLCJTcG9ydFNob2VzIl0%3D&prob=0.5862&gender=female&feed=default&country=IL&account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D"],
            ["label":"Shoes","gender":"female","b0":[0.4238345623016357,0.7074891328811646],"b1":[0.4840186834335327,0.7699545621871948],
             "offers":"//d1wt9iscpot47x.cloudfront.net/offers?image_url=aHR0cHM6Ly9zMy5hbWF6b25hd3MuY29tL3MzLWZpbGUtc3RvcmUvZ2VuZXJhdGVkL0xiN3ZORk5xb19ZTHJwRzRTWmpIVw%3D%3D&crop=eyJ5MiI6MC43NzA3MzUzODAwNTM1MjAyLCJ5IjowLjcwNjcwODMxNTAxNDgzOTIsIngyIjowLjQ4NDc3MDk4NDk0NzY4MTQ1LCJ4IjowLjQyMzA4MjI2MDc4NzQ4N30%3D&cats=WyJCb290cyIsIkZsYXRTYW5kYWxzIiwiRmxhdFNob2VzIiwiSGVlbFNhbmRhbHMiLCJIZWVsU2hvZXMiLCJTcG9ydFNob2VzIl0%3D&prob=0.6999&gender=female&feed=default&country=IL&account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D"]
        ]
        return (imageURL, segments)
    }
    
    func tupleByAspectRatio() -> (String, [[String : Any]]) {
        let nativeSize = UIScreen.main.nativeBounds.size
        let deviceAspectRatio = nativeSize.height / nativeSize.width
        let aspectRatio5Digit = Int(deviceAspectRatio * 10000)
        print("nativeSize:\(nativeSize)  aspectRatio5Digit:\(aspectRatio5Digit)  deviceAspectRatio:\(deviceAspectRatio)")
        switch aspectRatio5Digit {
        case 17750: // iPhone 5C,5,5S
            return self.tupleForRatio17750()
        case 17777: // iPhone 6+,6S+,7+
            return self.tupleForRatio17777()
        case 17786: // iPhone 6,6S,7,8
            return self.tupleForRatio17786()
        default:
            return self.tupleForRatio17750()
        }
    }
    
    func saveShoppables(assetId: String, uploadedURLString: String, segments: [[String : Any]]) { //-> Promise<[String]> {
        for segment in segments {
            guard let offersURL = segment["offers"] as? String,
                let url = URL(string: offersURL.hasPrefix("//") ? "https:" + offersURL : offersURL),
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
                                 url: url,
                                 label: label,
                                 b0x: b0x,
                                 b0y: b0y,
                                 b1x: b1x,
                                 b1y: b1y)
        }
    }

    func extractProducts(assetId: String,
                         uploadedURLString: String,
                         segments: [[String : Any]],
                         url: URL,
                         label: String?,
                         b0x: Double,
                         b0y: Double,
                         b1x: Double,
                         b1y: Double) {
        firstly {
            NetworkingPromise.downloadInfo(url: url)
            }.then(on: self.processingQ) { productsDict -> Void in
                if let productsArray = productsDict["ads"] as? [[String : Any]], productsArray.count > 0 {
                    let dataModel = DataModel.sharedInstance
                    dataModel.performBackgroundTask { (managedObjectContext) in
                        if let screenshot = dataModel.retrieveScreenshot(managedObjectContext: managedObjectContext, assetId: assetId) {
                            let shoppable = dataModel.saveShoppable(managedObjectContext: managedObjectContext,
                                                                    screenshot: screenshot,
                                                                    label: label,
                                                                    offersURL: url.absoluteString,
                                                                    b0x: b0x,
                                                                    b0y: b0y,
                                                                    b1x: b1x,
                                                                    b1y: b1y)
                            var productOrder: Int16 = 0
                            for prod in productsArray {
                                var floatPrice: Float = 0 // -1 ?
                                if let extractedFloatPrice = prod["floatPrice"] as? Float {
                                    floatPrice = extractedFloatPrice
                                }
                                var floatOriginalPrice: Float = 0 // -1 ?
                                if let extractedOriginalFloatPrice = prod["floatOriginalPrice"] as? Float {
                                    floatOriginalPrice = extractedOriginalFloatPrice
                                }
                                var categories: String?
                                if let extractedCategories = prod["categories"] as? [String] {
                                    categories = extractedCategories.first
                                }
                                let _ = dataModel.saveProduct(managedObjectContext: managedObjectContext,
                                                              shoppable: shoppable,
                                                              order: productOrder,
                                                              productDescription: prod["description"] as? String,
                                                              price: prod["price"] as? String,
                                                              originalPrice: prod["originalPrice"] as? String,
                                                              floatPrice: floatPrice,
                                                              floatOriginalPrice: floatOriginalPrice,
                                                              categories: categories,
                                                              brand: prod["brand"] as? String,
                                                              offer: prod["offer"] as? String,
                                                              imageURL: prod["imageUrl"] as? String,
                                                              merchant: prod["merchant"] as? String)
                                productOrder += 1
                            }
                            shoppable.productCount = productOrder
                            if shoppable.productCount > 0 {
                                screenshot.shoppablesCount += 1
                                if screenshot.shoppablesCount == 1 {
                                    screenshot.syteJson = NetworkingPromise.jsonStringify(object: segments)
                                    screenshot.uploadedImageURL = uploadedURLString
                                }
                                dataModel.saveMoc(managedObjectContext: managedObjectContext)
                            } else {
                                print("AssetSyncModel extractProducts empty productsArray. productsDict:\(productsDict)\noffersUrl:\(url)")
                            }
                        } else {
                            print("AssetSyncModel extractProducts error retreiving screenshot:\(assetId) to which to add shoppable and products")
                        }
                    }
                } else {
                    print("AssetSyncModel extractProducts no products in ads. productsDict:\(productsDict)")
                }
            }.catch { error in
                print("AssetSyncModel extractProducts error parsing product:\(error)")
        }
    }
    
    func image(assetId: String, callback: @escaping ((UIImage?, [AnyHashable : Any]?) -> Void)) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 1;
        
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: fetchOptions)
        
        guard let asset = assets.firstObject else {
            print("No asset for assetId:\(assetId)")
            callback(nil, nil)
            return
        }
        image(asset: asset, callback: callback)
    }
    
    func image(asset: PHAsset, callback: @escaping ((UIImage?, [AnyHashable : Any]?) -> Void)) {
        let imageRequestOptions = PHImageRequestOptions()
        imageRequestOptions.isSynchronous = false
        imageRequestOptions.version = .current
        imageRequestOptions.deliveryMode = .opportunistic
        imageRequestOptions.resizeMode = .none
        imageRequestOptions.isNetworkAccessAllowed = false
        let targetSize = self.targetSize()
        PHImageManager.default().requestImage(for: asset,
                                              targetSize: targetSize,
                                              contentMode: .aspectFill,
                                              options: imageRequestOptions,
                                              resultHandler: { (image: UIImage?, info: [AnyHashable : Any]?) in
                                                callback(image, info)
        })
    }
    
    func image(asset: PHAsset) -> Promise<UIImage> {
        return Promise { fulfill, reject in
            image(asset: asset, callback: { (image: UIImage?, info: [AnyHashable : Any]?) in
                if let imageError = info?[PHImageErrorKey] as? NSError {
                    reject(imageError)
                    return
                }
                if let isCancelled = info?[PHImageCancelledKey] as? Bool,
                    isCancelled == true {
                    let cancelledError = NSError(domain: "Craze", code: 7, userInfo: [NSLocalizedDescriptionKey : "Image request canceled"])
                    reject(cancelledError)
                    return
                }
                if let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool,
                    isDegraded == true {
                    // This callback will be called again with a better quality image.
                    return
                }
                if let image = image {
                    fulfill(image)
                } else {
                    let emptyError = NSError(domain: "Craze", code: 2, userInfo: [NSLocalizedDescriptionKey : "Asset returned no image"])
                    reject(emptyError)
                }
            })
        }
    }
    
    func targetSize() -> CGSize {
        let screenSizePx = UIScreen.main.nativeBounds.size
        let targetSize = CGSize(width: screenSizePx.width / 2, height: screenSizePx.height / 2)
        return targetSize
    }
    
    func data(for image: UIImage) -> Data? {
        let actualToTargetRatio = image.size.width / targetSize().width
        let compressionQuality: CGFloat
        switch actualToTargetRatio {
        case 0..<0.8:
            compressionQuality = 0.99
        case 2.0..<4.0:
            compressionQuality = 0.25
        case 4.0...:
            compressionQuality = 0.10
        default:
            compressionQuality = 0.75
        }
        let data = UIImageJPEGRepresentation(image, compressionQuality)
        print("image.size:\(image.size)  targetSize:\(targetSize())  actualToTargetRatio:\(actualToTargetRatio)  compressionQuality:\(compressionQuality)  data.count:\(data?.count ?? 0)")
        return data
    }
    
    func setupFutureScreenshotAssets() {
        let fetchOptions = PHFetchOptions()
        var installDate: NSDate
        if let UserDefaultsInstallDate = UserDefaults.standard.object(forKey: UserDefaultsKeys.dateInstalled) as? NSDate {
            installDate = UserDefaultsInstallDate
        } else {
            installDate = NSDate()
            UserDefaults.standard.set(installDate, forKey: UserDefaultsKeys.dateInstalled)
        }
        fetchOptions.predicate = NSPredicate(format: "creationDate >= %@ AND (mediaSubtype & %d) != 0", installDate, PHAssetMediaSubtype.photoScreenshot.rawValue)
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 100
        futureScreenshotAssets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
    }
    
    func retrieveFutureScreenshotAssetIds() -> Set<String> {
        setupFutureScreenshotAssets()
        var assetIds = Set<String>()
        futureScreenshotAssets?.enumerateObjects({ (asset: PHAsset, index: Int, stop: UnsafeMutablePointer<ObjCBool>) in
            assetIds.insert(asset.localIdentifier)
        })
        return assetIds
    }
    
    func retrieveSelectedScreenshotAssetIds() -> Set<String> {
        let assetIdArray = selectedScreenshotAssets.map { $0.localIdentifier }
        let assetIdSet = Set<String>(assetIdArray)
        return assetIdSet
    }
    
    func beginSync() {
        isSyncing = true
//print("beginSync isSyncing now true")
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        if !isRegistered {
            registerForPhotoChanges()
        }
    }
    
    func endSync() {
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
        isSyncing = false
//print("endSync isSyncing now false")
        if shouldSyncAgain {
            shouldSyncAgain = false
            syncPhotos()
        }
    }
    
    func countAndPrint(name: String, set: Set<AnyHashable>) {
        print("\(name) count:\(set.count)")
    }
    
    func isSyncReady() -> Bool {
        if isSyncing {
//print("isSyncReady isSyncing found true. notReady")
            shouldSyncAgain = true
            return false
        }
//print("isSyncReady isSyncing found false. ready")
        return true
    }
    
    func addToSelected(assetId: String) -> Bool {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "localIdentifier == %@", assetId)
        let fetchResult: PHFetchResult<PHAsset> = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        guard let asset = fetchResult.firstObject else {
            return false
        }
        let tuple = self.selectedScreenshotAssets.insert(asset)
        return tuple.inserted
    }
    
    @objc public func syncPhotos() {
        self.serialQ.async {
            let dataModel = DataModel.sharedInstance
            guard PermissionsManager.shared().hasPermission(for: .photo),
                dataModel.isCoreDataStackReady,
                self.isSyncReady() else {
                    return
            }
            self.beginSync()
            let selectedSet = self.retrieveSelectedScreenshotAssetIds()
            let futureSet = self.retrieveFutureScreenshotAssetIds()
            let managedObjectContext = dataModel.adHocMoc()
            var dbSet = Set<String>()
            managedObjectContext.performAndWait {
                dbSet = dataModel.retrieveAllAssetIds(managedObjectContext: managedObjectContext)
//                let toDeleteFromDB = dbSet.subtracting(photosSet)//.union(changedAssetIds)
//                self.countAndPrint(name: "toDeleteFromDB", set: toDeleteFromDB)
//                if toDeleteFromDB.count > 0 {
//                    dataModel.deleteScreenshots(managedObjectContext: managedObjectContext, assetIds: toDeleteFromDB)
//                }
            }
            let toRetry = selectedSet.intersection(dbSet)
            let toBypassClarifai = selectedSet.subtracting(dbSet)
            let toUpload = futureSet.subtracting(selectedSet).subtracting(dbSet)//.union(changedAssetIds)
            let toDownload = Set<String>(self.incomingDynamicLinks).subtracting(dbSet)
            self.incomingDynamicLinks.removeAll()
            // TODO: Remove changedAssetIds as each screenshot is successfully saved.
            //changedAssetIds = []
            self.countAndPrint(name: "selectedSet", set: selectedSet)
            self.countAndPrint(name: "futureSet", set: futureSet)
            self.countAndPrint(name: "dbSet", set: dbSet)
            self.countAndPrint(name: "toRetry", set: toRetry)
            self.countAndPrint(name: "toBypassClarifai", set: toBypassClarifai)
            self.countAndPrint(name: "toUpload", set: toUpload)
            self.countAndPrint(name: "toDownload", set: toDownload)
            if toUpload.count > 0 || toDownload.count > 0 || toBypassClarifai.count > 0 || toRetry.count > 0 {
                DispatchQueue.main.async {
                    self.networkingIndicatorDelegate?.networkingIndicatorDidStart(type: .Screenshot)
                }
            }
            if toUpload.count > 0 {
                track("user imported screenshots", properties: ["numScreenshots" : toUpload.count])
                AccumulatorModel.sharedInstance.addToNewScreenshots(count: toUpload.count)
                self.futureScreenshotAssets?.enumerateObjects( { (asset: PHAsset, index: Int, stop: UnsafeMutablePointer<ObjCBool>) in
                    if toUpload.contains(asset.localIdentifier) {
                        self.screenshotsToProcess += 1
                        self.processingQ.async {
                            self.uploadScreenshotWithClarifai(asset: asset)
                        }
                    }
                })
            }
            if toDownload.count > 0 {
                track("user received shared screenshots", properties: ["numScreenshots" : toDownload.count]) // Always 1?
                self.screenshotsToProcess += toDownload.count
                toDownload.forEach { shareId in
                    self.processingQ.async {
                        self.downloadScreenshot(shareId: shareId)
                    }
                }
            }
            if toBypassClarifai.count > 0 {
                track("user imported old screenshots", properties: ["numScreenshots" : toBypassClarifai.count])
                self.selectedScreenshotAssets
                    .filter { toBypassClarifai.contains($0.localIdentifier) }
                    .forEach { asset in
                        self.screenshotsToProcess += 1
                        self.processingQ.async {
                            self.uploadPhotoBypassClarifai(asset: asset)
                        }
                }
            }
            if toRetry.count > 0 {
                track("user retried screenshots", properties: ["numScreenshots" : toRetry.count])
                self.selectedScreenshotAssets
                    .filter { toRetry.contains($0.localIdentifier) }
                    .forEach { asset in
                        self.screenshotsToProcess += 1
                        self.processingQ.async {
                            self.retryScreenshot(asset: asset)
                        }
                }
            }
            // Remove selected assets that were processed, i.e. their assetId is in selectedSet.
            self.selectedScreenshotAssets.subtract(self.selectedScreenshotAssets.filter { selectedSet.contains($0.localIdentifier) })
            if self.screenshotsToProcess == 0 {
                self.endSync()
            }
        }
    }
    
    @objc public func syncSelectedPhotos(assets: [PHAsset]) {
        self.selectedScreenshotAssets.formUnion(assets)
        syncPhotos()
    }
    
    @objc public func syncTutorialPhoto(image: UIImage) {
        self.serialQ.async {
            let dataModel = DataModel.sharedInstance
            guard dataModel.isCoreDataStackReady,
                self.isSyncReady() else {
                    return
            }
            self.beginSync()
            let imageData = self.data(for: image)
            dataModel.performBackgroundTask { (managedObjectContext) in
                let _ = dataModel.saveScreenshot(managedObjectContext: managedObjectContext,
                                                 assetId: Constants.tutorialScreenshotAssetId,
                                                 createdAt: Date(),
                                                 isFashion: true,
                                                 isFromShare: false,
                                                 isHidden: false,
                                                 imageData: imageData)
            }
            let tuple = self.tupleByAspectRatio()
            self.saveShoppables(assetId: Constants.tutorialScreenshotAssetId, uploadedURLString: tuple.0, segments: tuple.1)
            self.endSync()
        }
    }
    
    public func refetchOpenedFromNotification(assetId: String) {
        guard addToSelected(assetId: assetId) else {
            return
        }
        let accumulator = AccumulatorModel.sharedInstance
        if accumulator.getNewScreenshotsCount() > 0 {
            accumulator.addToNewScreenshots(count: -1)
        }
        syncPhotos()
    }
    
    @objc public func refetchShoppables(screenshot: Screenshot) {
        guard screenshot.shoppablesCount < 0,
          let assetId = screenshot.assetId,
          addToSelected(assetId: assetId) else {
                return
        }
        syncPhotos()
    }

    // Called from UI thread.
    @objc public func refetchLastScreenshot() {
        let dataModel = DataModel.sharedInstance
        guard let lastScreenshotAssetId = dataModel.retrieveLastScreenshotAssetId(managedObjectContext: dataModel.mainMoc()),
          addToSelected(assetId: lastScreenshotAssetId) else {
            return
        }
        syncPhotos()
    }
    
}

extension AssetSyncModel {
    
    func sendScreenshotAddedLocalNotification(assetId: String) {
        guard PermissionsManager.shared().hasPermission(for: .push) else {
            print("sendScreenshotAddedLocalNotification refused by guard")
            return
        }
        let content = UNMutableNotificationContent()
        content.title = "Ready to shop?"
        content.body = "Check out the products in your screenshot"
        if let lastNotificationSound = UserDefaults.standard.object(forKey: UserDefaultsKeys.dateLastSound) as? Date,
            -lastNotificationSound.timeIntervalSinceNow < 60 { // 1 minute
            content.sound = nil
        } else {
            content.sound = UNNotificationSound.default()
        }
        UserDefaults.standard.setValue(Date(), forKey: UserDefaultsKeys.dateLastSound)
        content.userInfo = [Constants.openingScreenKey : Constants.openingScreenValueScreenshot,
                            Constants.openingAssetIdKey : assetId]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let identifier = "CrazeLocal" + assetId
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content,
                                            trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: { (error) in
            if let error = error {
                print("sendScreenshotAddedLocalNotification identifier:\(identifier)  error:\(error)")
            }
        })
    }
    
}

extension AssetSyncModel: PHPhotoLibraryChangeObserver {
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        print("photoLibraryDidChange")
        guard let allScreenshotAssets = futureScreenshotAssets else {
            syncPhotos()
            return
        }
        if let changes = changeInstance.changeDetails(for: allScreenshotAssets),
            changes.hasIncrementalChanges {
            //                let changedAssets = changes.changedObjects
            //                if changedAssets.count > 0 {
            //                    for changedAsset in changedAssets {
            //                        changedAssetIds.append(changedAsset.localIdentifier)
            //                    }
            //                }
            //                print("photoLibraryDidChange changedAssets count:\(changedAssets.count)")
            syncPhotos()
        }
    }
    
}

extension AssetSyncModel {
    
    @objc public func handleDynamicLink(shareId: String) {
        incomingDynamicLinks.append(shareId)
        syncPhotos()
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
            }.then(on: assetSyncModel.processingQ) { id, shareLink -> Promise<String> in
                // Return the promise as soon as we have the shareLink, and concurrently or afterwards save shareLink to DB.
                NSLog("id:\(id)  shareLink:\(shareLink)")
                dataModel.performBackgroundTask { (managedObjectContext) in
                    if let screenshot = dataModel.retrieveScreenshot(managedObjectContext: managedObjectContext, assetId: assetId) {
                        screenshot.shareLink = shareLink
                        dataModel.saveMoc(managedObjectContext: managedObjectContext)
                    }
                }
                return Promise(value: shareLink)
        }
    }
    
    private func shareOrReshare() -> Promise<(String, String)> {
        let userName = UserDefaults.standard.string(forKey: UserDefaultsKeys.name)
        if self.isFromShare {
            return NetworkingPromise.reshare(userName: userName, screenshotId: self.assetId)
        } else {
            return NetworkingPromise.share(userName: userName, imageURLString: self.uploadedImageURL, syteJson: self.syteJson)
        }
    }
    
    @objc public func shareViaLink() -> AnyPromise {
        return AnyPromise(share())
    }
    
}
