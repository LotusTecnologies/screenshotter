//
//  Product+craze.swift
//  screenshot
//
//  Created by Jonathan Rose on 6/3/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import Foundation
import CoreData


extension Product {
    
    func getSortDateForProductBar() -> Date {
        
        var date = Date.distantPast
        
        if self.isFavorite, let dateFavorited = self.dateFavorited as Date?{
            date = dateFavorited
        }
        
        if  let dateViewed = self.dateViewed as Date?{
            if dateViewed.compare(date) == .orderedDescending {
                date = dateViewed
            }
        }
        
        return date
    }
    
    public func recordViewedProduct(){
        let now = Date()
        let managedObjectID = self.objectID
        DataModel.sharedInstance.performBackgroundTask { (managedObjectContext) in
            let fetchRequest: NSFetchRequest<Product> = Product.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "SELF == %@", managedObjectID)
            fetchRequest.sortDescriptors = nil
            
            do {
                let results = try managedObjectContext.fetch(fetchRequest)
                for product in results {
                    product.dateViewed = now
                    product.dateSortProductBar = product.getSortDateForProductBar()
                }
                try managedObjectContext.save()
            } catch {
                DataModel.sharedInstance.receivedCoreDataError(error: error)
                print("recordViewedProduct objectID:\(managedObjectID) results with error:\(error)")
            }
        }
    }
    
    
    public func setFavorited(toFavorited: Bool) {
        DataModel.sharedInstance.favorite(toFavorited: toFavorited, productOIDs: [self.objectID])
    }
    
    @objc dynamic var calculatedDisplayTitle:String? {
        get {
            if let displayBrand = brand,
                !displayBrand.isEmpty {
                return displayBrand
            } else {
                return merchant
            }
        }
    }
    
    public func isSale() -> Bool {
        return floatPrice < floatOriginalPrice
    }
    
    public func imageURLs() -> [URL] {
        return altImageURLs?.components(separatedBy: ",").compactMap {URL(string: $0)} ?? []
    }
    
    func productTitle() -> String? {
        return productDescription?.productTitle()
    }
    
    func isSimmilar(_ product:Product?) -> Bool{
        if let product = product {
            let similar = (product.price == self.price && product.merchant == self.merchant && product.productTitle() == self.productTitle() )
            var sameId = false
            if let id1 = self.id, let id2 = product.id, !id1.isEmpty, !id2.isEmpty {
                sameId = id1 == id2
            }
            return  similar || sameId
        }
        return false
    }
}
