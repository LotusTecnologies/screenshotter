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
import SDWebImage

enum LocalNotificationIdentifier: String {
    case screenshotAdded        = "CrazeLocal"
    case tappedProduct          = "CrazeTappedProduct"
    case saleScreenshot         = "CrazeSaleScreenshot"
    case favoritedItem          = "CrazeFavoritedItem"
    case inactivityDiscover     = "CrazeInactivityDiscover"
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
        cancelPendingNotifications()
    }
    
    @objc func applicationDidEnterBackground() {
        postLatestTapped()
        postSaleScreenshot()
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
            
            identifier += String(assetId.unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) }) // Strip out /.[]
            // Add image url
            let tmpImageFileUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(identifier).appendingPathExtension("jpg")
            do {
                try representativeImageData.write(to: tmpImageFileUrl)
                let attachment = try UNNotificationAttachment(identifier: identifier,
                                                              url: tmpImageFileUrl,
                                                              options: [UNNotificationAttachmentOptionsTypeHintKey : kUTTypeImage])
                content.attachments = [attachment]
            } catch {
                let localizedDescription = "Screenshot notif identifier:\(identifier) attachment error:\(error)"
                print(localizedDescription)
                Analytics.trackAppSentLocalPushNotification(success: false, localizedDescription: localizedDescription)
                Analytics.trackError(type: nil, domain: "Craze", code: 101, localizedDescription: localizedDescription)
            }
        }
        
        content.badge = NSNumber(value: AccumulatorModel.screenshotUninformed.uninformedCount)
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content,
                                            trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: { (error) in
            if let error = error {
                let localizedDescription = "Screenshot notif identifier:\(identifier) schedule error:\(error)"
                print(localizedDescription)
                Analytics.trackAppSentLocalPushNotification(success: false, localizedDescription: localizedDescription)
                Analytics.trackError(type: nil, domain: "Craze", code: 102, localizedDescription: localizedDescription)
            } else {
                Analytics.trackAppSentLocalPushNotification(success: true, localizedDescription: nil)
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
                case LocalNotificationIdentifier.saleScreenshot.rawValue:
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

        let identifier = LocalNotificationIdentifier.tappedProduct.rawValue
        DataModel.sharedInstance.performBackgroundTask({ (context) in

            if let product = DataModel.sharedInstance.retrieveLatestTapped(in: context), let imageURLString = product.imageURL, let productTitle = product.productTitle(), let offer = product.offer {
                product.inNotif = true
                context.saveIfNeeded()
                let message = "notification.tapped.product.message".localized(withFormat: productTitle)
                NetworkingPromise.sharedInstance.downloadTmp(from: imageURLString, identifier: identifier).then(execute: { (copiedTmpURL) -> Void in
                    let displayFromNow = TimeInterval.oneDay
                    self.scheduleImageLocalNotification(copiedTmpURL: copiedTmpURL,
                                                        userInfo: [Constants.openingProductKey : imageURLString],
                                                        identifier: identifier,
                                                        body: message,
                                                        interval: TimeInterval.oneDay)
                    DataModel.sharedInstance.performBackgroundTask({ (context) in
                        let date = Date.init(timeIntervalSinceNow:displayFromNow)
                        let expire = Date.init(timeIntervalSinceNow:displayFromNow + 7 * .oneDay)
                        
                        InboxMessage.createUpdateWith(lookupDict: nil, actionType: "link", actionValue: offer, buttonText: "Buy Now", image: imageURLString, title: message, uuid: UUID().uuidString, expireDate: expire, date: date, showAfterDate: date, tracking: nil, create: true, update: false, context: context)
                        context.saveIfNeeded()
                    })
                })
            }
        })
    }

    func postSaleScreenshot() {
        guard PermissionsManager.shared.hasPermission(for: .push) else {
            print("postSaleScreenshot no push permission")
            return
        }
        let identifier = LocalNotificationIdentifier.saleScreenshot.rawValue
        DataModel.sharedInstance.performBackgroundTask({ (context) in
            
            if let screenshot = DataModel.sharedInstance.retrieveSaleScreenshot(in:context), let assetIdString = screenshot.assetId, let imageData = screenshot.imageData {
                let message = "notification.sale.screenshot.message".localized
                NetworkingPromise.sharedInstance.saveToTmp(data: imageData, identifier: identifier, originalExtension: "").then(execute: { (copiedTmpURL) -> Void in
                    let displayFromNow = 2 * TimeInterval.oneDay
                    self.scheduleImageLocalNotification(copiedTmpURL: copiedTmpURL,
                                                        userInfo: [Constants.openingScreenKey  : Constants.openingScreenValueScreenshot,
                                                                   Constants.openingAssetIdKey : assetIdString],
                                                        identifier: identifier,
                                                        body: message,
                                                        interval: displayFromNow)
                    let urlString = screenshot.uploadedImageURL ?? copiedTmpURL.absoluteString
                    if let image =  UIImage.init(data: imageData), let url = URL.init(string: urlString) {
                        SDWebImageManager.shared().saveImage(toCache:image, for:url)
                    }

                    DataModel.sharedInstance.performBackgroundTask({ (context) in
                        let date = Date.init(timeIntervalSinceNow:displayFromNow)
                        let expire = Date.init(timeIntervalSinceNow:displayFromNow + 7 * .oneDay)

                        InboxMessage.createUpdateWith(lookupDict: nil, actionType: "screenshot", actionValue: assetIdString, buttonText: "View Items", image: urlString, title: message, uuid: UUID().uuidString, expireDate:expire, date: date, showAfterDate: date, tracking: nil, create: true, update: false, context: context)
                        context.saveIfNeeded()
                    })
                })
            }
            
        })
    }
    
    func category(product: Product) -> String {
        if let shoppable = product.shoppable,
          let category = shoppable.label?.normalizedStyeCategory() ?? shoppable.parentShoppable?.label?.normalizedStyeCategory() {
            return category
        }
        return product.label?.normalizedStyeCategory() ?? product.categories?.normalizedStyeCategory() ?? "fav"
    }
    
    func postLatestFavorite() {
        guard PermissionsManager.shared.hasPermission(for: .push) else {
            print("postLatestFavorite no push permission")
            return
        }
        let identifier = LocalNotificationIdentifier.favoritedItem.rawValue
        DataModel.sharedInstance.performBackgroundTask({ (context) in
            if let latest = DataModel.sharedInstance.retrieveLatestFavorite(in: context), let imageURLString = latest.imageURL, let productId = latest.id {
                let category = self.category(product: latest)
                latest.inNotif = true
                context.saveIfNeeded()

                let message = "notification.favorited.item.message".localized(withFormat: category)
                
                    NetworkingPromise.sharedInstance.downloadTmp(from: imageURLString, identifier: identifier).then(execute: { (copiedTmpURL) -> Void in
                        let displayFromNow = 3 * TimeInterval.oneDay

                        self.scheduleImageLocalNotification(copiedTmpURL: copiedTmpURL,
                                                            userInfo: [Constants.openingProductKey : imageURLString],
                                                            identifier: identifier,
                                                            body: message,
                                                            interval: displayFromNow)
                        DataModel.sharedInstance.performBackgroundTask({ (context) in
                            let date = Date.init(timeIntervalSinceNow:displayFromNow)
                            let expire = Date.init(timeIntervalSinceNow:displayFromNow + 7 * .oneDay)

                            InboxMessage.createUpdateWith(lookupDict: nil, actionType: "product", actionValue: productId, buttonText: "Show me!", image: imageURLString, title: message, uuid: UUID().uuidString, expireDate: expire, date: date, showAfterDate: date, tracking: nil, create: true, update: false, context: context)
                            context.saveIfNeeded()
                        })
                    })
            }
            
        })
    }
    
    func scheduleInactivityDiscoverLocalNotification() {
        guard PermissionsManager.shared.hasPermission(for: .push) else {
            return
        }
        
        self.scheduleImageLocalNotification(copiedTmpURL: nil,
                                            userInfo: [Constants.openingScreenKey : Constants.openingScreenValueDiscover],
                                            identifier: LocalNotificationIdentifier.inactivityDiscover.rawValue,
                                            body: "notification.inactivity.discover.message".localized,
                                            interval: 4 * TimeInterval.oneDay)
    }
    
    func cancelPendingNotifications(within: Date? = nil) {
        DataModel.sharedInstance.performBackgroundTask { (context) in
            InboxMessage.deletePendingMessage(in:context)
            context.saveIfNeeded()
        }
        UNUserNotificationCenter.current().getPendingNotificationRequests { notificationRequestArray in
            var toCancel = [LocalNotificationIdentifier.tappedProduct.rawValue, LocalNotificationIdentifier.saleScreenshot.rawValue, LocalNotificationIdentifier.favoritedItem.rawValue, LocalNotificationIdentifier.inactivityDiscover.rawValue]
            let toCancelPotentialSet = Set<String>(toCancel)
            toCancel.removeAll()
            notificationRequestArray.forEach { notificationRequest in
                var isInCancelDateRange = true
                if let within = within,
                  let trigger = notificationRequest.trigger as? UNCalendarNotificationTrigger,
                  let triggerDate = trigger.nextTriggerDate(),
                  triggerDate > within {
                    isInCancelDateRange = false
                }
                if isInCancelDateRange && toCancelPotentialSet.contains(notificationRequest.identifier) {
                    switch notificationRequest.identifier {
                    case LocalNotificationIdentifier.tappedProduct.rawValue:
                        Analytics.trackTimedLocalNotificationCancelled(source: .tappedProduct)
                        self.cancelProductInNotif(productKey: notificationRequest.content.userInfo[Constants.openingProductKey] as? String)
                    case LocalNotificationIdentifier.saleScreenshot.rawValue:
                        Analytics.trackTimedLocalNotificationCancelled(source: .saleCount)
                        self.cancelScreenshotInNotif(assetId: notificationRequest.content.userInfo[Constants.openingAssetIdKey] as? String)
                    case LocalNotificationIdentifier.favoritedItem.rawValue:
                        Analytics.trackTimedLocalNotificationCancelled(source: .favoritedItem)
                        self.cancelProductInNotif(productKey: notificationRequest.content.userInfo[Constants.openingProductKey] as? String)
                    case LocalNotificationIdentifier.inactivityDiscover.rawValue:
                        Analytics.trackTimedLocalNotificationCancelled(source: .inactivityDiscover)
                    default:
                        print("Cancel unknown timedLocalNotification. WTF?")
                    }
                    print("Canceling notification \(notificationRequest.identifier)")
                    toCancel.append(notificationRequest.identifier)
                }
            }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: toCancel)
        }
    }
    
    func cancelProductInNotif(productKey: String?) {
        guard let productKey = productKey else {
            return
        }
        DataModel.sharedInstance.markProductNotInNotif(imageURL: productKey)
    }
    
    func cancelScreenshotInNotif(assetId: String?) {
        guard let assetId = assetId else {
            return
        }
        DataModel.sharedInstance.markScreenshotNotInNotif(assetId: assetId)
    }
    
    // MARK: Remote Notification

    func registerCrazeFavoritedPriceAlert(id: String?, merchant: String?, lastPrice: Float) {
        guard let id = id else {
            print("registerCrazeFavoritedPriceAlert no product id")
            return
        }
        guard let firebaseId = UserAccountManager.shared.user?.uid else {
            print("registerCrazeFavoritedPriceAlert no firebase id")
            return
        }
        guard let merchant = merchant else {
            print("registerCrazeFavoritedPriceAlert no merchant")
            return
        }
        NetworkingPromise.sharedInstance.registerCrazePriceAlert(id: id, merchant: merchant, lastPrice: lastPrice, firebaseId: firebaseId, action: "favorited")
            .catch { error in
                if let err = error as? PMKURLError {
                    switch err {
                    case let .badResponse(request, data, response):
                        var errorString: String = "-"
                        var dataCount: Int = 0
                        if let data = data {
                            errorString = String(data: data, encoding: .utf8) ?? "-"
                            dataCount = data.count
                        }
                        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                        print("registerCrazeFavoritedPriceAlert specific catch badResponse data count:\(dataCount)  statusCode:\(statusCode)  errorString:\(errorString)  request:\(request)")
                        return
                    default:
                        break
                    }
                }
                print("registerCrazeFavoritedPriceAlert caught error:\(error)")
        }
    }
    
    func deregisterCrazeFavoritedPriceAlert(id: String?, merchant: String?) {
        guard let id = id else {
            print("deregisterCrazeFavoritedPriceAlert no product id")
            return
        }
        guard let merchant = merchant else {
            print("deregisterCrazeFavoritedPriceAlert no merchant")
            return
        }
        guard let firebaseId = UserAccountManager.shared.user?.uid else {
            print("deregisterCrazeFavoritedPriceAlert no firebase id")
            return
        }
        NetworkingPromise.sharedInstance.registerCrazePriceAlert(id: id, merchant: merchant, lastPrice: 0, firebaseId: firebaseId, action: "disabled")
            .catch { error in
                if let err = error as? PMKURLError {
                    switch err {
                    case let .badResponse(request, data, response):
                        var errorString: String = "-"
                        var dataCount: Int = 0
                        if let data = data {
                            errorString = String(data: data, encoding: .utf8) ?? "-"
                            dataCount = data.count
                        }
                        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                        print("deregisterCrazeFavoritedPriceAlert specific catch badResponse data count:\(dataCount)  statusCode:\(statusCode)  errorString:\(errorString)  request:\(request)")
                        return
                    default:
                        break
                    }
                }
                print("deregisterCrazeFavoritedPriceAlert caught error:\(error)")
        }
    }

    func registerCrazeTappedPriceAlert(id: String?, merchant: String?, lastPrice: Float) {
        guard let id = id else {
            print("registerCrazeTappedPriceAlert no product id")
            return
        }
        guard let firebaseId = UserAccountManager.shared.user?.uid else {
            print("registerCrazeTappedPriceAlert no firebase id")
            return
        }
        guard let merchant = merchant else {
            print("registerCrazeTappedPriceAlert no merchant")
            return
        }
        NetworkingPromise.sharedInstance.registerCrazePriceAlert(id: id, merchant: merchant, lastPrice: lastPrice, firebaseId: firebaseId, action: "tapped")
            .catch { error in
                if let err = error as? PMKURLError {
                    switch err {
                    case let .badResponse(request, data, response):
                        var errorString: String = "-"
                        var dataCount: Int = 0
                        if let data = data {
                            errorString = String(data: data, encoding: .utf8) ?? "-"
                            dataCount = data.count
                        }
                        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                        print("registerCrazeTappedPriceAlert specific catch badResponse data count:\(dataCount)  statusCode:\(statusCode)  errorString:\(errorString)  request:\(request)")
                        return
                    default:
                        break
                    }
                }
                print("registerCrazeTappedPriceAlert caught error:\(error)")
        }
    }
    
}
