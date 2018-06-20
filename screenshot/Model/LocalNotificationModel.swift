//
//  LocalNotificationModel.swift
//  screenshot
//
//  Created by Gershon Kagan on 06/19/2018.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import MobileCoreServices // kUTTypeImage
import UserNotifications

enum LocalNotificationIdentifier: String {
    case screenshotAdded        = "CrazeLocal"
    case inactivityDiscover     = "CrazeInactivityDiscover"
    case favoritedItem          = "CrazeFavoritedItem"
    case tappedProduct          = "CrazeTappedProduct"
}

class LocalNotificationModel {
    
    static let shared = LocalNotificationModel()
    static func setup() {
        let _ = LocalNotificationModel.shared
    }
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: .UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: .UIApplicationDidEnterBackground, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func applicationWillEnterForeground() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [LocalNotificationIdentifier.inactivityDiscover.rawValue, LocalNotificationIdentifier.favoritedItem.rawValue, LocalNotificationIdentifier.tappedProduct.rawValue])
    }
    
    @objc func applicationDidEnterBackground() {
        scheduleInactivityDiscoverLocalNotification()
    }
    
    func sendScreenshotAddedLocalNotification(assetId: String, imageData: Data?) {
        guard PermissionsManager.shared.hasPermission(for: .push) else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "notification.title".localized
        content.body = "notification.message".localized
        if let lastNotificationSound = UserDefaults.standard.object(forKey: UserDefaultsKeys.dateLastSound) as? Date,
            -lastNotificationSound.timeIntervalSinceNow < 60 { // 1 minute
            content.sound = nil
        } else {
            content.sound = UNNotificationSound.default()
        }
        UserDefaults.standard.setValue(Date(), forKey: UserDefaultsKeys.dateLastSound)
        content.userInfo = [Constants.openingScreenKey  : Constants.openingScreenValueScreenshot]
        
        var identifier = LocalNotificationIdentifier.screenshotAdded.rawValue
        if let representativeImageData = imageData {
            
            content.userInfo = [Constants.openingScreenKey  : Constants.openingScreenValueScreenshot,
                                Constants.openingAssetIdKey : assetId]
            
            identifier += assetId.replacingOccurrences(of: "/", with: "-")
            // Add image url
            let tmpImageFileUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(identifier).appendingPathExtension("jpg")
            do {
                try representativeImageData.write(to: tmpImageFileUrl)
                let attachment = try UNNotificationAttachment(identifier: identifier,
                                                              url: tmpImageFileUrl,
                                                              options: [UNNotificationAttachmentOptionsTypeHintKey : kUTTypeImage])
                content.attachments = [attachment]
            } catch {
                print("Local notification attachment error:\(error)")
            }
        }
        
        content.badge = NSNumber(value: AccumulatorModel.screenshotUninformed.uninformedCount)
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content,
                                            trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: { (error) in
            if let error = error {
                print("sendScreenshotAddedLocalNotification identifier:\(identifier)  error:\(error)")
            } else {
                Analytics.trackAppSentLocalPushNotification()
            }
        })
    }

    func scheduleInactivityDiscoverLocalNotification() {
        guard PermissionsManager.shared.hasPermission(for: .push) else {
            return
        }

        let content = UNMutableNotificationContent()
        content.body = "notification.inactivity.discover.message".localized
        content.sound = UNNotificationSound.default()
        content.userInfo = [Constants.openingScreenKey  : Constants.openingScreenValueDiscover]
        
//        let threeDays: TimeInterval = 3 * Constants.secondsInDay
        let threeMinutes: TimeInterval = 3 * 60
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: threeMinutes, repeats: false)
        let request = UNNotificationRequest(identifier: LocalNotificationIdentifier.inactivityDiscover.rawValue,
                                            content: content,
                                            trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: { (error) in
            if let error = error {
                print("scheduleInactivityDiscoverLocalNotification identifier:\(LocalNotificationIdentifier.inactivityDiscover.rawValue)  error:\(error)")
            } else {
//                Analytics.trackAppSentLocalPushNotification()  // TODO: GMK Track inactivity push
            }
        })
    }

    func cancelInactivityDiscoverLocalNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [LocalNotificationIdentifier.inactivityDiscover.rawValue])
    }
    
    func scheduleFavoritedItemLocalNotification(imageURL: String, category: String) {
        guard PermissionsManager.shared.hasPermission(for: .push) else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.body = "notification.favorited.item.message".localized(withFormat: category)
        content.sound = UNNotificationSound.default()
        //        content.userInfo = [Constants.openingScreenKey  : Constants.openingScreenValueDiscover] // TODO: GMK set favorited item userInfo

        var identifier = LocalNotificationIdentifier.favoritedItem.rawValue
        // Add image url
        let tmpImageFileUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(identifier).appendingPathExtension("jpg")
        do {
            try representativeImageData.write(to: tmpImageFileUrl)
            let attachment = try UNNotificationAttachment(identifier: identifier,
                                                          url: tmpImageFileUrl,
                                                          options: [UNNotificationAttachmentOptionsTypeHintKey : kUTTypeImage])
            content.attachments = [attachment]
        } catch {
            print("Local notification attachment error:\(error)")
        }

        //        let twoDays: TimeInterval = 2 * Constants.secondsInDay
        let twoMinutes: TimeInterval = 2 * 60
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: twoMinutes, repeats: false)
        let request = UNNotificationRequest(identifier: LocalNotificationIdentifier.favoritedItem.rawValue,
                                            content: content,
                                            trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: { (error) in
            if let error = error {
                print("scheduleFavoritedItemLocalNotification identifier:\(identifier)  error:\(error)")
            } else {
                //                Analytics.trackAppSentLocalPushNotification()  // TODO: GMK Track inactivity push
            }
        })
    }
    
    func cancelFavoritedItemLocalNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [LocalNotificationIdentifier.favoritedItem.rawValue])
    }
    
    func scheduleTappedProductLocalNotification(imageURL: String, name: String) {
        guard PermissionsManager.shared.hasPermission(for: .push) else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.body = "notification.tapped.product.message".localized(withFormat: name)
        content.sound = UNNotificationSound.default()
        //        content.userInfo = [Constants.openingScreenKey  : Constants.openingScreenValueDiscover] // TODO: GMK set tapped product userInfo

        //        let oneDay: TimeInterval = Constants.secondsInDay
        let oneMinute: TimeInterval = 60
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: oneMinute, repeats: false)
        let request = UNNotificationRequest(identifier: LocalNotificationIdentifier.tappedProduct.rawValue,
                                            content: content,
                                            trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: { (error) in
            if let error = error {
                print("scheduleTappedProductLocalNotification identifier:\(LocalNotificationIdentifier.tappedProduct.rawValue)  error:\(error)")
            } else {
                //                Analytics.trackAppSentLocalPushNotification()  // TODO: GMK Track inactivity push
            }
        })
    }
    
    func cancelTappedProductLocalNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [LocalNotificationIdentifier.tappedProduct.rawValue])
    }
    
    func postLatestFavorite() {
        DataModel.sharedInstance.retrieveLatestFavorite().then { imageURL, categories -> Void in
            if let imageURL = imageURL {
                self.scheduleFavoritedItemLocalNotification(imageURL: imageURL, category: categories ?? "fav")
            } else {
                print("postLatestFavorite empty imageURL")
            }
        }
    }
    
    func postLatestTapped() {
        DataModel.sharedInstance.retrieveLatestTapped().then { imageURL, name -> Void in
            if let imageURL = imageURL {
                self.scheduleTappedProductLocalNotification(imageURL: imageURL, name: name ?? "")
            } else {
                print("postLatestTapped empty imageURL")
            }
        }
    }
    
}
