//
//  AccumulatorModel.swift
//  screenshot
//
//  Created by Corey Werner on 5/13/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import Foundation
import UIKit

extension Notification.Name {
    static let ScreenshotUninformedAccumulatorModelDidChange = Notification.Name(rawValue: "io.crazeapp.screenshot.ScreenshotUninformedAccumulatorModelDidChange")
    static let FavoriteUninformedAccumulatorModelDidChange =  Notification.Name(rawValue: "io.crazeapp.screenshot.FavoriteUninformedAccumulatorModelDidChange")
}

class AccumulatorModel: NSObject {
    static let screenshot = ScreenshotAccumulatorModel()
    static let screenshotUninformed = ScreenshotUninformedAccumulatorModel()

    static let favoriteUninformed = FavoriteUninformedAccumulatorModel()
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
}

class FavoriteUninformedAccumulatorModel: NSObject {
    var uninformedCount: Int {
        return UserDefaults.standard.integer(forKey: UserDefaultsKeys.uninformedFavoritesCount)
    }
    
    func incrementUninformedCount() {
        DispatchQueue.mainAsyncIfNeeded {
            UserDefaults.standard.set(self.uninformedCount + 1, forKey: UserDefaultsKeys.uninformedFavoritesCount)
            NotificationCenter.default.post(name: .FavoriteUninformedAccumulatorModelDidChange, object: nil)
        }
    }
    
    func decrementUninformedCount(by:Int) {
        DispatchQueue.mainAsyncIfNeeded {
            var newCount = self.uninformedCount - by
            if newCount < 0 {
                newCount = 0
            }
            UserDefaults.standard.set(newCount, forKey: UserDefaultsKeys.uninformedFavoritesCount)
            NotificationCenter.default.post(name: .FavoriteUninformedAccumulatorModelDidChange, object: nil)
        }
    }
    
    func resetUninformedCount() {
        DispatchQueue.mainAsyncIfNeeded {
            UserDefaults.standard.set(0, forKey: UserDefaultsKeys.uninformedFavoritesCount)
            NotificationCenter.default.post(name: .FavoriteUninformedAccumulatorModelDidChange, object: nil)
        }
    }
}

class ScreenshotUninformedAccumulatorModel: NSObject {
    var uninformedCount: Int {
        return UserDefaults.standard.integer(forKey: UserDefaultsKeys.uninformedScreenshotsCount)
    }
    
    func decrementUninformedCount(by:Int) {
        DispatchQueue.mainAsyncIfNeeded {
            var newCount = self.uninformedCount - by
            if newCount < 0 {
                newCount = 0
            }
            UserDefaults.standard.set(newCount, forKey: UserDefaultsKeys.uninformedScreenshotsCount)
            NotificationCenter.default.post(name: .ScreenshotUninformedAccumulatorModelDidChange, object: nil)
        }
    }
    
    func incrementUninformedCount() {
        DispatchQueue.mainAsyncIfNeeded {
            UserDefaults.standard.set(self.uninformedCount + 1, forKey: UserDefaultsKeys.uninformedScreenshotsCount)
            NotificationCenter.default.post(name: .ScreenshotUninformedAccumulatorModelDidChange, object: nil)
        }
    }
    
    func resetUninformedCount() {
        DispatchQueue.mainAsyncIfNeeded {
            UserDefaults.standard.set(0, forKey: UserDefaultsKeys.uninformedScreenshotsCount)
            NotificationCenter.default.post(name: .ScreenshotUninformedAccumulatorModelDidChange, object: nil)
        }
    }
}
