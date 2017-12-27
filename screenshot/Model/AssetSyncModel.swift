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
    public weak var screenshotDetectionDelegate: ScreenshotDetectionProtocol?
    var futureScreenshotAssets: PHFetchResult<PHAsset>?
    var selectedScreenshotAssets = Set<PHAsset>()
    var foregroundScreenshotAssetIds = Set<String>()
    var backgroundScreenshotAssetIds = Set<String>()
    var incomingDynamicLinks: [String] = []
    let serialQ = DispatchQueue(label: "io.crazeapp.screenshot.syncPhotos.serial")
    let processingQ = DispatchQueue.global(qos: .default) // .utility // DispatchQueue(label: "io.crazeapp.screenshot.syncPhotos.processing")
    var isRegistered = false
    var isSyncing = false
    var shouldSyncAgain = false
    var isNextScreenshotForeground = false
    var isRecentlyForeground = false
    var screenshotsToProcess: Int = 0
    var shoppablesToProcess: Int = 0
    
    let imageMediaType = kUTTypeImage as String;
    
    override init() {
        super.init()
        registerForPhotoChanges()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationUserDidTakeScreenshot), name: .UIApplicationUserDidTakeScreenshot, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func registerForPhotoChanges() {
        guard PermissionsManager.shared.hasPermission(for: .photo) else {
            print("registerForPhotoChanges refused by guard")
            return
        }
        PHPhotoLibrary.shared().register(self)
        isRegistered = true
    }
    
    @objc func applicationUserDidTakeScreenshot() {
        print("AssetSyncModel applicationUserDidTakeScreenshot")
        isNextScreenshotForeground = ApplicationStateModel.sharedInstance.isActive()
    }
    
    func uploadScreenshotWithClarifai(asset: PHAsset) {
        let isForeground = foregroundScreenshotAssetIds.contains(asset.localIdentifier)
        let dataModel = DataModel.sharedInstance
        firstly {
            return image(asset: asset)
            }.then (on: processingQ) { image -> Promise<(Bool, UIImage)> in
                track("sent image to Clarifai")
                return ClarifaiModel.sharedInstance.isFashion(image: image)
            }.then(on: processingQ) { isFashion, image -> Promise<(Bool, Data?)> in
                track("received response from Clarifai", properties: ["isFashion" : isFashion])
                let imageData: Data? = isFashion ? self.data(for: image) : nil
                return Promise { fulfill, reject in
                    dataModel.performBackgroundTask { (managedObjectContext) in
                        let _ = dataModel.saveScreenshot(managedObjectContext: managedObjectContext,
                                                         assetId: asset.localIdentifier,
                                                         createdAt: asset.creationDate,
                                                         isFashion: isFashion,
                                                         isFromShare: false,
                                                         isHidden: !isFashion || !isForeground,
                                                         imageData: imageData)
                        fulfill((isFashion, imageData))
                    }
                }
            }.then (on: processingQ) { isFashion, imageData -> Void in
                if isForeground {
                    self.foregroundScreenshotAssetIds.remove(asset.localIdentifier)
                }
                if isFashion {
                    if isForeground { // Screenshot taken while app in foregorund
                        DispatchQueue.main.async {
                            self.screenshotDetectionDelegate?.foregroundScreenshotTaken(assetId: asset.localIdentifier)
                        }
                        self.syteProcessing(shouldProcess: true, imageData: imageData, assetId: asset.localIdentifier)
                    } else { // Screenshot taken while app in background (or killed)
                        AccumulatorModel.sharedInstance.addToNewScreenshots(count: 1)
                        self.backgroundScreenshotAssetIds.insert(asset.localIdentifier)
                    }
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
                            // Shitty FRCs sometimes misreport a move as an update, unless saved twice.
                            screenshot.lastModified = NSDate()
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
#if STORE_NEW_TUTORIAL_SCREENSHOT
                    print("uploadedURLString:\(uploadedURLString)\nsegments:\(segments)")
#endif
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
            // See end https://docs.google.com/document/d/16WsJMepl0Z3YrsRKxcFqkASUieRLKy_Aei8lmbpD2bo
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
                return dataModel.backgroundPromise(dict: screenshotDict) { (managedObjectContext) -> NSManagedObject in
                    return dataModel.saveScreenshot(managedObjectContext: managedObjectContext,
                                                    assetId: shareId,
                                                    createdAt: Date(),
                                                    isFashion: true,
                                                    isFromShare: true,
                                                    isHidden: false,
                                                    imageData: imageData)
                }
            }.then(on: self.processingQ) { screenshotManagedObject, screenshotDict -> Void in
                // Save shoppables to db.
                guard let syteJsonString = screenshotDict["syteJson"] as? String,
                  let segments = NetworkingPromise.jsonDestringify(string: syteJsonString),
                  let imageURLString = screenshotDict["image"] as? String else {
                    let jsonError = NSError(domain: "Craze", code: 10, userInfo: [NSLocalizedDescriptionKey : "Could not extract syteJson from screenshotDict:\(screenshotDict)"])
                    print(jsonError)
                    return
                }
                self.saveShoppables(assetId: shareId, uploadedURLString: imageURLString, segments: segments)
            }.always(on: self.serialQ) {
                self.decrementScreenshots()
            }.catch { error in
                print("downloadScreenshot catch error:\(error)")
        }
    }
    
    func tupleForRawGraphic() -> (String, [[String : Any]]) {
        let imageURL = "https://s3.amazonaws.com/s3-file-store/generated/aKeeu5_UE5rQj09XPjla5"
        let segments = [
            ["label":"Skirts","gender":"female",
             "offers":"//d1wt9iscpot47x.cloudfront.net/offers?image_url=aHR0cHM6Ly9zMy5hbWF6b25hd3MuY29tL3MzLWZpbGUtc3RvcmUvZ2VuZXJhdGVkL2FLZWV1NV9VRTVyUWowOVhQamxhNQ%3D%3D&crop=eyJ5MiI6MC44MzQ1MjQ1NjQwNzI0ODk4LCJ5IjowLjMxNTc4MTgwOTc2MjEyMDMsIngyIjowLjczMTM4OTQ1Mjg4OTU2MTYsIngiOjAuMzYwNzQwNTgyMjcyNDEwNH0%3D&cats=WyJTa2lydHMiXQ%3D%3D&prob=0.7441&gender=female&feed=default&country=IL&account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D"],
            ["label":"Jackets","gender":"female",
             "offers":"//d1wt9iscpot47x.cloudfront.net/offers?image_url=aHR0cHM6Ly9zMy5hbWF6b25hd3MuY29tL3MzLWZpbGUtc3RvcmUvZ2VuZXJhdGVkL2FLZWV1NV9VRTVyUWowOVhQamxhNQ%3D%3D&crop=eyJ5MiI6MC41MjEzNTk2OTk1OTE5OTQyLCJ5IjowLjE2OTM2NDQ2NDY1NTUxODU1LCJ4MiI6MC42NTIxMDM5NjIwMDQxODQ3LCJ4IjowLjM0NDgwMjA4MDA5NDgxNDMzfQ%3D%3D&cats=WyJDb2F0c0phY2tldHNTdWl0cyJd&prob=0.8739&gender=female&feed=default&country=IL&account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D"],
           ["label":"Bags","gender":"female",
             "offers":"//d1wt9iscpot47x.cloudfront.net/offers?image_url=aHR0cHM6Ly9zMy5hbWF6b25hd3MuY29tL3MzLWZpbGUtc3RvcmUvZ2VuZXJhdGVkL2FLZWV1NV9VRTVyUWowOVhQamxhNQ%3D%3D&crop=eyJ5MiI6MC43MTI0MzIyNzEyNDIxNDE3LCJ5IjowLjU0MDc4NDgyOTg1NDk2NTIsIngyIjowLjM5ODcwODUxMzM3OTA5Njk2LCJ4IjowLjMwMzUyMzYwOTA0MjE2Nzd9&cats=WyJIYW5kYmFncyJd&prob=0.7504&gender=female&feed=default&country=IL&account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D"],
            ["label":"Shoes","gender":"female", // Heeled shoe
             "offers":"//d1wt9iscpot47x.cloudfront.net/offers?image_url=aHR0cHM6Ly9zMy5hbWF6b25hd3MuY29tL3MzLWZpbGUtc3RvcmUvZ2VuZXJhdGVkL2FLZWV1NV9VRTVyUWowOVhQamxhNQ%3D%3D&crop=eyJ5MiI6MC45NjI4MjczMDk5NjYwODczLCJ5IjowLjgzMDg1NDA3MzE2Njg0NzIsIngyIjowLjQ2NDg3NDE5MjMyNzI2MDk2LCJ4IjowLjM4MzQxNDE2NDkzMDU4MjA2fQ%3D%3D&cats=WyJCb290cyIsIkZsYXRTYW5kYWxzIiwiRmxhdFNob2VzIiwiSGVlbFNhbmRhbHMiLCJIZWVsU2hvZXMiLCJTcG9ydFNob2VzIl0%3D&prob=0.7713&gender=female&feed=default&country=IL&account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D"],
            ["label":"Shoes","gender":"female", // Invisible heel
             "offers":"//d1wt9iscpot47x.cloudfront.net/offers?image_url=aHR0cHM6Ly9zMy5hbWF6b25hd3MuY29tL3MzLWZpbGUtc3RvcmUvZ2VuZXJhdGVkL2FLZWV1NV9VRTVyUWowOVhQamxhNQ%3D%3D&crop=eyJ5MiI6MC45MzAzMjQ1NjkzNDQ1MjA2LCJ5IjowLjgwODgzNzYzNzMwNTI1OTcsIngyIjowLjU5ODI1MTQ0MTEyMTEwMTQsIngiOjAuNTEzMjgyNTU4MzIxOTUyOH0%3D&cats=WyJCb290cyIsIkZsYXRTYW5kYWxzIiwiRmxhdFNob2VzIiwiSGVlbFNhbmRhbHMiLCJIZWVsU2hvZXMiLCJTcG9ydFNob2VzIl0%3D&prob=0.8184&gender=female&feed=default&country=IL&account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D"]
        ]
        return (imageURL, segments)
    }
    
    func tupleForRatio15000() -> (String, [[String : Any]]) {
        let rawGraphicTuple = self.tupleForRawGraphic()
        var segments = rawGraphicTuple.1
        segments[0]["b0"] = [0.44328701, 0.55790961]                   // skirt
        segments[0]["b1"] = [0.58159721, 0.67620057]
        segments[1]["b0"] = [0.45023148148148145, 0.54166666666666663] // jacket
        segments[1]["b1"] = [0.54861111111111116, 0.61979166666666663]
        segments[2]["b0"] = [0.43981481481481477, 0.61545138888888884] // bag
        segments[2]["b1"] = [0.48495370370370366, 0.65364583333333337]
        segments[3]["b0"] = [0.46296296296296291, 0.67664930555555547] // heeled shoe
        segments[3]["b1"] = [0.49537037037037035, 0.70616319444444431]
        segments[4]["b0"] = [0.50231481481481477, 0.67230902777777768] // flat shoe
        segments[4]["b1"] = [0.53356481481481477, 0.70182291666666663]
        return (rawGraphicTuple.0, segments)
    }
    
    func tupleForRatio17750() -> (String, [[String : Any]]) {
        let rawGraphicTuple = self.tupleForRawGraphic()
        var segments = rawGraphicTuple.1
        segments[0]["b0"] = [0.44328701, 0.55790961] // skirt
        segments[0]["b1"] = [0.58159721, 0.67620057]
        segments[1]["b0"] = [0.4380787, 0.51624292]  // jacket
        segments[1]["b1"] = [0.55497682, 0.58615816]
        segments[2]["b0"] = [0.41550925925925924, 0.59110169491525422] // bag
        segments[2]["b1"] = [0.46875, 0.67549435028248583]
        segments[3]["b0"] = [0.45081018518518512, 0.66419491525423724] // heeled shoe
        segments[3]["b1"] = [0.49016203703703698, 0.72387005649717506]
        segments[4]["b0"] = [0.50289351851851849, 0.67161016949152541] // flat shoe
        segments[4]["b1"] = [0.55034722222222221, 0.72598870056497167]
        return (rawGraphicTuple.0, segments)
    }
    
    func tupleForRatio17777() -> (String, [[String : Any]]) {
        let rawGraphicTuple = self.tupleForRawGraphic()
        var segments = rawGraphicTuple.1
        segments[0]["b0"] = [0.45157109968941067, 0.5366802879937731]  // skirt
        segments[0]["b1"] = [0.58665370415977025, 0.6534345203346954]
        segments[1]["b0"] = [0.44677137870855144, 0.49513888623979357] // jacket
        segments[1]["b1"] = [0.55206514528284523, 0.56215277777777772]
        segments[2]["b0"] = [0.40945902170391962, 0.58124148073213111] // bag
        segments[2]["b1"] = [0.47942986718496916, 0.63183498438241115]
        segments[3]["b0"] = [0.43602202291584408, 0.64915352587710096] // heeled shoe
        segments[3]["b1"] = [0.49206349206349204, 0.69157423326351641]
        segments[4]["b0"] = [0.5046971169420148, 0.65207238762405129]  // flat shoe
        segments[4]["b1"] = [0.5468091949275059, 0.68748783216237042]
        return (rawGraphicTuple.0, segments)
    }
    
    func tupleForRatio17786() -> (String, [[String : Any]]) {
        let rawGraphicTuple = self.tupleForRawGraphic()
        var segments = rawGraphicTuple.1
        segments[0]["b0"] = [0.44412050534499509, 0.53736135434909515] // skirt
        segments[0]["b1"] = [0.58551992225461613, 0.65148861646234679]
        segments[1]["b0"] = [0.43828960155490765, 0.49357851722124924] // jacket
        segments[1]["b1"] = [0.55733722060252666, 0.5642148277875072]
        segments[2]["b0"] = [0.4139941690962099, 0.58990075890251015]  // bag
        segments[2]["b1"] = [0.46064139941690962, 0.62930531231757147]
        segments[3]["b0"] = [0.44946550048590861, 0.66053706946876822] // heeled shoe
        segments[3]["b1"] = [0.48250728862973763, 0.69118505545826026]
        segments[4]["b0"] = [0.50874635568513116, 0.65703444249854048] // flat shoe
        segments[4]["b1"] = [0.53838678328474243, 0.68563922942206657]
        return (rawGraphicTuple.0, segments)
    }
    
    func tupleForRatio21653() -> (String, [[String : Any]]) {
        let rawGraphicTuple = self.tupleForRawGraphic()
        var segments = rawGraphicTuple.1
        segments[0]["b0"] = [0.44962746014979649, 0.53225261735900031] // skirt
        segments[0]["b1"] = [0.58956915111189556, 0.63492062976737951]
        segments[1]["b0"] = [0.43861353571143857, 0.49240121322884345] // jacket
        segments[1]["b1"] = [0.56073858114674435, 0.55673758607585455]
        segments[2]["b0"] = [0.41690962099125367, 0.57598783936866105] // bag
        segments[2]["b1"] = [0.46161321671525746, 0.60840931859865088]
        segments[3]["b0"] = [0.45124716058996139, 0.6377912841508292]  // heeled shoe
        segments[3]["b1"] = [0.48720440062883408, 0.6656534928641018]
        segments[4]["b0"] = [0.51182376724406276, 0.63542721538034808] // flat shoe
        segments[4]["b1"] = [0.54065435203796919, 0.66024991041580916]
        return (rawGraphicTuple.0, segments)
    }
    
    func tupleByAspectRatio() -> (String, [[String : Any]]) {
        let nativeSize = UIScreen.main.nativeBounds.size
        let deviceAspectRatio = nativeSize.height / nativeSize.width
        let aspectRatio5Digit = Int(deviceAspectRatio * 10000)
        print("nativeSize:\(nativeSize)  aspectRatio5Digit:\(aspectRatio5Digit)  deviceAspectRatio:\(deviceAspectRatio)")
        switch aspectRatio5Digit {
        case 15000: // iPad, iPad Air, iPad Pro 9.7", iPad Pro 10.5"
            return self.tupleForRatio15000()
        case 17750: // iPhone 5C,5,5S
            return self.tupleForRatio17750()
        case 17777: // iPhone 6+,6S+,7+
            return self.tupleForRatio17777()
        case 17786: // iPhone 6,6S,7,8; iPad Pro 12.9"
            return self.tupleForRatio17786()
        case 21653: // iPhone X
            return self.tupleForRatio21653()
        default:
            return self.tupleForRatio17750()
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
    
    func saveShoppables(assetId: String, uploadedURLString: String, segments: [[String : Any]]) { //-> Promise<[String]> {
        let optionsMask = ProductsOptionsMask.global
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
                    screenshot.syteJson = NetworkingPromise.jsonStringify(object: segments)
                    screenshot.uploadedImageURL = uploadedURLString
                }
                dataModel.saveMoc(managedObjectContext: managedObjectContext)
            }
        }
            
        NetworkingPromise.downloadProductsWithRetry(url: url)
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
            dataModel.saveMoc(managedObjectContext: managedObjectContext)
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
        NetworkingPromise.downloadProductsWithRetry(url: url)
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
    
    func image(assetId: String, callback: @escaping ((UIImage?, [AnyHashable : Any]?) -> Void)) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 1;
        
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: fetchOptions)
        
        guard let asset = assets.firstObject else {
            print("No asset for assetId:\(assetId)")
            track("err img hang", properties: ["reason" : "No asset for assetId:\(assetId)"])
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
        imageRequestOptions.isNetworkAccessAllowed = true
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
                    track("err img hang", properties: ["reason" : "PHImageErrorKey. info:\(info ?? ["-" : "-"])"])
                    reject(imageError)
                    return
                }
                if let isCancelled = info?[PHImageCancelledKey] as? Bool,
                    isCancelled == true {
                    track("err img hang", properties: ["reason" : "PHImageCancelledKey. info:\(info ?? ["-" : "-"])"])
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
                    track("err img hang", properties: ["reason" : "No image. info:\(info ?? ["-" : "-"])"])
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
        var compressionQuality: CGFloat
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
#if STORE_NEW_TUTORIAL_SCREENSHOT
        compressionQuality = 0.99
#endif
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
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        if !isRegistered {
            registerForPhotoChanges()
        }
    }
    
    func endSync() {
        let backgroundScreenshotIds = Set<String>(backgroundScreenshotAssetIds)
        backgroundScreenshotAssetIds.removeAll()
        let wasRecentlyForeground = isRecentlyForeground
        isRecentlyForeground = false
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            if wasRecentlyForeground && AccumulatorModel.sharedInstance.getNewScreenshotsCount() > 0 {
                self.screenshotDetectionDelegate?.backgroundScreenshotsWereTaken(assetIds: backgroundScreenshotIds)
            }
        }
        if backgroundScreenshotIds.count > 0 && ApplicationStateModel.sharedInstance.isBackground() {
            self.sendScreenshotAddedLocalNotification(assetIds: backgroundScreenshotIds)
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
            guard PermissionsManager.shared.hasPermission(for: .photo),
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
            }
            let toRetry = selectedSet.intersection(dbSet)
            let toBypassClarifai = selectedSet.subtracting(dbSet)
            let toUpload = futureSet.subtracting(selectedSet).subtracting(dbSet)//.union(changedAssetIds)
            let toDownload = Set<String>(self.incomingDynamicLinks).subtracting(dbSet)
            self.incomingDynamicLinks.removeAll()
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
    
    @objc public func syncPhotosUponForeground() {
        isRecentlyForeground = true
        syncPhotos()
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
            let imageData: Data?
#if STORE_NEW_TUTORIAL_SCREENSHOT
            imageData = self.data(for: TutorialTrySlideView.rawGraphic ?? image)
#else
            imageData = self.data(for: image)
#endif
            dataModel.performBackgroundTask { (managedObjectContext) in
                let _ = dataModel.saveScreenshot(managedObjectContext: managedObjectContext,
                                                 assetId: Constants.tutorialScreenshotAssetId,
                                                 createdAt: Date(),
                                                 isFashion: true,
                                                 isFromShare: false,
                                                 isHidden: false,
                                                 imageData: imageData)
            }
#if STORE_NEW_TUTORIAL_SCREENSHOT
            let _ = self.tupleByAspectRatio() // Just want print of aspectRatio.
            self.syteProcessing(shouldProcess: true, imageData: imageData, assetId: Constants.tutorialScreenshotAssetId)
#else
            let tuple = self.tupleByAspectRatio()
            self.saveShoppables(assetId: Constants.tutorialScreenshotAssetId, uploadedURLString: tuple.0, segments: tuple.1)
#endif
            self.endSync()
        }
    }
    
    public func refetchOpenedFromNotification(assetId: String) {
        guard addToSelected(assetId: assetId) else {
            return
        }
        backgroundScreenshotAssetIds.remove(assetId)
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
    
    func sendScreenshotAddedLocalNotification(assetIds: Set<String>) {
        guard PermissionsManager.shared.hasPermission(for: .push) else {
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
        if assetIds.count == 1,
          let onlyAssetId = assetIds.first {
            content.userInfo = [Constants.openingScreenKey  : Constants.openingScreenValueScreenshot,
                                Constants.openingAssetIdKey : onlyAssetId]
        } else {
            content.userInfo = [Constants.openingScreenKey : Constants.openingScreenValueScreenshot]
        }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let firstAssetId = assetIds.first ?? ""
        let identifier = "CrazeLocal" + firstAssetId
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content,
                                            trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: { (error) in
            if let error = error {
                print("sendScreenshotAddedLocalNotification identifier:\(identifier)  error:\(error)")
            } else {
                track("app sent local push notification")
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
            if let foregroundScreenshotAssetId = changes.insertedObjects.first?.localIdentifier,
                isNextScreenshotForeground {
                self.foregroundScreenshotAssetIds.insert(foregroundScreenshotAssetId)
                isNextScreenshotForeground = false
            }
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
            }.then(on: assetSyncModel.processingQ) { shareId, shareLink -> Promise<String> in
                // Return the promise as soon as we have the shareLink, and concurrently or afterwards save shareLink to DB.
                NSLog("shareId:\(shareId)  shareLink:\(shareLink)")
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
            return NetworkingPromise.reshare(userName: userName, shareId: self.assetId)
        } else {
            return NetworkingPromise.share(userName: userName, imageURLString: self.uploadedImageURL, syteJson: self.syteJson)
        }
    }
    
    @objc public func shareViaLink() -> AnyPromise {
        return AnyPromise(share())
    }
    
}
