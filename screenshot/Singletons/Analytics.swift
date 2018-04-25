//
//  Analytics.swift
//  screenshot
//
//  Created by Jacob Relkin on 9/26/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation
import Analytics
import Appsee
import Branch
import FBSDKCoreKit

public enum AnalyticsEvent : String {
    case acceptedPushPermissions = "Accepted Push Permissions"
    case apnDisabled = "APN Disabled"
    case apnEnabled = "APN Enabled"
    case appOpenedFromLocalNotification = "app opened from local notification"
    case appSentLocalPushNotification = "app sent local push notification"
    case automaticallyExitedTutorialVideo = "Automatically Exited Tutorial Video"
    case bypassedClarifai = "bypassed Clarifai"
    case bypassedClarifaiOnRetry = "bypassed Clarifai on retry"
    case canceledPhotoCreation = "Canceled Photo Creation"
    case completedTutorialVideo = "Completed Tutorial Video"
    case continuedTutorialVideo = "Continued Tutorial Video"
    case createdPhoto = "Created Photo"
    case dailyStreak = "Daily Streak"
    case deniedPushPermissions = "Denied Push Permissions"
    case errImgHang = "err img hang"
    case error = "Error"
    case finishedDownloadingClarifaiModel = "finished downloading Clarifai model"
    case finishedTutorial = "Finished Tutorial"
    case gameCollision = "Game Collision"
    case gameInterrupted = "Game Interrupted"
    case gameOpened = "Game Opened"
    case gameRestarted = "Game Restarted"
    case gameResumed = "Game Resumed"
    case gameScoreIncreased = "Game Score Increased"
    case gameStarted = "Game Started"
    case ignoredRatingInApp = "Ignored rating in app"
    case ignoredRatingOnAppstore = "Ignored rating on AppStore"
    case inAppPurchase = "InAppPurchase"
    case importedPhotos = "Imported Photos"
    case matchsticksAdd = "Matchsticks Add"
    case matchsticksFlagged = "Matchsticks Flagged"
    case matchsticksOpenedScreenshot = "Matchsticks Opened Screenshot"
    case matchsticksSkip = "Matchsticks Skip"
    case openedFiltersView = "Opened Filters View"
    case openedPicker = "Opened Picker"
    case openedWithRemoteNotification = "Opened with remote notification"
    case pausedTutorialVideo = "Paused Tutorial Video"
    case productFavorited = "Product favorited"
    case productForEmail = "Product for email"
    case productUnfavorited = "Product unfavorited"
    case ratedApp = "Rated app"
    case ratedAppOnAppStore = "Rated app on app store"
    case receivedProductsFromSyte = "received products from Syte"
    case receivedRemoteNotification = "Received remote notification"
    case receivedResponseFromClarifai = "received response from Clarifai"
    case receivedResponseFromSyte = "received response from Syte"
    case refreshedWebpage = "Refreshed webpage"
    case removedScreenshot = "Removed screenshot"
    case replayedTutorialVideo = "Replayed Tutorial Video"
    case requestedCustomStylist = "Requested Custom Stylist"
    case screenshotNotificationAccepted = "Screenshot notification accepted"
    case screenshotNotificationCancelled = "Screenshot notification cancelled"
    case screenshotOpenedWithoutShoppables = "Screenshot Opened Without Shoppables"
    case sentImageToClarifai = "sent image to Clarifai"
    case sentImageToSyte = "sent image to Syte"
    case sessionEnded = "sessionEnded"
    case sessionStarted = "sessionStarted"
    case shareCompleted = "Share completed"
    case shareIncomplete = "Share incomplete"
    case sharedScreenshot = "Shared screenshot"
    case shoppableFeedbackNegative = "Shoppable Feedback Negative"
    case shoppableRatingNegative = "Shoppable rating negative"
    case shoppableRatingPositive = "Shoppable rating positive"
    case skippedTutorial = "Skipped Tutorial"
    case startedDownloadingClarifaiModel = "started downloading Clarifai model"
    case startedTutorial = "Started Tutorial"
    case startedTutorialVideo = "Started Tutorial Video"
    case submittedBlankEmail = "Submitted blank email"
    case submittedEmail = "Submitted email"
    case tabBarTapped = "Tab Bar tapped"
    case tappedOnProduct = "Tapped on product"
    case tappedOnProductFavorites = "Tapped on product - Favorites"
    case tappedOnProductProductbar = "Tapped on product - ProductBar"
    case tappedOnProductProducts = "Tapped on product - Products"
    case tappedOnScreenshot = "Tapped on screenshot"
    case tappedOnShoppable = "Tapped on shoppable"
    case tookScreenshot = "Took Screenshot"
    case tookScreenshotWhileShowingIntercomWindow = "Took Screenshot While Showing Intercom Window"
    case userAge = "User Age"
    case userExitedTutorialVideo = "User Exited Tutorial Video"
    case userImportedOldScreenshots = "user imported old screenshots"
    case userImportedScreenshots = "user imported screenshots"
    case userProperties = "User Properties"
    case userReceivedSharedScreenshots = "user received shared screenshots"
    case userRetriedScreenshots = "user retried screenshots"
    case webviewInvalidUrl = "WebView invalid url"
    case wokeFromSilentPush = "Woke From Silent Push"
}


public class AnalyticsUser : NSObject {
    static var current: AnalyticsUser {
        let name = UserDefaults.standard.string(forKey: UserDefaultsKeys.name)
        let email = UserDefaults.standard.string(forKey: UserDefaultsKeys.email)
        return AnalyticsUser(name: name, email: email)
    }

    let identifier: String
    let name: String?
    let email: String?
    
    init(name: String?, email: String?) {
        self.name = name
        self.email = (email?.count ?? 0 > 0) ? email : nil
        
        let persistedID = UserDefaults.standard.string(forKey: UserDefaultsKeys.userID) ?? {
            let id = UUID().uuidString
            UserDefaults.standard.setValue(id, forKey: UserDefaultsKeys.userID)
            return id
        }()
        identifier = persistedID
    }
    
    var analyticsProperties: [String : String] {
        var props = ["identifier" : identifier]
        
        if let email = email {
            props["email"] = email
        }
        
        if let name = name {
            props["name"] = name
        }
        
        if let channel = UserDefaults.standard.string(forKey: UserDefaultsKeys.referralChannel) {
            props["referringChannel"] = channel
        }
        
        if let campaign = UserDefaults.standard.string(forKey: UserDefaultsKeys.campaign) {
            props["campaign"] = campaign
        }
        
        props["pushEnabled"] = PermissionsManager.shared.hasPermission(for: .push) ? "true" : "false"
        props["dailyStreak"] = "\(UserDefaults.standard.integer(forKey: UserDefaultsKeys.dailyStreak))"
        
        if let token = UserDefaults.standard.object(forKey: UserDefaultsKeys.deviceToken) as? NSData {
            props["pushToken"] = token.description
        }
        
        props["userAge"] = "\(userAge())"
        if InAppPurchaseManager.sharedInstance.didPurchase(_inAppPurchaseProduct: .personalStylist) {
            props["personalStylistPurchased"] = "true"
        }
        
        

        return props
    }
}

@objc public protocol AnalyticsTracker {
    func trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(_ event: String, properties: [AnyHashable : Any]?)
    func identify(_ user: AnalyticsUser)
}

public class CompositeAnalyticsTracker : NSObject, AnalyticsTracker {
   
    
    private var trackers: [String : AnalyticsTracker] = [:]
    
    init(trackers ts: [AnalyticsTracker] = []) {
        super.init()
        
        ts.forEach(add)
    }
    
    func add(tracker: AnalyticsTracker) {
        let id = String(describing: type(of:tracker))
        
        guard trackers[id] == nil else {
            return
        }
        
        trackers[id] = tracker
    }
    
    func remove(tracker: AnalyticsTracker) {
        trackers.removeValue(forKey: String(describing: type(of:tracker)))
    }
    
    // MARK: - AnalyticsTracker
    
    public func trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(_ event: String, properties: [AnyHashable : Any]? = nil) {
        trackers.values.forEach { $0.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(event, properties: properties) }
    }
    
    public func identify(_ user: AnalyticsUser) {
        trackers.values.forEach { $0.identify(user) }
    }
}

class SegmentAnalyticsTracker : NSObject, AnalyticsTracker {
    func trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(_ event: String, properties: [AnyHashable : Any]? = nil) {
        SEGAnalytics.shared().track(event, properties: properties as? [String : Any])
    }
    
    func identify(_ user: AnalyticsUser) {
        SEGAnalytics.shared().identify(user.identifier, traits: user.analyticsProperties)
    }
    
    func error(withDescription description: String) {
        SEGAnalytics.shared().track("Error", properties: ["Description" : description])
    }
}

class AppseeAnalyticsTracker : NSObject, AnalyticsTracker {
    func trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(_ event: String, properties: [AnyHashable : Any]? = nil) {
        // Appsee properties can't exceed 300 bytes.
        // https://www.appsee.com/docs/ios/api?section=events
        
        let finalKeys = (properties ?? [:]).keys.filter {
            let propertyLength = "\(event)\($0)\(properties![$0] ?? ""))".lengthOfBytes(using: .utf8)
            return propertyLength < 300
        }
        
        if finalKeys.count > 0 {
            let props = finalKeys.reduce([:]) { (final, key) -> [AnyHashable : Any] in
                var copy = final
                copy[key] = properties?[key]
                return copy
            }
            
            Appsee.addEvent(event, withProperties: props)
            
        } else {
            Appsee.addEvent(event)
        }
    }
    
    func identify(_ user: AnalyticsUser) {
        Appsee.setUserID(user.email ?? user.identifier)
        
        track(.userProperties, properties: user.analyticsProperties)
    }
}

class IntercomAnalyticsTracker : NSObject, AnalyticsTracker {
    func trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(_ event: String, properties: [AnyHashable : Any]? = nil) {
//        IntercomHelper.sharedInstance.record(event: event, properties: properties)
    }
    
    func identify(_ user: AnalyticsUser) {
//        IntercomHelper.sharedInstance.register(user: user)
    }
}

class BranchAnalyticsTracker : NSObject, AnalyticsTracker {
    func trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(_ event: String, properties: [AnyHashable : Any]? = nil) {
        Branch.getInstance().userCompletedAction(event, withState: properties ?? [:])
    }
    
    func identify(_ user: AnalyticsUser) {
        Branch.getInstance().setIdentity(user.email ?? user.identifier)
        
        if let isEmpty = user.email?.isEmpty, isEmpty == false {
            Branch.getInstance().userCompletedAction("Submitted email")
        }
    }
}

class KochavaAnalyticsTracker : NSObject, AnalyticsTracker {
    func trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(_ event: String, properties: [AnyHashable : Any]? = nil) {
        
        if let kEvent = KochavaEvent(eventTypeEnum: .custom) {
            kEvent.nameString = event
            kEvent.payloadDictionary = properties
            kEvent.userIdString = AnalyticsUser.current.identifier
            kEvent.userNameString = AnalyticsUser.current.name
            KochavaTracker.shared.send(kEvent)
            
        }
        SEGAnalytics.shared().track(event, properties: properties as? [String : Any])
    }
    
    func identify(_ user: AnalyticsUser) {
    }
    
    func error(withDescription description: String) {
        
        if let kEvent = KochavaEvent(eventTypeEnum: .custom) {
            kEvent.nameString = "Error"
            kEvent.payloadDictionary = ["description":description]
            kEvent.userIdString = AnalyticsUser.current.identifier
            kEvent.userNameString = AnalyticsUser.current.name
            KochavaTracker.shared.send(kEvent)
            
        }
    }
}

public class AnalyticsTrackers : NSObject {
    static let appsee = AppseeAnalyticsTracker()
    static let segment = SegmentAnalyticsTracker()
    static let intercom = IntercomAnalyticsTracker()
    static let branch = BranchAnalyticsTracker()
    static let kochava = KochavaAnalyticsTracker()

    static let standard = CompositeAnalyticsTracker(trackers: [segment, appsee, intercom, kochava])
}

fileprivate let marketingBrands = [
    "boohoo",
    "missguided",
    "forever 21",
    "asos",
    "free people",
    "urban outfitters",
    "river island",
    "bdg",
    "tommy hilfiger",
    "nbd",
    "yoox.com",
    "revolve",
    "nordstrom"
]

extension AnalyticsTracker {
    public func track(_ event: AnalyticsEvent, properties: [AnyHashable : Any]? = nil) {
        self.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(event.rawValue, properties: properties)
    }
    
    func trackUserAge() {
        let current = AnalyticsUser.current
        
        track( .userAge, properties: ["age": userAge()])
        identify(current)
    }
    
    func trackFavorited(_ favorited: Bool, product: Product, onPage page: String) {
        let uploadedImageURL = product.shoppable?.screenshot?.uploadedImageURL ?? ""
        let merchant = product.merchant ?? ""
        let brand = product.brand ?? ""
        let offer = product.offer ?? ""
        let imageURL = product.imageURL ?? ""
        let price = product.price ?? "0"
        let properties = [
            "screenshot" : uploadedImageURL,
            "merchant": merchant,
            "brand": brand,
            "url": offer,
            "imageUrl": imageURL,
            "price": price,
            "page": page
        ]
        if favorited {
            track(.productFavorited, properties: properties)
        } else {
            track(.productUnfavorited, properties: properties)
        }
        if favorited {
            FBSDKAppEvents.logEvent(FBSDKAppEventNameAddedToWishlist, parameters: [FBSDKAppEventParameterNameSuccess: FBSDKAppEventParameterValueYes])
        } else {
            FBSDKAppEvents.logEvent(FBSDKAppEventNameAddedToWishlist, parameters: [FBSDKAppEventParameterNameSuccess: FBSDKAppEventParameterValueNo])
        }
    }
    
    func trackTappedOnProduct(_ product: Product, onPage page: String) {
        let screenshot = product.shoppable?.screenshot ?? product.screenshot
        let merchant = product.merchant ?? ""
        let brand = product.brand?.lowercased() ?? ""
        let offer = product.offer ?? ""
        let imageURL = product.imageURL ?? ""
        let screenshotURL = screenshot?.uploadedImageURL ?? ""
        let screenshotID = screenshot?.screenshotId ?? ""
        
        let sale = product.isSale()

        track(.tappedOnProduct, properties: [
            "merchant" : merchant,
            "brand" : brand,
            "url" : offer,
            "imageUrl" : imageURL,
            "screenshotURL" : screenshotURL,
            "screenshotID" : screenshotID,
            "sale" : sale,
            "page" : page
        ])
        
        FBSDKAppEvents.logEvent(FBSDKAppEventNameViewedContent, parameters: [FBSDKAppEventParameterNameContentID : imageURL])
        
        // Need to use properties: [:] to clarify which track function we want to call
        if marketingBrands.contains(brand) {
            trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent("Tapped on \(brand) product", properties: [:])
        }
    }
}

// Returns the user's age in days.
fileprivate func userAge() -> Int {
    guard let dateInstalled = UserDefaults.standard.object(forKey: UserDefaultsKeys.dateInstalled) as? Date else {
        return 0
    }
    
    let components = Set<Calendar.Component>([.day])
    guard let ageInDays = Calendar.current.dateComponents(components, from: dateInstalled, to: Date()).day else {
        return 0
    }
    
    return ageInDays
}
