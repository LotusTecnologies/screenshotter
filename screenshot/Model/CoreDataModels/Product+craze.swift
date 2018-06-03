//
//  Product+craze.swift
//  screenshot
//
//  Created by Jonathan Rose on 6/3/18.
//  Copyright © 2018 crazeapp. All rights reserved.
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
                    product.hideFromProductBar = false
                }
                try managedObjectContext.save()
            } catch {
                DataModel.sharedInstance.receivedCoreDataError(error: error)
                print("recordViewedProduct objectID:\(managedObjectID) results with error:\(error)")
            }
        }
    }
    
    
    public func setFavorited(toFavorited: Bool) {
        let managedObjectID = self.objectID
        DataModel.sharedInstance.performBackgroundTask { (managedObjectContext) in
            let fetchRequest: NSFetchRequest<Product> = Product.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "SELF == %@", managedObjectID)
            fetchRequest.sortDescriptors = nil
            
            do {
                let results = try managedObjectContext.fetch(fetchRequest)
                for product in results {
                    product.isFavorite = toFavorited
                    if toFavorited {
                        product.track()
                    }else{
                        product.untrack()
                    }
                    if toFavorited == false {
                        product.dateViewed  = nil
                    }
                    if toFavorited {
                        let now = Date()
                        product.dateFavorited = now
                        product.dateSortProductBar = product.getSortDateForProductBar()
                        product.hideFromProductBar = false
                        if let screenshot = product.shoppable?.screenshot {
                            screenshot.addToFavorites(product)
                            if let favoritesCount = screenshot.favorites?.count {
                                screenshot.favoritesCount = Int16(favoritesCount)
                            } else {
                                screenshot.favoritesCount += 1
                            }
                            screenshot.lastFavorited = now
                        }
                    } else {
                        product.dateFavorited = nil
                        if let screenshot = product.shoppable?.screenshot {
                            screenshot.removeFromFavorites(product)
                            if let favorites = screenshot.favorites {
                                screenshot.favoritesCount = Int16(favorites.count)
                            } else {
                                screenshot.favoritesCount = 0
                                screenshot.lastFavorited = nil
                            }
                        }
                    }
                }
                try managedObjectContext.save()
                
                if toFavorited {
                    let score = UserDefaults.standard.integer(forKey: UserDefaultsKeys.gameScore)
                    UserDefaults.standard.set(score + 1, forKey: UserDefaultsKeys.gameScore)
                    AccumulatorModel.favorite.incrementUninformedCount()
                }else{
                    AccumulatorModel.favorite.decrementUninformedCount(by:1)
                }
            } catch {
                DataModel.sharedInstance.receivedCoreDataError(error: error)
                print("setFavorited objectID:\(managedObjectID) results with error:\(error)")
            }
        }
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
    
    var isSupportingUSC: Bool {
        return UIApplication.isUSC && partNumber != nil
    }
    
}
