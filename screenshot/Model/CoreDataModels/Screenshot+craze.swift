//
//  Screenshot+craze.swift
//  screenshot
//
//  Created by Jonathan Rose on 6/3/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import CoreData
import SDWebImage

enum ScreenshotSource : String {
    case unknown
    case discover
    case gallery
    case camera
    case screenshot
    case shuffle
    case share
    case tutorial
    case nativeShare = "native-share" //Andriod only - here for completment of analytics
    case burrow
    
    var isUserGenerated:Bool {
        return (self == .nativeShare || self == .gallery || self == .share || self == .unknown || self == .screenshot || self == .camera)
    }
}


extension Screenshot {
    
    var source:ScreenshotSource {
        get {
            if let sourceString = self.sourceString,  let source = ScreenshotSource.init(rawValue: sourceString) {
                return source
            }else{
                return .unknown
            }
        }
        set (newValue){
            self.sourceString = newValue.rawValue
        }
    }
    var isShamrockVersion:Bool {
        return self.assetId?.hasPrefix("shamrock") ?? false
    }
    
    // hideWorkhorse is not meant to be called from UI code,
    // but may be called on the main queue, even if generally called on a background queue.
    // It does not actually hide the screenshot.
    func hideWorkhorse(deleteImage: Bool = true) {
        if let context = self.managedObjectContext {
            if let favoriteSet = favorites as? Set<Product>,
                favoriteSet.count > 0 {
                favoriteSet.forEach { $0.shoppable = nil }
            } else if deleteImage {
                if isFromShare {
                    context.delete(self)
                    return
                }
                imageData = nil
            }
            if let shoppablesSet = shoppables as? Set<Shoppable> {
                shoppablesSet.forEach { context.delete($0) }
            }
            shoppablesCount = -1
            syteJson = nil
            shareLink = nil
            uploadedImageURL = nil
        }
    }
    
    public func setHide() {
        let managedObjectID = self.objectID
        DataModel.sharedInstance.performBackgroundTask { (managedObjectContext) in
            do {
                guard let screenshot = managedObjectContext.object(with: managedObjectID) as? Screenshot,
                    screenshot.isHidden == false else {
                        return
                }
                screenshot.isHidden = true
                screenshot.hideWorkhorse()
                try managedObjectContext.save()
            } catch {
                DataModel.sharedInstance.receivedCoreDataError(error: error)
                print("setHide objectID:\(managedObjectID) results with error:\(error)")
            }
        }
    }
    
    public func setViewed() {
        let managedObjectID = self.objectID
        DataModel.sharedInstance.performBackgroundTask { (managedObjectContext) in
            let fetchRequest: NSFetchRequest<Screenshot> = Screenshot.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "SELF == %@", managedObjectID)
            fetchRequest.sortDescriptors = nil
            
            do {
                let results = try managedObjectContext.fetch(fetchRequest)
                for screenshot in results {
                    screenshot.isNew = false
                }
                try managedObjectContext.save()
            } catch {
                DataModel.sharedInstance.receivedCoreDataError(error: error)
                print("setViewed objectID:\(managedObjectID) results with error:\(error)")
            }
        }
    }
    
    func shoppablesBoundingFrame(in size: CGSize) -> CGRect {
        var frame: CGRect = .null
        
        if let shoppables = shoppables {
            for shoppable in shoppables {
                if let shoppable = shoppable as? Shoppable {
                    if shoppable.parentShoppable == nil {
                        frame = frame.union(shoppable.frame(size: size))
                    }
                }
            }
        }
        
        return frame
    }
    
    var favoritedShoppablesCount: Int {
        if let favoritedShoppablesCount = shoppables?.filtered(using: NSPredicate(format: "ANY products.isFavorite == TRUE")).count {
            return favoritedShoppablesCount
        }
        return 0
    }
    
    
    var favoritedProducts: [Product] {
        let sortDescriptors = [NSSortDescriptor(key: "dateFavorited", ascending: false)]
        if let sortedFavorites = favorites?.sortedArray(using: sortDescriptors) as? [Product] {
            return sortedFavorites
        }
        return []
    }
    
    
    static func createWith(subShoppable:Shoppable ){
        if let imageUrl = subShoppable.imageUrl {
            SDWebImageManager.shared().loadImage(with: URL.init(string: imageUrl), options: [SDWebImageOptions.fromCacheOnly], progress: nil, completed: { (image, data, error, cache, bool, url) in
                
                let imageData:Data? =  {
                    if let data = data {
                        return data
                    }else if let i = image {
                        return AssetSyncModel.sharedInstance.data(for: i)
                    }
                    return nil
                }()
                if let imageData = imageData {
                    DataModel.sharedInstance.performBackgroundTask { (context) in
                        
                        let _ = DataModel.sharedInstance.saveScreenshot(managedObjectContext: context, assetId: imageUrl, createdAt: Date(), isRecognized: true, source: .burrow, isHidden: false, imageData: imageData, uploadedImageURL: imageUrl, syteJsonString: nil)
                        
                        // download stye stuff for URL
                        AssetSyncModel.sharedInstance.syteProcessing(imageClassification: .human, imageData: nil, orImageUrlString: imageUrl, assetId: imageUrl)
                        
                        context.saveIfNeeded()
                    }
                }
            })
        }
       
    }
    
}

