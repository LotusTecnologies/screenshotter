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
    case tappedProduct          = "CrazeTappedProduct"
    case saleCount              = "CrazeSaleCount"
    case favoritedItem          = "CrazeFavoritedItem"
    case inactivityDiscover     = "CrazeInactivityDiscover"
}

class LocalNotificationModel {
    
    static let shared = LocalNotificationModel()
    static func setup() {
        let _ = LocalNotificationModel.shared
    }
    
    var sessionStart = NSDate()
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: .UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: .UIApplicationDidEnterBackground, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: NotificationCenter Handlers

    @objc func applicationWillEnterForeground() {
        sessionStart = NSDate()
        UNUserNotificationCenter.current().getPendingNotificationRequests { notificationRequestArray in
            let toCancel = [LocalNotificationIdentifier.tappedProduct.rawValue, LocalNotificationIdentifier.saleCount.rawValue, LocalNotificationIdentifier.favoritedItem.rawValue, LocalNotificationIdentifier.inactivityDiscover.rawValue]
            let toCancelSet = Set<String>(toCancel)
            notificationRequestArray.forEach { notificationRequest in
                if toCancelSet.contains(notificationRequest.identifier) {
                    switch notificationRequest.identifier {
                    case LocalNotificationIdentifier.tappedProduct.rawValue:
                        Analytics.trackTimedLocalNotificationCancelled(source: .tappedProduct)
                        self.cancelProductInNotif(productKey: notificationRequest.content.userInfo[Constants.openingProductKey] as? String)
                    case LocalNotificationIdentifier.saleCount.rawValue:
                        Analytics.trackTimedLocalNotificationCancelled(source: .saleCount)
                    case LocalNotificationIdentifier.favoritedItem.rawValue:
                        Analytics.trackTimedLocalNotificationCancelled(source: .favoritedItem)
                        self.cancelProductInNotif(productKey: notificationRequest.content.userInfo[Constants.openingProductKey] as? String)
                    case LocalNotificationIdentifier.inactivityDiscover.rawValue:
                        Analytics.trackTimedLocalNotificationCancelled(source: .inactivityDiscover)
                    default:
                        print("Cancel unknown timedLocalNotification. WTF?")
                    }
                    print("Canceling notification \(notificationRequest.identifier)")
                }
            }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: toCancel)
        }
    }
    
    @objc func applicationDidEnterBackground() {
        postLatestTapped()
        postSaleCount()
        postLatestFavorite()
        scheduleInactivityDiscoverLocalNotification()
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

    func scheduleImageLocalNotification(copiedTmpURL: URL?, userInfo: [String : Any], identifier: String, body: String, interval: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.body = body
        content.sound = UNNotificationSound.default()
        content.userInfo = userInfo
        if let copiedTmpURL = copiedTmpURL {
            do {
                let attachment = try UNNotificationAttachment(identifier: identifier,
                                                              url: copiedTmpURL)
                content.attachments = [attachment]
            } catch {
                print("Local notification attachment error:\(error)")
            }
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content,
                                            trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: { (error) in
            if let error = error {
                print("scheduleImageLocalNotification identifier:\(identifier)  error:\(error)")
            } else {
                switch identifier {
                case LocalNotificationIdentifier.tappedProduct.rawValue:
                    Analytics.trackTimedLocalNotificationScheduled(source: .tappedProduct)
                case LocalNotificationIdentifier.saleCount.rawValue:
                    Analytics.trackTimedLocalNotificationScheduled(source: .saleCount)
                case LocalNotificationIdentifier.favoritedItem.rawValue:
                    Analytics.trackTimedLocalNotificationScheduled(source: .favoritedItem)
                case LocalNotificationIdentifier.inactivityDiscover.rawValue:
                    Analytics.trackTimedLocalNotificationScheduled(source: .inactivityDiscover)
                default:
                    print("Schedule unknown timedLocalNotification. WTF?")
                }
            }
        })
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
                                                    userInfo: [Constants.openingProductKey : imageURLString],
                                                    identifier: identifier,
                                                    body: "notification.tapped.product.message".localized(withFormat: productTitle),
                                                    interval: Constants.secondsInDay)
        }
    }

    func postSaleCount() {
        guard PermissionsManager.shared.hasPermission(for: .push) else {
            print("postSaleCount no push permission")
            return
        }
        var imageURLString = ""
        var saleCount = 0
        let identifier = LocalNotificationIdentifier.saleCount.rawValue
        DataModel.sharedInstance.retrieveSaleCount(from: sessionStart)
            .then { productCount -> Promise<URL> in
                imageURLString = "https://images-na.ssl-images-amazon.com/images/I/71F2ZBXnwtL._SX679_.jpg" // TODO: GMK collage from first 4 images.
                saleCount = productCount
                return NetworkingPromise.sharedInstance.downloadTmp(from: imageURLString, identifier: identifier)
            }.then { copiedTmpURL -> Void in
                self.scheduleImageLocalNotification(copiedTmpURL: copiedTmpURL,
                                                    userInfo: [Constants.openingScreenKey : Constants.openingScreenValueScreenshot],
                                                    identifier: identifier,
                                                    body: saleCount == 1 ? "notification.sale.count.message.single".localized(withFormat: saleCount) : "notification.sale.count.message.plural".localized(withFormat: saleCount),
                                                    interval: 2 * Constants.secondsInDay)
        }
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
                                                    userInfo: [Constants.openingProductKey : imageURLString],
                                                    identifier: identifier,
                                                    body: "notification.favorited.item.message".localized(withFormat: category),
                                                    interval: 3 * Constants.secondsInDay)
        }
    }
    
    func scheduleInactivityDiscoverLocalNotification() {
        guard PermissionsManager.shared.hasPermission(for: .push) else {
            return
        }
        
        self.scheduleImageLocalNotification(copiedTmpURL: nil,
                                            userInfo: [Constants.openingScreenKey : Constants.openingScreenValueDiscover],
                                            identifier: LocalNotificationIdentifier.inactivityDiscover.rawValue,
                                            body: "notification.inactivity.discover.message".localized,
                                            interval: 4 * Constants.secondsInDay)
    }
    
    func cancelProductInNotif(productKey: String?) {
        guard let productKey = productKey else {
            return
        }
        DataModel.sharedInstance.markProductNotInNotif(imageURL: productKey)
    }
    
}
