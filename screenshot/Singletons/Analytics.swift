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

extension Bool {
    func toStringLiteral() -> String {
        return self ? "true" : "false"
    }
}
class Analytics {
    static func propertiesFor(_ matchstick:Matchstick) -> [String:Any] {
        var properties:[String:Any] = [:]
        
        
        return properties
    }
    
    static func propertiesFor(_ screenshot:Screenshot) -> [String:Any] {
        var properties:[String:Any] = [:]
        if let uploadedImageURL = screenshot.uploadedImageURL {
            properties["screenshot-imageURL"] = uploadedImageURL
        }
        
        
        return properties
    }
    static func propertiesFor(_ shoppable:Shoppable) -> [String:Any] {
        var properties:[String:Any] = [:]
        
        if let offersURL = shoppable.offersURL {
            properties["shoppable-offerURL"] = offersURL
        }
        if let category = shoppable.label {
            properties["shoppable-category"] = category
        }
        
        
        if let screenshot = shoppable.screenshot {
            propertiesFor(screenshot).forEach { properties[$0] = $1 }
        }
        
        return properties
    }
    static func propertiesFor(_ product:Product) -> [String:Any] {
        var properties:[String:Any] = [:]
        if let brand = product.brand {
            properties["product-brand"] = brand
        }
        if let merchant = product.merchant {
            properties["product-merchant"] = merchant
        }
        properties["product-isSale"] = product.isSale()
        properties["product-isFavorite"] = product.isFavorite
        if let imageURL = product.imageURL {
            properties["product-imageURL"] = imageURL
        }
        if let offerURL = product.offer {
            properties["product-offerURL"] = offerURL
            
        }
        
        let options = ProductsOptionsMask.init(rawValue: Int(product.optionsMask))
        properties["product-filter-size"] = options.size.analyticsStringValue
        properties["product-filter-gender"] = options.gender.analyticsStringValue
        properties["product-filter-category"] = options.category.analyticsStringValue
        
        /*
         price normalized to USD
         */
        if let shoppable = product.shoppable{
            propertiesFor(shoppable).forEach { properties[$0] = $1 }
        }
        
        return properties
    }
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


class IntercomAnalyticsTracker : NSObject, AnalyticsTracker {
    func trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(_ event: String, properties: [AnyHashable : Any]? = nil) {
        IntercomHelper.sharedInstance.record(event: event, properties: properties)
    }
    
    func identify(_ user: AnalyticsUser) {
        IntercomHelper.sharedInstance.register(user: user)
    }
}
class KochavaAnalyticsTracker : NSObject, AnalyticsTracker {
    func trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(_ event: String, properties: [AnyHashable : Any]? = nil) {
        
        if let kEvent = KochavaEvent(eventTypeEnum: .custom) {
            kEvent.nameString = event
            kEvent.customEventNameString = event
            //Do not track properties - there is an bug in ios 10 that will cause freezing.
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
    static let kochava = KochavaAnalyticsTracker()
    static let intercom = IntercomAnalyticsTracker()
    static let branch = BranchAnalyticsTracker()    
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

extension AnalyticsTrackers {
    enum Location: String {
        case favorite = "Favorite"
        case products = "Products"
        case productBar = "ProductBar"
        case productSimilar = "ProductSimilar"
    }
}

extension AnalyticsTracker {
    
    func trackUserAge() {
        let current = AnalyticsUser.current
        
        identify(current)
    }
    
    
    func trackTappedOnProduct(_ product: Product, atLocation location: AnalyticsTrackers.Location) {
        let willShowShoppingCartPage = (product.partNumber != nil )
        let displayAs:String = {
            if willShowShoppingCartPage {
                return "In app Product"
            }else{
                if let urlString = product.offer, let url = URL(string:urlString) {
                    let willOpenWith = OpenWebPage.using(url:url)
                    return willOpenWith.analyticsString()
                }else{
                    return "error"
                }
            }
        }()
        
        switch location {
        case .favorite:
            track(.tappedOnProductFavorites, properties: ["display":displayAs])
        case .products:
            track(.tappedOnProductProducts, properties: ["display":displayAs])
        case .productBar:
            track(.tappedOnProductProductBar, properties: ["display":displayAs])
        case .productSimilar:
            track(.tappedOnProductProductSimilar, properties: ["display":displayAs])
        }
        
        let email = UserDefaults.standard.string(forKey: UserDefaultsKeys.email) ?? ""
        
        if email.lengthOfBytes(using: .utf8) > 0 {
            let uploadedImageURL = product.screenshot?.uploadedImageURL ?? ""
            let merchant = product.merchant ?? ""
            let brand = product.brand ?? ""
            let displayTitle = product.calculatedDisplayTitle ?? ""
            let offer = product.offer ?? ""
            let imageURL = product.imageURL ?? ""
            let price = product.price ?? ""
            let name =  UserDefaults.standard.string(forKey: UserDefaultsKeys.name) ?? ""
            
            let properties = ["screenshot": uploadedImageURL,
                              "merchant": merchant,
                              "brand": brand,
                              "title": displayTitle,
                              "url": offer,
                              "imageUrl": imageURL,
                              "price": price,
                              "email": email,
                              "name": name,
                              "display":displayAs]
            AnalyticsTrackers.standard.track(.productForEmail, properties:properties)
        }
        
        let merchant = product.merchant ?? ""
        let brand = product.brand?.lowercased() ?? ""
        let offer = product.offer ?? ""
        let imageURL = product.imageURL ?? ""
        let screenshot = product.shoppable?.screenshot ?? product.screenshot
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
            "page" : location,
            "display":displayAs
        ])
        
        FBSDKAppEvents.logEvent(FBSDKAppEventNameViewedContent, parameters: [FBSDKAppEventParameterNameContentID : imageURL])

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
