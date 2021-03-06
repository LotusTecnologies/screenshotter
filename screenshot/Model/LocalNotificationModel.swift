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
    case similarLooks           = "CrazeSimilarLooks"
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
        postSimilarLooks()
    }
    
    // MARK: Local Notification

    func getTextAndImageForNotification(assetId: String, imageData: Data?) -> Promise<(String, Data?)>{
        return Promise.init(resolvers: { (fulfil, reject) in
            DataModel.sharedInstance.performBackgroundTask { (context) in
                let screenshot = context.screenshotWith(assetId: assetId)
                let product = screenshot?.firstShoppable?.feturedProduct()
                
                if let product = product, let imageURL = product.imageURL, let url = URL.init(string:imageURL){
                    let contentBody:String = {
                        if let price = product.price, product.floatPrice < 40 {
                            return "notification.message.productWithPrice".localized(withFormat: price)
                        }else{
                            return "notification.message.product".localized
                        }
                    }()
                    SDWebImageManager.shared().loadImage(with: url, options: [], progress: nil, completed: { (image, data, error, cache, bool, url) in
                        let imageData:Data? =  {
                            if let data = data {
                                return data
                            }else if let i = image {
                                return AssetSyncModel.sharedInstance.data(for: i)
                            }
                            return nil
                        }()
                        fulfil((contentBody, imageData))
                    })
                }else{
                    fulfil(("notification.message".localized, imageData))
                }
            }
        })
       
    }
    func sendScreenshotAddedLocalNotification(assetId: String, imageData: Data?, startTimeForDebug:Date) {
        guard PermissionsManager.shared.hasPermission(for: .push) else {
            return
        }
        getTextAndImageForNotification(assetId: assetId, imageData: imageData).then { (args) -> Void in
            Analytics.trackDevLog(file:  NSString.init(string: #file).lastPathComponent, line: #line, message: "extra time for notification \(startTimeForDebug.timeIntervalSinceNow)")

            let (contentBody, imageData) = args
            let content = UNMutableNotificationContent()
            content.title = "notification.title".localized
            content.body = contentBody
            
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
    }

func scheduleImageLocalNotification(copiedTmpURL: URL?, userInfo: [String : Any], identifier: String, body: String, trigger: UNNotificationTrigger) {
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
                case LocalNotificationIdentifier.similarLooks.rawValue:
                    Analytics.trackTimedLocalNotificationScheduled(source: .similarLooks)
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
                    let uuid = UUID().uuidString
                    let inboxDict = [
                        "uuid":uuid,
                    ]
                    self.scheduleImageLocalNotification(copiedTmpURL: copiedTmpURL,
                                                        userInfo: [Constants.openingProductKey : imageURLString, "inbox":inboxDict],
                                                        identifier: identifier,
                                                        body: message,
                                                        trigger: UNTimeIntervalNotificationTrigger(timeInterval: displayFromNow, repeats: false))
                    DataModel.sharedInstance.performBackgroundTask({ (context) in
                        let date = Date.init(timeIntervalSinceNow:displayFromNow)
                        let expire = Date.init(timeIntervalSinceNow:displayFromNow + 7 * .oneDay)
                        
                        InboxMessage.createUpdateWith(lookupDict: nil, actionType: "link", actionValue: offer, buttonText: "Buy Now", image: imageURLString, title: message, uuid: uuid, expireDate: expire, date: date, showAfterDate: date, tracking: nil, create: true, update: false, context: context)
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
        let dataModel = DataModel.sharedInstance
        dataModel.performBackgroundTask { managedObjectContext in
            if let screenshot = dataModel.retrieveSaleScreenshot(in: managedObjectContext),
              let assetIdString = screenshot.assetId,
              let imageData = screenshot.imageData,
              let urlString = screenshot.uploadedImageURL {
                screenshot.inNotif = true
                managedObjectContext.saveIfNeeded()
                let message = "notification.sale.screenshot.message".localized
                NetworkingPromise.sharedInstance.saveToTmp(data: imageData, identifier: identifier, originalExtension: "").then { copiedTmpURL -> Void in
                    let displayFromNow = 2 * TimeInterval.oneDay
                    let uuid = UUID().uuidString
                    let inboxDict = [
                        "uuid":uuid,
                        ]
                    self.scheduleImageLocalNotification(copiedTmpURL: copiedTmpURL,
                                                        userInfo: [Constants.openingScreenKey  : Constants.openingScreenValueScreenshot,
                                                                   Constants.openingAssetIdKey : assetIdString,
                                                                   "inbox":inboxDict],
                                                        identifier: identifier,
                                                        body: message,
                                                        trigger: UNTimeIntervalNotificationTrigger(timeInterval: displayFromNow, repeats: false))
                    if let image =  UIImage.init(data: imageData), let url = URL.init(string: urlString) {
                        SDWebImageManager.shared().saveImage(toCache:image, for:url)
                    }
                    dataModel.performBackgroundTask { context in
                        let date = Date(timeIntervalSinceNow:displayFromNow)
                        let expire = Date(timeIntervalSinceNow:displayFromNow + 7 * .oneDay)

                        InboxMessage.createUpdateWith(lookupDict: nil, actionType: "screenshot", actionValue: assetIdString, buttonText: "View Items", image: urlString, title: message, uuid: uuid, expireDate:expire, date: date, showAfterDate: date, tracking: nil, create: true, update: false, context: context)
                        context.saveIfNeeded()
                    }
                }
            }
        }
    }
    
    func category(product: Product) -> String {
        if let shoppable = product.shoppable,
          let category = shoppable.label?.normalizedSyteCategory() ?? shoppable.parentShoppable?.label?.normalizedSyteCategory() {
            return category
        }
        return product.label?.normalizedSyteCategory() ?? product.categories?.normalizedSyteCategory() ?? "fav"
    }
    
    func postLatestFavorite() {
        guard PermissionsManager.shared.hasPermission(for: .push) else {
            print("postLatestFavorite no push permission")
            return
        }
        let identifier = LocalNotificationIdentifier.favoritedItem.rawValue
        DataModel.sharedInstance.performBackgroundTask { context in
            if let latest = DataModel.sharedInstance.retrieveLatestFavorite(in: context),
              let imageURLString = latest.imageURL,
              let productId = latest.id {
                let category = latest.shoppable?.label ?? latest.shoppable?.parentShoppable?.label ?? latest.categories ?? "fav"
                latest.inNotif = true
                context.saveIfNeeded()
                let message = "notification.favorited.item.message".localized(withFormat: category)
                NetworkingPromise.sharedInstance.downloadTmp(from: imageURLString, identifier: identifier).then { copiedTmpURL -> Void in
                    let displayFromNow = 3 * TimeInterval.oneDay
                    let uuid = UUID().uuidString
                    let inboxDict = [
                        "uuid":uuid,
                    ]
                    self.scheduleImageLocalNotification(copiedTmpURL: copiedTmpURL,
                                                        userInfo: [Constants.openingProductKey : imageURLString, "inbox":inboxDict],
                                                        identifier: identifier,
                                                        body: message,
                                                        trigger: UNTimeIntervalNotificationTrigger(timeInterval: displayFromNow, repeats: false))
                    DataModel.sharedInstance.performBackgroundTask { context in
                        let date = Date(timeIntervalSinceNow:displayFromNow)
                        let expire = Date(timeIntervalSinceNow:displayFromNow + 7 * .oneDay)
                        InboxMessage.createUpdateWith(lookupDict: nil, actionType: "product", actionValue: productId, buttonText: "Show me!", image: imageURLString, title: message, uuid: uuid, expireDate: expire, date: date, showAfterDate: date, tracking: nil, create: true, update: false, context: context)
                        context.saveIfNeeded()
                    }
                }
            }
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
                                            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 4 * TimeInterval.oneDay, repeats: false))
    }
    
    func postSimilarLooks() {
        guard PermissionsManager.shared.hasPermission(for: .push) else {
            print("postSimilarLooks no push permission")
            return
        }
        let identifier = LocalNotificationIdentifier.similarLooks.rawValue
        let dataModel = DataModel.sharedInstance
        dataModel.performBackgroundTask { managedObjectContext in
            if let screenshot = dataModel.retrieveSimilarLook(in: managedObjectContext),
              let assetIdString = screenshot.assetId,
              let imageData = screenshot.imageData,
              let urlString = screenshot.uploadedImageURL, let firstShoppable = screenshot.firstShoppable, let _ = firstShoppable.relatedImagesUrl() {
                screenshot.inNotif = true
                managedObjectContext.saveIfNeeded()
                RelatedLooksManager.loadRelatedLooked(shoppable: firstShoppable).then(execute: { (relatedLooks) -> Void in
                    
                    NetworkingPromise.sharedInstance.saveToTmp(data: imageData, identifier: identifier, originalExtension: "").then { copiedTmpURL -> Void in
                        var threePmSunday = DateComponents()
                        threePmSunday.weekday = 1
                        threePmSunday.hour = 15
                        let displayDateTrigger = UNCalendarNotificationTrigger(dateMatching: threePmSunday, repeats: false)
                        let uuid = UUID().uuidString
                        let inboxDict = [
                            "uuid":uuid,
                        ]
                        self.scheduleImageLocalNotification(copiedTmpURL: copiedTmpURL,
                                                            userInfo: [Constants.openingScreenKey  : Constants.openingScreenValueScreenshot,
                                                                       Constants.openingAssetIdKey : assetIdString, "inbox":inboxDict],
                                                            identifier: identifier,
                                                            body: "notification.similar.looks.message".localized,
                                                            trigger: displayDateTrigger)
                        if let image =  UIImage.init(data: imageData), let url = URL.init(string: urlString) {
                            SDWebImageManager.shared().saveImage(toCache:image, for:url)
                        }
                        if let date = displayDateTrigger.nextTriggerDate() {
                            let expire = Date(timeInterval: 7 * .oneDay, since: date)
                            dataModel.performBackgroundTask { context in
                                InboxMessage.createUpdateWith(lookupDict: nil, actionType: "similarLooks", actionValue: assetIdString, buttonText: "notification.similar.looks.message.button".localized, image: urlString, title: "notification.similar.looks.message.markup".localized, uuid: uuid, expireDate:expire, date: date, showAfterDate: date, tracking: nil, create: true, update: false, context: context)
                                context.saveIfNeeded()
                            }
                        }
                    }
                    
                })
            }
        }
    }
    
    func cancelPendingNotifications(within: Date? = nil) {
        DataModel.sharedInstance.performBackgroundTask { context in
            InboxMessage.deletePendingMessage(in: context)
            context.saveIfNeeded()
        }
        UNUserNotificationCenter.current().getPendingNotificationRequests { notificationRequestArray in
            var toCancel = [LocalNotificationIdentifier.tappedProduct.rawValue, LocalNotificationIdentifier.saleScreenshot.rawValue, LocalNotificationIdentifier.favoritedItem.rawValue, LocalNotificationIdentifier.inactivityDiscover.rawValue, LocalNotificationIdentifier.similarLooks.rawValue]
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
                    case LocalNotificationIdentifier.similarLooks.rawValue:
                        Analytics.trackTimedLocalNotificationCancelled(source: .similarLooks)
                        self.cancelScreenshotInNotif(assetId: notificationRequest.content.userInfo[Constants.openingAssetIdKey] as? String)
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
