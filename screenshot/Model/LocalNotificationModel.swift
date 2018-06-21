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
import PromiseKit

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
    
    // MARK: NotificationCenter Handlers

    @objc func applicationWillEnterForeground() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [LocalNotificationIdentifier.inactivityDiscover.rawValue, LocalNotificationIdentifier.favoritedItem.rawValue, LocalNotificationIdentifier.tappedProduct.rawValue])
    }
    
    @objc func applicationDidEnterBackground() {
        scheduleInactivityDiscoverLocalNotification()
        postLatestFavorite()
        postLatestTapped()
    }
    
    // MARK: Local Notification

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
    
    func scheduleImageLocalNotification(copiedTmpURL: URL, imageURLString: String, identifier: String, body: String, interval: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.body = body
        content.sound = UNNotificationSound.default()
        content.userInfo = [Constants.openingProductKey : imageURLString]
        do {
            let attachment = try UNNotificationAttachment(identifier: identifier,
                                                          url: copiedTmpURL,
                                                          options: [UNNotificationAttachmentOptionsTypeHintKey : kUTTypeImage])
            content.attachments = [attachment]
        } catch {
            print("Local notification attachment error:\(error)")
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content,
                                            trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: { (error) in
            if let error = error {
                print("scheduleImageLocalNotification identifier:\(identifier)  error:\(error)")
            } else {
                //                Analytics.trackAppSentLocalPushNotification()  // TODO: GMK Track scheduleImageLocalNotification push
            }
        })
    }
    
    func postLatestFavorite() {
        guard PermissionsManager.shared.hasPermission(for: .push) else {
            print("postLatestFavorite no push permission")
            return
        }
        var imageURLString = ""
        var category = "fav"
        let identifier = LocalNotificationIdentifier.favoritedItem.rawValue
        DataModel.sharedInstance.retrieveLatestFavorite()
            .then { imageURL, categories -> Promise<URL> in
                imageURLString = imageURL
                category = categories ?? category
                return NetworkingPromise.sharedInstance.downloadTmp(from: imageURLString, identifier: identifier)
            }.then { copiedTmpURL -> Void in
                self.scheduleImageLocalNotification(copiedTmpURL: copiedTmpURL,
                                                    imageURLString: imageURLString,
                                                    identifier: identifier,
                                                    body: "notification.favorited.item.message".localized(withFormat: category),
                                                    interval: 2 * 60) // TODO: GMK 2 * Constants.secondsInDay
        }
    }
    
    func postLatestTapped() {
        guard PermissionsManager.shared.hasPermission(for: .push) else {
            print("postLatestTapped no push permission")
            return
        }
        var imageURLString = ""
        var productTitle = ""
        let identifier = LocalNotificationIdentifier.tappedProduct.rawValue
        DataModel.sharedInstance.retrieveLatestTapped()
            .then { imageURL, title -> Promise<URL> in
                imageURLString = imageURL
                productTitle = title ?? productTitle
                return NetworkingPromise.sharedInstance.downloadTmp(from: imageURLString, identifier: identifier)
            }.then { copiedTmpURL -> Void in
                self.scheduleImageLocalNotification(copiedTmpURL: copiedTmpURL,
                                                    imageURLString: imageURLString,
                                                    identifier: identifier,
                                                    body: "notification.tapped.product.message".localized(withFormat: productTitle),
                                                    interval: 60) // TODO: GMK Constants.secondsInDay
        }
    }
    
}
