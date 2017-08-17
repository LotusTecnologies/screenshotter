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

class AssetSyncModel: NSObject {

    public static let sharedInstance = AssetSyncModel()
    var allScreenshotAssets: PHFetchResult<PHAsset>!
//    var changedAssetIds: [String] = []
    var isRegistered = false
    // TODO: Atomicity
    var isSyncing = false
    var shouldSyncAgain = false

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
        let moc = dataModel.adHocMoc()
        firstly {
            return image(asset: asset)
            }.then { image in
                return ClarifaiModel.sharedInstance.isFashion(image: image)
            }.then { isFashion, image -> Void in
                print("uploadScreenshot isFashion:\(isFashion)")
                let screenshot = dataModel.saveScreenshot(managedObjectContext: moc,
                                                          assetId: asset.localIdentifier,
                                                          isFashion: isFashion,
                                                          createdAt: asset.creationDate)
                if isFashion {
                    let imageData = UIImageJPEGRepresentation(image, 0.95)
                    firstly {
                        return NetworkingPromise.uploadToSyte(imageData: imageData)
                        }.then { segments -> Void in
                            var order: Int16 = 0
                            for segment in segments {
                                guard let b0 = segment["b0"] as? [Any],
                                    b0.count >= 2,
                                    let b1 = segment["b1"] as? [Any],
                                    b1.count >= 2,
                                    let b0x = b0[0] as? Double,
                                    let b0y = b0[1] as? Double,
                                    let b1x = b1[0] as? Double,
                                    let b1y = b1[1] as? Double else {
                                        print("AssetSyncModel error parsing b0, b1")
                                        continue
                                }
                                let label = segment["label"] as? String
                                let offersURL = segment["offers"] as? String
                                screenshot.shoppablesCount += 1
                                let shoppable = dataModel.saveShoppable(managedObjectContext: moc,
                                                                        screenshot: screenshot,
                                                                        order: order,
                                                                        label: label,
                                                                        offersURL: offersURL,
                                                                        b0x: b0x,
                                                                        b0y: b0y,
                                                                        b1x: b1x,
                                                                        b1y: b1y)
                                order += 1
                                self.extractProducts(shoppable: shoppable, managedObjectContext: moc)
                            }
                        }.catch { error in
                            print("uploadScreenshot inner uploadToSyte catch error:\(error)")
                    }
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
        NetworkingModel.downloadProductInfo(url , completionHandler: { (response: URLResponse, responseObject: Any?, error: Error?) in
            if let error = error {
                print("NetworkingModel.downloadProductInfo error:\(error)")
                return
            }
            guard let productsDict = responseObject as? [String : Any],
                let productsArray = productsDict["ads"] as? [[String : Any]],
                productsArray.count > 0 else {
                    print("NetworkingModel.downloadProductInfo Error parsing products")
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
                shoppable.productCount += 1
                let p = dataModel.saveProduct(managedObjectContext: managedObjectContext,
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
                print("saveProduct:\(p)")
                order += 1
            }
        })
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
        let targetSize = CGSize(width: 180, height: 320)
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
        fetchOptions.predicate = NSPredicate(format: "(mediaSubtype & %d) != 0", PHAssetMediaSubtype.photoScreenshot.rawValue)
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        allScreenshotAssets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
    }
    
    func retrieveAllScreenshotAssetIds() -> Set<String> {
        setupAllScreenshotAssets()
        var assetIds = Set<String>()
        allScreenshotAssets.enumerateObjects({ (asset: PHAsset, index: Int, stop: UnsafeMutablePointer<ObjCBool>) in
            assetIds.insert(asset.localIdentifier)
        })
        return assetIds
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
        guard PermissionsManager.shared().hasPermission(for: .photo),
          isSyncReady() else {
            print("syncPhotos refused by guard")
            return
        }
        isSyncing = true
        print("syncPhotos passed guard")
        if !isRegistered {
            registerForPhotoChanges()
        }
        let photosSet = retrieveAllScreenshotAssetIds()
        let dbSet = DataModel.sharedInstance.retrieveCompleteAssetIds()
        let toDeleteFromDB = dbSet.subtracting(photosSet)//.union(changedAssetIds)
        let toUpload = photosSet.subtracting(dbSet)//.union(changedAssetIds)
        // TODO: Remove changedAssetIds as each screenshot is successfully saved.
        //changedAssetIds = []
        countAndPrint(name: "photosSet", set: photosSet)
        countAndPrint(name: "dbSet", set: dbSet)
        countAndPrint(name: "toDeleteFromDB", set: toDeleteFromDB)
        countAndPrint(name: "toUpload", set: toUpload)
        if toDeleteFromDB.count > 0 {
            DataModel.sharedInstance.deleteScreenshots(assetIds: toDeleteFromDB)
        }
        if toUpload.count > 0 {
            allScreenshotAssets.enumerateObjects({ (asset: PHAsset, index: Int, stop: UnsafeMutablePointer<ObjCBool>) in
                if toUpload.contains(asset.localIdentifier) {
                    self.uploadScreenshot(asset: asset)
                }
            })
        }
        isSyncing = false
        if shouldSyncAgain {
            shouldSyncAgain = false
            syncPhotos()
        }
    }
    
}

extension AssetSyncModel: PHPhotoLibraryChangeObserver {
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        print("photoLibraryDidChange")
        if allScreenshotAssets == nil {
            syncPhotos()
        } else if let changes = changeInstance.changeDetails(for: allScreenshotAssets),
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
