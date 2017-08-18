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
//    var changedAssetIds: [String] = []
    let serialQ = DispatchQueue(label: "io.crazeapp.screenshot.syncPhotos.serial")
    let processingQ = DispatchQueue(label: "io.crazeapp.screenshot.syncPhotos.processing") // DispatchQueue.global(qos: .userInitiated) // TODO: Parallelize.
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
    
    func uploadScreenshot(asset: PHAsset) {
        NSLog("uploadScreenshot started assetId:\(asset.localIdentifier)")
        let uploadStart = Date()
        let dataModel = DataModel.sharedInstance
        let moc = dataModel.adHocMoc()
        firstly {
            return image(asset: asset)
            }.then /*(on: processingQ)*/ { image -> Promise<(Bool, UIImage)> in  // Clarifai bug, must run on main
                NSLog("uploadScreenshot til image retrieved \(-uploadStart.timeIntervalSinceNow) sec assetId:\(asset.localIdentifier)")
                return ClarifaiModel.sharedInstance.isFashion(image: image)
            }.then(on: processingQ) { isFashion, image -> Void in
                NSLog("uploadScreenshot til isFashion:\(isFashion) \(-uploadStart.timeIntervalSinceNow) sec assetId:\(asset.localIdentifier)")
                let screenshot = dataModel.saveScreenshot(managedObjectContext: moc,
                                                          assetId: asset.localIdentifier,
                                                          isFashion: isFashion,
                                                          createdAt: asset.creationDate)
                if isFashion {
                    NSLog("uploadScreenshot til db saved \(-uploadStart.timeIntervalSinceNow) sec assetId:\(asset.localIdentifier)")
                    let imageData = UIImageJPEGRepresentation(image, 0.95)
                    firstly { _ -> Promise<[[String : Any]]> in
                        NSLog("uploadScreenshot til jpeg \(-uploadStart.timeIntervalSinceNow) sec assetId:\(asset.localIdentifier)")
                        return NetworkingPromise.uploadToSyte(imageData: imageData)
                        }.then(on: self.processingQ) { segments -> Void in
                            NSLog("uploadScreenshot til Syte response \(-uploadStart.timeIntervalSinceNow) sec assetId:\(asset.localIdentifier)")
                            self.saveShoppables(managedObjectContext: moc, screenshot: screenshot, segments: segments)
                        }.catch { error in
                            print("uploadScreenshot inner uploadToSyte catch error:\(error)")
                    }
                }
            }.always(on: self.serialQ) {
                self.screenshotsToProcess -= 1
                if self.screenshotsToProcess == 0 {
                    self.endSync()
                } else if self.screenshotsToProcess < 0 {
                    print("WTF? negative screenshotsToProcess:\(self.screenshotsToProcess) after subtracting one")
                }
            }.catch { error in
                print("uploadScreenshot outer Clarifai catch error:\(error)")
        }
    }
    
    func extractProducts(shoppable: Shoppable, managedObjectContext: NSManagedObjectContext) {
        guard let offersUrl = shoppable.offersURL,
            let url = URL(string: (offersUrl.hasPrefix("//") ? "https:" + offersUrl : offersUrl)) else {
                print("No offersUrl for shoppable order:\(shoppable.order)")
                return
        }
        NetworkingPromise.downloadInfo(url: url).then(on: self.processingQ) { productsDict -> Void in
            guard let productsArray = productsDict["ads"] as? [[String : Any]],
                productsArray.count > 0 else {
                    print("AssetSyncModel extractProducts error parsing productsArray")
                    return
            }
            let dataModel = DataModel.sharedInstance
            var order: Int16 = 0
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
                shoppable.productCount += 1 // Before saveProduct gets this saved too.
                let _ = dataModel.saveProduct(managedObjectContext: managedObjectContext,
                                              shoppable: shoppable,
                                              order: order,
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
                order += 1
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

    func saveShoppables(managedObjectContext: NSManagedObjectContext, screenshot: Screenshot, segments: [[String : Any]]) { //-> Promise<[String]> {
//        return Promise { fulfill, reject in
            var order: Int16 = 0
            var offers: [String] = []
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
                offers.append(offersURL)
                let label = segment["label"] as? String
                screenshot.shoppablesCount += 1
                let shoppable = DataModel.sharedInstance.saveShoppable(managedObjectContext: managedObjectContext,
                                                                       screenshot: screenshot,
                                                                       order: order,
                                                                       label: label,
                                                                       offersURL: offersURL,
                                                                       b0x: b0x,
                                                                       b0y: b0y,
                                                                       b1x: b1x,
                                                                       b1y: b1y)
                order += 1
                self.extractProducts(shoppable: shoppable, managedObjectContext: managedObjectContext)
            }
            if offers.count > 0 {
                self.sendScreenshotAddedLocalNotification(assetId: screenshot.assetId ?? "")
//                fulfill(offers)
//            } else {
//                let emptyError = NSError(domain: "Craze", code: 6, userInfo: [NSLocalizedDescriptionKey : "No shoppable segments"])
//                reject(emptyError)
            }
//        }
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
        fetchOptions.predicate = NSPredicate(format: "(mediaSubtype & %d) != 0", PHAssetMediaSubtype.photoScreenshot.rawValue)
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 3
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
    
    func beginSync() {
        isSyncing = true
        NSLog("beginSync")
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
        NSLog("endSync")
        isSyncing = false
        if shouldSyncAgain {
            shouldSyncAgain = false
            syncPhotos()
        }
    }
    
    func countAndPrint(name: String, set: Set<String>) {
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
            guard PermissionsManager.shared().hasPermission(for: .photo),
                self.isSyncReady() else {
                    NSLog("syncPhotos refused by guard")
                    return
            }
            self.beginSync()
            let photosSet = self.retrieveAllScreenshotAssetIds()
            let dbSet = DataModel.sharedInstance.retrieveCompleteAssetIds()
            let toDeleteFromDB = dbSet.subtracting(photosSet)//.union(changedAssetIds)
            let toUpload = photosSet.subtracting(dbSet)//.union(changedAssetIds)
            // TODO: Remove changedAssetIds as each screenshot is successfully saved.
            //changedAssetIds = []
            self.countAndPrint(name: "photosSet", set: photosSet)
            self.countAndPrint(name: "dbSet", set: dbSet)
            self.countAndPrint(name: "toDeleteFromDB", set: toDeleteFromDB)
            self.countAndPrint(name: "toUpload", set: toUpload)
            if toDeleteFromDB.count > 0 {
                DataModel.sharedInstance.deleteScreenshots(assetIds: toDeleteFromDB)
            }
            if toUpload.count > 0 {
                self.allScreenshotAssets?.enumerateObjects(options: [.reverse]) { (asset: PHAsset, index: Int, stop: UnsafeMutablePointer<ObjCBool>) in
                    if toUpload.contains(asset.localIdentifier) {
                        self.screenshotsToProcess += 1
                        self.processingQ.async {
                            self.uploadScreenshot(asset: asset)
                        }
                    }
                }
            }
            NSLog("enumerated assets to upload")
            if self.screenshotsToProcess == 0 {
                self.endSync()
            }
        }
    }
    
}

extension AssetSyncModel {
    
    func sendScreenshotAddedLocalNotification(assetId: String) {
        guard PermissionsManager.shared().hasPermission(for: .push) else {
            print("sendScreenshotAddedLocalNotification refused by guard")
            return
        }
        let content = UNMutableNotificationContent()
        content.title = "Congratulations!"
        content.body = "Tap to shop your screenshot."
        content.sound = UNNotificationSound.default()
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
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
