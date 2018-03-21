//
//  PHAsset+craze.swift
//  screenshot
//
//  Created by Jonathan Rose on 3/18/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import Photos
import PromiseKit
extension PHAsset {
    static func assetWith(assetId:String) -> PHAsset?{
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "localIdentifier == %@", assetId)
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        return fetchResult.firstObject
    }
    
    func goodTargetSize() -> CGSize{
        let screenSizePx = UIScreen.main.nativeBounds.size
        let targetSize = CGSize(width: screenSizePx.width / 2, height: screenSizePx.height / 2)
        let imageSize = CGSize.init(width: self.pixelWidth, height: self.pixelHeight)
        let targetRect = CGRect.init(origin: .zero, size: targetSize)
        let imageRect = CGRect.init(origin: .zero, size: imageSize)
        let resize = imageRect.aspectFit(in: targetRect)
        return resize.size
    }
    
    func image(allowFromICloud:Bool) -> Promise<UIImage>{
        print("processing image \(self.localIdentifier)")
        return Promise.init(resolvers: { (fulfill, reject) in
            let imageRequestOptions = PHImageRequestOptions()
            imageRequestOptions.version = .current
            imageRequestOptions.deliveryMode = .opportunistic
            imageRequestOptions.resizeMode = .none
            imageRequestOptions.isNetworkAccessAllowed = allowFromICloud
            imageRequestOptions.isSynchronous = !allowFromICloud
            let size = self.goodTargetSize()
            PHImageManager.default().requestImage(for: self, targetSize: size, contentMode: .aspectFill, options: imageRequestOptions, resultHandler: { (image, info) in
                if let imageError = info?[PHImageErrorKey] as? NSError {
                    AnalyticsTrackers.standard.track(.errImgHang, properties: ["reason" : "PHImageErrorKey. info:\(info ?? ["-" : "-"])"])
                    reject(imageError)
                } else if let isCancelled = info?[PHImageCancelledKey] as? Bool,
                    isCancelled == true {
                    AnalyticsTrackers.standard.track(.errImgHang, properties: ["reason" : "PHImageCancelledKey. info:\(info ?? ["-" : "-"])"])
                    let cancelledError = NSError(domain: "Craze", code: 7, userInfo: [NSLocalizedDescriptionKey : "Image request canceled"])
                    reject(cancelledError)
                    
                } else if let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool, isDegraded == true {
                    //this will be called again
                } else if let image = image {
                    fulfill(image)
                } else {
                    AnalyticsTrackers.standard.track(.errImgHang, properties: ["reason" : "No image. info:\(info ?? ["-" : "-"])"])
                    let emptyError = NSError(domain: "Craze", code: 2, userInfo: [NSLocalizedDescriptionKey : "Asset returned no image"])
                    reject(emptyError)
                }
            })
        })
    }
}
