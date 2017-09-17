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


class AssetSyncModel: NSObject {

    public static let sharedInstance = AssetSyncModel()
    var allScreenshotAssets: PHFetchResult<PHAsset>?
    var selectedScreenshotAssets: [PHAsset]?
//    var changedAssetIds: [String] = []
    var incomingDynamicLinks: [String] = []
    let serialQ = DispatchQueue(label: "io.crazeapp.screenshot.syncPhotos.serial")
    let processingQ = DispatchQueue.global(qos: .default) // .utility // DispatchQueue(label: "io.crazeapp.screenshot.syncPhotos.processing")
    var isRegistered = false
    var isSyncing = false
    var isTutorialScreenshot = false
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
    
    func uploadScreenshot(asset: PHAsset) {
        let dataModel = DataModel.sharedInstance
        firstly {
            return image(asset: asset)
            }.then (on: processingQ) { image -> Promise<(Bool, UIImage)> in
                if self.isTutorialScreenshot {
                    print("Bypassing Clarifai")
                    return Promise(value: (true, image))
                } else {
                    AnalyticsManager.track("sent image to Clarifai")
                    return ClarifaiModel.sharedInstance.isFashion(image: image)
                }
            }.then(on: processingQ) { isFashion, image -> Void in
                if !self.isTutorialScreenshot {
                    AnalyticsManager.track("received response from Clarifai", properties: ["isFashion" : isFashion])
                }
                let imageData: Data? = isFashion ? UIImageJPEGRepresentation(image, 0.80) : nil
                dataModel.performBackgroundTask { (managedObjectContext) in
                    let _ = dataModel.saveScreenshot(managedObjectContext: managedObjectContext,
                                                     assetId: asset.localIdentifier,
                                                     createdAt: asset.creationDate,
                                                     isFashion: isFashion,
                                                     isFromShare: false,
                                                     imageData: imageData)
                }
                if isFashion {
                    DispatchQueue.main.async {
                        NotificationManager.shared().present(with: .products)
                    }
                    firstly { _ -> Promise<(String, [[String : Any]])> in
                        if self.isTutorialScreenshot {
                            UserDefaults.standard.setValue(asset.localIdentifier, forKey: UserDefaultsKeys.tutorialScreenshotAssetId)
                            print("Bypassing Syte")
                            let nativeSize = UIScreen.main.nativeBounds.size
                            let deviceAspectRatio = nativeSize.height / nativeSize.width
                            let aspectRatio5Digit = Int(deviceAspectRatio * 10000)
                            print("nativeSize:\(nativeSize)  aspectRatio5Digit:\(aspectRatio5Digit)  deviceAspectRatio:\(deviceAspectRatio)")
                            switch aspectRatio5Digit {
                            case 17777: // iPhone 6,6+,6S,6S+,7,7+
                                return self.promiseForRatio17777()
                            case 17750: // iPhone 5C,5,5S
                                return self.promiseForRatio17750()
                            default:
                                return self.promiseForRatio17750()
                             }
                        } else {
                            return NetworkingPromise.uploadToSyte(imageData: imageData)
                        }
                        }.then(on: self.processingQ) { uploadedURLString, segments -> Void in
                            if self.isTutorialScreenshot {
                                self.isTutorialScreenshot = false
                            } else {
                                AnalyticsManager.track("received response from Syte", properties: ["segmentCount" : segments.count])
                            }
                            self.saveShoppables(assetId: asset.localIdentifier, uploadedURLString: uploadedURLString, segments: segments)
                        }.always {
                            NotificationManager.shared().dismiss(with: .products)
                        }.catch { error in
                            print("uploadScreenshot inner uploadToSyte catch error:\(error)")
                    }
                }
            }.always(on: self.serialQ) {
                self.decrementScreenshots()
            }.catch { error in
                print("uploadScreenshot outer Clarifai catch error:\(error)")
        }
    }
    
    func decrementScreenshots() {
        self.screenshotsToProcess -= 1
        if self.screenshotsToProcess == 0 {
            DispatchQueue.main.async {
                NotificationManager.shared().dismiss(with: .screenshots)
            }
            self.endSync()
        } else if self.screenshotsToProcess < 0 {
            print("WTF? negative screenshotsToProcess:\(self.screenshotsToProcess) after subtracting one")
        }
    }
    
    func downloadScreenshot(screenshotId: String) {
        let dataModel = DataModel.sharedInstance
        firstly { _ -> Promise<[String : Any]> in
            // Get screenshot dict from Craze server. See end https://docs.google.com/document/d/12_IrBskNTGY8zQSM88uA6h0QjLnUtZF7yiUdzv0nxT8/
            guard let screenshotInfoUrl = URL(string: Constants.screenShotLambdaDomain + "screenshot/" + screenshotId) else {
                    let urlError = NSError(domain: "Craze", code: 6, userInfo: [NSLocalizedDescriptionKey : "Could not form URL from screenshotId:\(screenshotId)"])
                    return Promise(error: urlError)
            }
            print("downloadScreenshot screenshotId:\(screenshotId)")
            return NetworkingPromise.downloadInfo(url: screenshotInfoUrl)
            }.then(on: self.processingQ) { screenshotDict -> Promise<(Data, [String : Any])> in
                // Download image from Syte S3.
                guard let imageURLString = screenshotDict["image"] as? String,
                    let imageURL = URL(string: imageURLString) else {
                        let imageURLError = NSError(domain: "Craze", code: 7, userInfo: [NSLocalizedDescriptionKey : "Could not form image URL from screenshotDict:\(screenshotDict)"])
                        return Promise(error: imageURLError)
                }
                return NetworkingPromise.downloadImage(url: imageURL, screenshotDict: screenshotDict)
            }.then(on: self.processingQ) { imageData, screenshotDict -> Promise<(NSManagedObject, [String : Any])> in
                // Save screenshot to db.
                return dataModel.backgroundPromise(dict: screenshotDict) { (managedObjectContext) -> NSManagedObject in
                    return dataModel.saveScreenshot(managedObjectContext: managedObjectContext,
                                                    assetId: screenshotId,
                                                    createdAt: Date(),
                                                    isFashion: true,
                                                    isFromShare: true,
                                                    imageData: imageData)
                }
            }.then(on: self.processingQ) { screenshotManagedObject, screenshotDict -> Void in
                // Save shoppables to db.
                guard let syteJsonString = screenshotDict["syteJson"] as? String,
                  let segments = NetworkingPromise.jsonDestringify(string: syteJsonString),
                  let imageURLString = screenshotDict["image"] as? String else {
                    let jsonError = NSError(domain: "Craze", code: 8, userInfo: [NSLocalizedDescriptionKey : "Could not extract syteJson from screenshotDict:\(screenshotDict)"])
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

    func promiseForRatio17777() -> Promise<(String, [[String : Any]])> {
        let imageURL = "https://s3.amazonaws.com/s3-file-store/generated/JjdvWeV7u5S75ZPl5pSOX"
        let segments = [["label":"Skirts","gender":"female","b0":[0.4177178144454956,0.4898432493209839],"center":[0.5302261114120483,0.5905150771141052],"offers":"//d1wt9iscpot47x.cloudfront.net/offers?image_url=aHR0cHM6Ly9zMy5hbWF6b25hd3MuY29tL3MzLWZpbGUtc3RvcmUvZ2VuZXJhdGVkL0pqZHZXZVY3dTVTNzVaUGw1cFNPWA%3D%3D&crop=eyJ5MiI6MC42OTM3MDM3MDA2MDIwNTQ2LCJ5IjowLjQ4NzMyNjQ1MzYyNjE1NTg0LCJ4MiI6MC42NDU1NDcxMTU4MDI3NjQ5LCJ4IjowLjQxNDkwNTEwNzAyMTMzMTh9&cats=WyJTa2lydHMiXQ%3D%3D&prob=0.5819&gender=female&feed=default&country=IL&account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D","b1":[0.6427344083786011,0.6911869049072266]],["label":"Jackets","gender":"female","b0":[0.3964715600013733,0.4136771559715271],"center":[0.5247414112091064,0.4848739802837372],"offers":"//d1wt9iscpot47x.cloudfront.net/offers?image_url=aHR0cHM6Ly9zMy5hbWF6b25hd3MuY29tL3MzLWZpbGUtc3RvcmUvZ2VuZXJhdGVkL0pqZHZXZVY3dTVTNzVaUGw1cFNPWA%3D%3D&crop=eyJ5MiI6MC41NTc4NTA3MjUyMDM3NTI2LCJ5IjowLjQxMTg5NzIzNTM2MzcyMTg2LCJ4MiI6MC42NTYyMTgwMDg2OTcwMzMsIngiOjAuMzkzMjY0ODEzNzIxMTh9&cats=WyJDb2F0c0phY2tldHNTdWl0cyJd&prob=0.5910&gender=female&feed=default&country=IL&account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D","b1":[0.6530112624168396,0.5560708045959473]],["label":"Shoes","gender":"female","b0":[0.4400824010372162,0.7088841199874878],"center":[0.4686053097248077,0.73576420545578],"offers":"//d1wt9iscpot47x.cloudfront.net/offers?image_url=aHR0cHM6Ly9zMy5hbWF6b25hd3MuY29tL3MzLWZpbGUtc3RvcmUvZ2VuZXJhdGVkL0pqZHZXZVY3dTVTNzVaUGw1cFNPWA%3D%3D&crop=eyJ5MiI6MC43NjMzMTYyOTMwNjA3Nzk1LCJ5IjowLjcwODIxMjExNzg1MDc4MDUsIngyIjowLjQ5Nzg0MTI5MTEyOTU4OTEsIngiOjAuNDM5MzY5MzI4MzIwMDI2NH0%3D&cats=WyJCb290cyIsIkZsYXRTYW5kYWxzIiwiRmxhdFNob2VzIiwiSGVlbFNhbmRhbHMiLCJIZWVsU2hvZXMiLCJTcG9ydFNob2VzIl0%3D&prob=0.5940&gender=female&feed=default&country=IL&account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D","b1":[0.4971282184123993,0.7626442909240723]],["label":"Bags","gender":"female","b0":[0.3904582262039185,0.5603976249694824],"center":[0.4276284575462341,0.6082033514976501],"offers":"//d1wt9iscpot47x.cloudfront.net/offers?image_url=aHR0cHM6Ly9zMy5hbWF6b25hd3MuY29tL3MzLWZpbGUtc3RvcmUvZ2VuZXJhdGVkL0pqZHZXZVY3dTVTNzVaUGw1cFNPWA%3D%3D&crop=eyJ5MiI6MC42NTcyMDQyMjExODkwMjIxLCJ5IjowLjU1OTIwMjQ4MTgwNjI3ODIsIngyIjowLjQ2NTcyNzk0NDY3MjEwNzcsIngiOjAuMzg5NTI4OTcwNDIwMzYwNTV9&cats=WyJIYW5kYmFncyJd&prob=0.5947&gender=female&feed=default&country=IL&account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D","b1":[0.4647986888885498,0.6560090780258179]],["label":"Shoes","gender":"female","b0":[0.5386749505996704,0.7097557187080383],"center":[0.5780842304229736,0.7361155152320862],"offers":"//d1wt9iscpot47x.cloudfront.net/offers?image_url=aHR0cHM6Ly9zMy5hbWF6b25hd3MuY29tL3MzLWZpbGUtc3RvcmUvZ2VuZXJhdGVkL0pqZHZXZVY3dTVTNzVaUGw1cFNPWA%3D%3D&crop=eyJ5MiI6MC43NjMxMzQzMDY2NjkyMzUyLCJ5IjowLjcwOTA5NjcyMzc5NDkzNzIsIngyIjowLjYxODQ3ODc0MjI0MTg1OTQsIngiOjAuNTM3Njg5NzE4NjA0MDg3OX0%3D&cats=WyJCb290cyIsIkZsYXRTYW5kYWxzIiwiRmxhdFNob2VzIiwiSGVlbFNhbmRhbHMiLCJIZWVsU2hvZXMiLCJTcG9ydFNob2VzIl0%3D&prob=0.6584&gender=female&feed=default&country=IL&account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D","b1":[0.6174935102462769,0.762475311756134]]]
        return Promise(value: (imageURL, segments))
    }
    
    func promiseForRatio17750() -> Promise<(String, [[String : Any]])> {
        let imageURL = "https://s3.amazonaws.com/s3-file-store/generated/Z0RCO7uhoIdjexiNYpnOa"
        let segments = [["center":[0.4758209437131882,0.7562138438224792],"b1":[0.5065634846687317,0.7875601649284363],"offers":"//d1wt9iscpot47x.cloudfront.net/offers?image_url=aHR0cHM6Ly9zMy5hbWF6b25hd3MuY29tL3MzLWZpbGUtc3RvcmUvZ2VuZXJhdGVkL1owUkNPN3Vob0lkamV4aU5ZcG5PYQ%3D%3D&crop=eyJ5MiI6MC43ODgzNDM4MjI5NTYwODUyLCJ5IjowLjcyNDA4Mzg2NDY4ODg3MzMsIngyIjowLjUwNzMzMjA0ODE5MjYyMDIsIngiOjAuNDQ0MzA5ODM5MjMzNzU2MDV9&cats=WyJCb290cyIsIkZsYXRTYW5kYWxzIiwiRmxhdFNob2VzIiwiSGVlbFNhbmRhbHMiLCJIZWVsU2hvZXMiLCJTcG9ydFNob2VzIl0%3D&prob=0.5962&gender=female&feed=default&country=IL&account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D","gender":"female","b0":[0.4450784027576447,0.7248675227165222],"label":"Shoes"],["center":[0.5769312381744385,0.7599759697914124],"b1":[0.6138189435005188,0.790989100933075],"offers":"//d1wt9iscpot47x.cloudfront.net/offers?image_url=aHR0cHM6Ly9zMy5hbWF6b25hd3MuY29tL3MzLWZpbGUtc3RvcmUvZ2VuZXJhdGVkL1owUkNPN3Vob0lkamV4aU5ZcG5PYQ%3D%3D&crop=eyJ5MiI6MC43OTE3NjQ0MjkyMTE2MTY1LCJ5IjowLjcyODE4NzUxMDM3MTIwODIsIngyIjowLjYxNDc0MTEzNjEzMzY3MDgsIngiOjAuNTM5MTIxMzQwMjE1MjA2Mn0%3D&cats=WyJCb290cyIsIkZsYXRTYW5kYWxzIiwiRmxhdFNob2VzIiwiSGVlbFNhbmRhbHMiLCJIZWVsU2hvZXMiLCJTcG9ydFNob2VzIl0%3D&prob=0.6680&gender=female&feed=default&country=IL&account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D","gender":"female","b0":[0.5400435328483582,0.7289628386497498],"label":"Shoes"],["center":[0.5488517135381699,0.6003944724798203],"b1":[0.6968203783035278,0.7249109148979187],"offers":"//d1wt9iscpot47x.cloudfront.net/offers?image_url=aHR0cHM6Ly9zMy5hbWF6b25hd3MuY29tL3MzLWZpbGUtc3RvcmUvZ2VuZXJhdGVkL1owUkNPN3Vob0lkamV4aU5ZcG5PYQ%3D%3D&crop=eyJ5MiI6MC43MjgwMjM4MjU5NTgzNzExLCJ5IjowLjQ3Mjc2NTExOTAwMTI2OTMzLCJ4MiI6MC43MDA1MTk1OTQ5MjI2NjE4LCJ4IjowLjM5NzE4MzgzMjE1MzY3OH0%3D&cats=WyJTa2lydHMiXQ%3D%3D&prob=0.6826&gender=female&feed=default&country=IL&account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D","gender":"female","b0":[0.4008830487728119,0.4758780300617218],"label":"Skirts"],["center":[0.5255868434906006,0.4789808094501495],"b1":[0.6664043664932251,0.5487481951713562],"offers":"//d1wt9iscpot47x.cloudfront.net/offers?image_url=aHR0cHM6Ly9zMy5hbWF6b25hd3MuY29tL3MzLWZpbGUtc3RvcmUvZ2VuZXJhdGVkL1owUkNPN3Vob0lkamV4aU5ZcG5PYQ%3D%3D&crop=eyJ5MiI6MC41NTA0OTIzNzk4MTQzODY0LCJ5IjowLjQwNzQ2OTIzOTA4NTkxMjcsIngyIjowLjY2OTkyNDgwNDU2ODI5MDcsIngiOjAuMzgxMjQ4ODgyNDEyOTEwNX0%3D&cats=WyJDb2F0c0phY2tldHNTdWl0cyJd&prob=0.7033&gender=female&feed=default&country=IL&account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D","gender":"female","b0":[0.3847693204879761,0.4092134237289429],"label":"Jackets"],["center":[0.4082863032817841,0.6220149397850037],"b1":[0.4480967223644257,0.6669795513153076],"offers":"//d1wt9iscpot47x.cloudfront.net/offers?image_url=aHR0cHM6Ly9zMy5hbWF6b25hd3MuY29tL3MzLWZpbGUtc3RvcmUvZ2VuZXJhdGVkL1owUkNPN3Vob0lkamV4aU5ZcG5PYQ%3D%3D&crop=eyJ5MiI6MC42NjgxMDM2NjY2MDM1NjUyLCJ5IjowLjU3NTkyNjIxMjk2NjQ0MjEsIngyIjowLjQ0OTA5MTk4Mjg0MTQ5MTcsIngiOjAuMzY3NDgwNjIzNzIyMDc2NH0%3D&cats=WyJIYW5kYmFncyJd&prob=0.7323&gender=female&feed=default&country=IL&account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D","gender":"female","b0":[0.3684758841991425,0.5770503282546997],"label":"Bags"]]
        return Promise(value: (imageURL, segments))
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
                                screenshot.lastModified = NSDate()
                                dataModel.saveMoc(managedObjectContext: managedObjectContext)
                                if screenshot.shoppablesCount == 1 {
                                    self.sendScreenshotAddedLocalNotification(assetId: assetId)
                                }
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
        let screen = UIScreen.main
        let screenSizePx = screen.nativeBounds.size
        let targetSize = CGSize(width: screenSizePx.width / screen.nativeScale, height: screenSizePx.height / screen.nativeScale)
//        let targetSize = CGSize(width: 180, height: 320)
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
                    let cancelledError = NSError(domain: "Craze", code: 5, userInfo: [NSLocalizedDescriptionKey : "Image request canceled"])
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
    
    func setupAllScreenshotAssets() {
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
        allScreenshotAssets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
    }
    
    func retrieveAllScreenshotAssetIds() -> Set<String> {
        setupAllScreenshotAssets()
        var assetIds = Set<String>()
        allScreenshotAssets?.enumerateObjects({ (asset: PHAsset, index: Int, stop: UnsafeMutablePointer<ObjCBool>) in
            assetIds.insert(asset.localIdentifier)
        })
        return assetIds
    }
    
    func retrieveSelectedScreenshotAssetIds() -> Set<String> {
        var assetIds = Set<String>()
        guard let selectedScreenshotAssets = selectedScreenshotAssets else {
            return assetIds
        }
        for asset in selectedScreenshotAssets {
            assetIds.insert(asset.localIdentifier)
        }
        self.selectedScreenshotAssets?.removeAll()
        return assetIds
    }
    
    func beginSync() {
        isSyncing = true
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
            shouldSyncAgain = true
            return false
        }
        return true
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
            let photosSet = self.retrieveSelectedScreenshotAssetIds().union(self.retrieveAllScreenshotAssetIds())
            let managedObjectContext = dataModel.adHocMoc()
            var dbSet = Set<String>()
            managedObjectContext.performAndWait {
                dbSet = dataModel.retrieveCompleteAssetIds(managedObjectContext: managedObjectContext)
//                let toDeleteFromDB = dbSet.subtracting(photosSet)//.union(changedAssetIds)
//                self.countAndPrint(name: "toDeleteFromDB", set: toDeleteFromDB)
//                if toDeleteFromDB.count > 0 {
//                    dataModel.deleteScreenshots(managedObjectContext: managedObjectContext, assetIds: toDeleteFromDB)
//                }
            }
            let toUpload = photosSet.subtracting(dbSet)//.union(changedAssetIds)
            let toDownload = Set<String>(self.incomingDynamicLinks).subtracting(dbSet)
            self.incomingDynamicLinks.removeAll()
            // TODO: Remove changedAssetIds as each screenshot is successfully saved.
            //changedAssetIds = []
            self.countAndPrint(name: "dbSet", set: dbSet)
            self.countAndPrint(name: "photosSet", set: photosSet)
            self.countAndPrint(name: "toUpload", set: toUpload)
            self.countAndPrint(name: "toDownload", set: toDownload)
            if toUpload.count > 0 || toDownload.count > 0 {
                DispatchQueue.main.async {
                    NotificationManager.shared().present(with: .screenshots)
                }
            }
            if toUpload.count > 0 {
                AnalyticsManager.track("user imported screenshots", properties: ["numScreenshots" : toUpload.count])
                self.allScreenshotAssets?.enumerateObjects( { (asset: PHAsset, index: Int, stop: UnsafeMutablePointer<ObjCBool>) in
                    if toUpload.contains(asset.localIdentifier) {
                        self.screenshotsToProcess += 1
                        self.processingQ.async {
                            self.uploadScreenshot(asset: asset)
                        }
                    }
                })
            }
            if toDownload.count > 0 {
                AnalyticsManager.track("user received shared screenshots", properties: ["numScreenshots" : toDownload.count]) // Always 1?
                self.screenshotsToProcess += toDownload.count
                for screenshotId in toDownload {
                    self.processingQ.async {
                        self.downloadScreenshot(screenshotId: screenshotId)
                    }
                }
            }
            if self.screenshotsToProcess == 0 {
                self.endSync()
            }
        }
    }
    
    @objc public func syncSelectedPhotos(assets: [PHAsset]) {
        self.selectedScreenshotAssets = assets
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
        content.userInfo = [ Constants.openingScreenKey : Constants.openingScreenValueScreenshot ]
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
        guard let allScreenshotAssets = allScreenshotAssets else {
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
    
    @objc public func handleDynamicLink(screenshotId: String) {
        incomingDynamicLinks.append(screenshotId)
        syncPhotos()
    }
    
}

extension Screenshot {
    
    public func share() -> Promise<String> {
        if let shareLink = self.shareLink {
            return Promise(value: shareLink)
        }
        guard let assetId = self.assetId else {
            let error = NSError(domain: "Craze", code: 12, userInfo: [NSLocalizedDescriptionKey: "share with no assetId"])
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
