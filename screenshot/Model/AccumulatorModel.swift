//
//  AccumulatorModel.swift
//  screenshot
//
//  Created by Corey Werner on 5/13/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation

class AccumulatorModel: NSObject {
    static let screenshot = ScreenshotAccumulatorModel()
    static let favorite = FavoriteAccumulatorModel()
}

class ScreenshotAccumulatorModel: NSObject {
    
    // MARK: New Screenshots
    
    var newCount: Int {
        return assetIds.count
    }
    
    private(set) var assetIds: Set<String> = {
        if let array = UserDefaults.standard.value(forKey: UserDefaultsKeys.newScreenshotsAssetIds) as? [String]{
            return Set(array)
        }else{
            let a:[String] = []
            UserDefaults.standard.setValue(a, forKey: UserDefaultsKeys.newScreenshotsAssetIds)
            return Set(a)
        }
    }()
    
    private func modifyCount(_ block:@escaping ()->()) {
        DispatchQueue.main.async {  //we want to post the notification on the main queue
            let countBefore = self.newCount
            block()
            let countAfter = self.newCount
            
            if countBefore != countAfter {
                UserDefaults.standard.set(Array(self.assetIds), forKey: UserDefaultsKeys.newScreenshotsAssetIds)
                NotificationCenter.default.post(name: .accumulatorModelDidUpdate, object: self)
            }
        }
    }
    
    func resetNewCount() {
        modifyCount {
            self.assetIds.removeAll()
        }
    }
    
    func removeAssetId(_ assetId:String){
        modifyCount {
            let isMany = self.newCount > Constants.notificationProductToImportCountLimit
            if !isMany { // once it is 'many' it can only be cleared by user interaction, ie `resetNewScreenshotsCount`
                self.assetIds.remove(assetId)
            }
        }
    }
    
    func addAssetId(_ assetId:String){
        modifyCount {
            self.assetIds.insert(assetId)
        }
    }
    
    // MARK: Uninformed Screenshots
    
    var uninformedCount: Int {
        return UserDefaults.standard.integer(forKey: UserDefaultsKeys.uninformedScreenshotsCount)
    }
    
    func incrementUninformedCount() {
        UserDefaults.standard.set(uninformedCount + 1, forKey: UserDefaultsKeys.uninformedScreenshotsCount)
    }
    
    func resetUninformedCount() {
        UserDefaults.standard.set(0, forKey: UserDefaultsKeys.uninformedScreenshotsCount)
    }
    
}

class FavoriteAccumulatorModel: NSObject {
    
    // MARK: Uninformed Favorites
    
    var uninformedCount: Int {
        return UserDefaults.standard.integer(forKey: UserDefaultsKeys.uninformedFavoritesCount)
    }
    
    func incrementUninformedCount() {
        UserDefaults.standard.set(uninformedCount + 1, forKey: UserDefaultsKeys.uninformedFavoritesCount)
    }
    
    func resetUninformedCount() {
        UserDefaults.standard.set(0, forKey: UserDefaultsKeys.uninformedFavoritesCount)
    }
    
}
