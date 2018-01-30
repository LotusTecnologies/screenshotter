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

public class AnalyticsUser : NSObject {
    static var current: AnalyticsUser? {
        guard let name = UserDefaults.standard.string(forKey: UserDefaultsKeys.name) else {
            return nil
        }
        
        let email = UserDefaults.standard.string(forKey: UserDefaultsKeys.email)
        return AnalyticsUser(name: name, email: email)
    }

    let identifier: String
    let name: String?
    let email: String?
    
    init(name: String?, email: String?) {
        self.name = name
        self.email = (email?.count ?? 0 > 0) ? email : nil
        
        let persistedID = UserDefaults.standard.string(forKey: UserDefaultsKeys.userID)
        identifier = persistedID ?? UUID().uuidString
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

        props["pushEnabled"] = PermissionsManager.shared.hasPermission(for: .push) ? "true" : "false"
        props["dailyStreak"] = "\(UserDefaults.standard.integer(forKey: UserDefaultsKeys.dailyStreak))"
        
        if let token = UserDefaults.standard.object(forKey: UserDefaultsKeys.deviceToken) as? NSData {
            props["pushToken"] = token.description
        }
        
        props["userAge"] = "\(userAge())"
        return props
    }
}

@objc public protocol AnalyticsTracker {
    func track(_ event: String, properties: [AnyHashable : Any]?)
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
    
    public func track(_ event: String, properties: [AnyHashable : Any]? = nil) {
        trackers.values.forEach { $0.track(event, properties: properties) }
    }
    
    public func identify(_ user: AnalyticsUser) {
        trackers.values.forEach { $0.identify(user) }
    }
}

class SegmentAnalyticsTracker : NSObject, AnalyticsTracker {
    func track(_ event: String, properties: [AnyHashable : Any]? = nil) {
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
    func track(_ event: String, properties: [AnyHashable : Any]? = nil) {
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
        
        track("User Properties", properties: user.analyticsProperties)
    }
}

class IntercomAnalyticsTracker : NSObject, AnalyticsTracker {
    func track(_ event: String, properties: [AnyHashable : Any]? = nil) {
        IntercomHelper.sharedInstance.record(event: event, properties: properties)
    }
    
    func identify(_ user: AnalyticsUser) {
        IntercomHelper.sharedInstance.register(user: user)
    }
}

class BranchAnalyticsTracker : NSObject, AnalyticsTracker {
    func track(_ event: String, properties: [AnyHashable : Any]? = nil) {
        Branch.getInstance().userCompletedAction(event, withState: properties ?? [:])
    }
    
    func identify(_ user: AnalyticsUser) {
        Branch.getInstance().setIdentity(user.email ?? user.identifier)
        
        if let isEmpty = user.email?.isEmpty, isEmpty == false {
            Branch.getInstance().userCompletedAction("Submitted email")
        }
    }
}

public class AnalyticsTrackers : NSObject {
    static let appsee = AppseeAnalyticsTracker()
    static let segment = SegmentAnalyticsTracker()
    static let intercom = IntercomAnalyticsTracker()
    static let branch = BranchAnalyticsTracker()
    
    static let standard = CompositeAnalyticsTracker(trackers: [segment, appsee, intercom])
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
    func trackUserAge() {
        guard let current = AnalyticsUser.current else {
            return
        }
        
        track("User Age", properties: ["age": userAge()])
        identify(current)
    }
    
    func trackFavorited(_ favorited: Bool, product: Product, onPage page: String) {
        let properties = [
            "screenshot" : product.shoppable?.screenshot?.uploadedImageURL ?? "",
            "merchant": product.merchant ?? "",
            "brand": product.brand ?? "",
            "url": product.offer ?? "",
            "imageUrl": product.imageURL ?? "",
            "price": product.price ?? "0",
            "page": page
        ]
        if favorited {
            track("Product favorited", properties: properties)
        } else {
            track("Product unfavorited", properties: properties)
        }
        
        let value = favorited ? FBSDKAppEventParameterValueYes : FBSDKAppEventParameterValueNo
        FBSDKAppEvents.logEvent(FBSDKAppEventNameAddedToWishlist, parameters: [FBSDKAppEventParameterNameSuccess: value])
    }
    
    func trackTappedOnProduct(_ product: Product, onPage page: String) {
        track("Tapped on product", properties: [
            "merchant": product.merchant ?? "",
            "brand": product.brand ?? "",
            "url": product.offer ?? "",
            "imageUrl": product.imageURL ?? "",
            "sale": product.isSale(),
            "page": page
        ])
        
        FBSDKAppEvents.logEvent(FBSDKAppEventNameViewedContent, parameters: [FBSDKAppEventParameterNameContentID: product.imageURL ?? ""])
        
        guard let brand = product.brand?.lowercased(), marketingBrands.contains(brand) else {
            return
        }
        
        // Need to use properties: [:] to clarify which track function we want to call
        track("Tapped on \(brand) product", properties: [:])
    }
}

class AnalyticsTrackerObjCBridge : NSObject {
    static func trackFavoritedProduct(tracker: AnalyticsTracker, favorited: Bool, product: Product, onPage page: String) {
        tracker.trackFavorited(favorited, product: product, onPage: page)
    }
    
    static func trackTappedOnProduct(tracker: AnalyticsTracker, product: Product, onPage page: String) {
        tracker.trackTappedOnProduct(product, onPage: page)
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
