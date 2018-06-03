//
//  Shoppable+craze.swift
//  screenshot
//
//  Created by Jonathan Rose on 6/3/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import CoreData


extension Shoppable {
    public func relatedImagesUrl() -> URL? {
        if let urlString = self.relatedImagesURLString {
            return URL.urlWith(string: urlString, queryParameters: ["feed":"craze_ctl"])
        }
        return nil
    }
    
    public func relativeRect() -> CGRect{
        let topLeft = CGPoint.init(x: self.b0x, y: self.b0y)
        let bottomRight = CGPoint.init(x: self.b1x, y: self.b1y)
        return CGRect.rectWith(topLeft: topLeft, bottomRight: bottomRight)
    }
    
    public func frame(size: CGSize) -> CGRect {
        let relativeRect = self.relativeRect()
        return size.rectFrom(relativeSizeRect: relativeRect)
    }
    
    public func cropped(image: UIImage, thumbSize:CGSize) -> UIImage? {
        return UIImage.cropped(image: image, thumbSize: thumbSize, relativeSizeCropRect: self.relativeRect())
    }
    
    private func productFilter(managedObjectContext: NSManagedObjectContext, optionsMask: Int) -> ProductFilter? {
        let shoppableID = self.objectID
        let fetchRequest: NSFetchRequest<ProductFilter> = ProductFilter.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "shoppable == %@ AND optionsMask == %d", shoppableID, optionsMask)
        fetchRequest.sortDescriptors = nil
        
        do {
            let results = try managedObjectContext.fetch(fetchRequest)
            if let productFilter = results.first {
                return productFilter
            }
        } catch {
            DataModel.sharedInstance.receivedCoreDataError(error: error)
            print("productFilter optionsMask:\(optionsMask)  shoppableID:\(shoppableID) results with error:\(error)")
        }
        return nil
    }
    
    private func productFiltersContains(managedObjectContext: NSManagedObjectContext, optionsMask: ProductsOptionsMask) -> Bool {
        return productFilter(managedObjectContext: managedObjectContext, optionsMask: optionsMask.rawValue) != nil
    }
    
    func addProductFilter(managedObjectContext: NSManagedObjectContext, optionsMask: ProductsOptionsMask, rating: Int16 = 0) {
        let productFilterToSave = ProductFilter(context: managedObjectContext)
        productFilterToSave.optionsMask = Int32(optionsMask.rawValue)
        productFilterToSave.rating = rating
        productFilterToSave.productCount = 0
        productFilterToSave.dateSet = Date()
        productFilterToSave.shoppable = self
    }
    
    func getLastFilter() -> ProductFilter? {
        let lastSetDescriptor = NSSortDescriptor(key: "dateSet", ascending: false)
        if let lastSetFilter = productFilters?.sortedArray(using: [lastSetDescriptor]).first as? ProductFilter {
            return lastSetFilter
        }
        return nil
    }
    
    // Updates all this screenshot's shoppables' productFilters' dateSet.
    func set(productsOptions: ProductsOptions, callback: @escaping () -> Void) {
        guard let screenshotId = self.screenshot?.objectID else {
            return
        }
        let assetId = self.screenshot?.assetId
        let optionsMask = ProductsOptionsMask(productsOptions.category, productsOptions.gender, productsOptions.size)
        let optionsMaskInt = optionsMask.rawValue
        DataModel.sharedInstance.performBackgroundTask { (managedObjectContext) in
            let fetchRequest: NSFetchRequest<Shoppable> = Shoppable.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "screenshot == %@", screenshotId)
            fetchRequest.sortDescriptors = nil
            
            do {
                let results = try managedObjectContext.fetch(fetchRequest)
                for shoppable in results {
                    if let lastSetMask = shoppable.getLast(),
                        lastSetMask.rawValue & 0x01C0 != optionsMaskInt & 0x01C0 { // Category bits
                        if let screenshot = shoppable.screenshot {
                            screenshot.hideWorkhorse(deleteImage: false)
                            screenshot.syteJson = (optionsMaskInt & ProductsOptionsMask.categoryFurniture.rawValue > 0) ? "f" : "h"
                            AssetSyncModel.sharedInstance.processingQ.async {
                                AssetSyncModel.sharedInstance.rescanClassification(assetId: screenshot.assetId!, imageData: screenshot.imageData as Data?, optionsMask: optionsMask)
                            }
                        }
                        break // Break out of the shoppable for loop
                    }
                    if let matchingFilter = shoppable.productFilters?.filtered(using: NSPredicate(format: "optionsMask == %d", optionsMaskInt)).first as? ProductFilter {
                        matchingFilter.dateSet = Date()
                        if matchingFilter.productCount == 0,
                            let actualFilteredProductCount = shoppable.products?.filtered(using: NSPredicate(format: "(optionsMask & %d) == %d", optionsMaskInt, optionsMaskInt)).count {
                            matchingFilter.productCount = Int16(actualFilteredProductCount)
                        }
                        shoppable.productFilterCount = matchingFilter.productCount
                        continue
                    }
                    shoppable.addProductFilter(managedObjectContext: managedObjectContext, optionsMask: optionsMask)
                    shoppable.productFilterCount = 0
                    guard let offersURL = shoppable.offersURL else {
                        continue
                    }
                    if let actualFilteredProductCount = shoppable.products?.filtered(using: NSPredicate(format: "(optionsMask & %d) == %d", optionsMaskInt, optionsMaskInt)).count,
                        actualFilteredProductCount > 0 {
                        continue
                    }
                    AssetSyncModel.sharedInstance.reExtractProducts(assetId:assetId, shoppableId: shoppable.objectID, optionsMask: optionsMask, offersURL: offersURL)
                }
                try managedObjectContext.save()
                DispatchQueue.main.async(execute: callback)
            } catch {
                DataModel.sharedInstance.receivedCoreDataError(error: error)
                print("shoppable set optionsMask results with error:\(error)")
            }
        }
    }
    
    func getLast() -> ProductsOptionsMask? {
        if let lastSetFilter = getLastFilter() {
            return ProductsOptionsMask(rawValue: Int(lastSetFilter.optionsMask))
        }
        return nil
    }
    
    public func getRating() -> Int16 {
        if let lastSetFilter = getLastFilter() {
            return lastSetFilter.rating
        }
        return 0
    }
    
    public func setRating(positive: Bool) {
        let shoppableObjectID = self.objectID
        let imageUrl = self.screenshot?.uploadedImageURL
        let offersUrl = self.offersURL
        let b0x = self.b0x
        let b0y = self.b0y
        let b1x = self.b1x
        let b1y = self.b1y
        
        let dataModel = DataModel.sharedInstance
        dataModel.performBackgroundTask { (managedObjectContext) in
            if let shoppable = managedObjectContext.shoppableWith(objectId: shoppableObjectID) {
                let productFilters = shoppable.productFilters?.sortedArray(using: [NSSortDescriptor(key: "dateSet", ascending: false)])
                let positiveRating: Int16 = 5
                let negativeRating: Int16 = 1
                let ratingValue: Int16 = positive ? positiveRating : negativeRating
                let optionsMask: ProductsOptionsMask
                if let productFilter = productFilters?.first as? ProductFilter{
                    productFilter.rating = ratingValue
                    optionsMask = ProductsOptionsMask(rawValue: Int(productFilter.optionsMask))
                } else {
                    optionsMask = ProductsOptionsMask(.auto, .auto, .adult) // Historical value that was never set.
                    shoppable.addProductFilter(managedObjectContext: managedObjectContext, optionsMask: optionsMask, rating: ratingValue)
                }
                var augmentedOffersUrl: String? = nil
                if let offersUrl = offersUrl {
                    augmentedOffersUrl = AssetSyncModel.sharedInstance.augmentedUrl(offersURL: offersUrl, optionsMask: optionsMask)?.absoluteString
                }
                NetworkingPromise.sharedInstance.feedbackToSyte(isPositive: positive, imageUrl: imageUrl, offersUrl: augmentedOffersUrl, b0x: b0x, b0y: b0y, b1x: b1x, b1y: b1y)
                
                if positive {
                    Analytics.trackShoppableRatingPositive(shoppable: shoppable)
                } else {
                    Analytics.trackShoppableRatingNegative(shoppable: shoppable)
                }
                managedObjectContext.saveIfNeeded()
            }
        }
    }
    
    
    func deleteSubshoppable(){
        let shoppableObjectId = self.objectID
        DataModel.sharedInstance.performBackgroundTask { (context) in
            if let shoppable = context.shoppableWith(objectId: shoppableObjectId){
                var toDelete:[Product] = []
                if let products = shoppable.products{
                    for product in products {
                        if let product = product as? Product{
                            if !product.isFavorite {
                                toDelete.append(product)
                            }else{
                                product.screenshot = shoppable.screenshot
                                product.shoppable = shoppable.parentShoppable
                            }
                        }
                    }
                }
                for product in toDelete {
                    context.delete(product)
                }
                context.delete(shoppable)
                context.saveIfNeeded()
            }
        }
    }
    
}
