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

class AssetSyncModel: NSObject {

    public static let sharedInstance = AssetSyncModel()

    let imageMediaType = kUTTypeImage as String;
    
    func uploadLastScreenshot(completionHandler: ((_ success: Bool) -> Void)?) {
        let matchModel = MatchModel.shared()!
        let dataModel = DataModel.sharedInstance
        let moc = dataModel.adHocMoc()
        matchModel.logClarifaiSyteInitial({ (response: URLResponse, responseObject: Any?, error: Error?) in
            guard error == nil,
                let responseObjectDict = responseObject as? [String : AnyObject],
                let uploadedURLString = responseObjectDict.keys.first,
                let segments = responseObjectDict[uploadedURLString] as? [[String : AnyObject]],
                segments.count > 0,
                let screenshot = dataModel.lastSavedScreenshot(managedObjectContext: moc),
                (screenshot.shoppables == nil || screenshot.shoppables!.count == 0) else {
                    print("AssetSyncModel uploadLastScreenshot error:\(error)")
                    completionHandler?(false)
                    return
            }
            print("AssetSyncModel response:\(response)\nresponseObject:\(responseObject ?? ""))")
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
                print("b0x:\(b0x)  b0y:\(b0y)  b1x:\(b1x)  b1y:\(b1y)")
                let shoppable = dataModel.saveShoppable(managedObjectContext: moc,
                                                        screenshot: screenshot,
                                                        order: order,
                                                        label: label,
                                                        offersURL: offersURL,
                                                        b0x: b0x,
                                                        b0y: b0y,
                                                        b1x: b1x,
                                                        b1y: b1y)
                self.extractProducts(shoppable: shoppable, managedObjectContext: moc)
                order += 1
            }
            completionHandler?(true)
        })
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
    
    func image(assetId: String, callback: @escaping ((UIImage?) -> Void)) {
        let fetchOptions = PHFetchOptions()
        //fetchOptions.predicate = NSPredicate(format: "mediaSubtype == %lu", .photoScreenshot)//PHAssetMediaSubtypePhotoScreenshot)
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 1;
        
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: fetchOptions)
        
        guard let asset = assets.firstObject else {
            print("No asset for assetId:\(assetId)")
            callback(nil)
            return
        }
        
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
                                                callback(image)
        })
    }

}
