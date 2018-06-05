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
import Whisper
import AdSupport
import Pushwoosh
import Amplitude_iOS

extension Bool {
    func toStringLiteral() -> String {
        return self ? "true" : "false"
    }
}

class Analytics {
    
    static private func addScreenshotProperitesFrom(trackingData:String?, toProperties:inout [String:Any]) {
        do {
            if let string = trackingData, let data = string.data(using: .utf8) {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                    json.forEach { (arg) in
                        let (key, value) = arg
                        if let key = key as? String {
                            toProperties["screenshot-\(key)"] = value
                        }
                    }
                }
            }
        }catch {
            
        }
    }
    
    static func uscExperience() -> String {
//        let uscExperience: String
//        if UserDefaults.standard.object(forKey: UserDefaultsKeys.isUSC) == nil {
//            uscExperience = "unset"
//        } else if UserDefaults.standard.bool(forKey: UserDefaultsKeys.isUSC) {
//            uscExperience = "full-usc"
//        } else if UserDefaults.standard.bool(forKey: UserDefaultsKeys.abUSC) {
//            uscExperience = "usc-feed-external-ui"
//        } else {
//            uscExperience = "non-usc"
//        }
//        return uscExperience
        // Revert to never use USC.
        return "non-usc"
    }
    
    static func propertiesFor(_ matchstick:Matchstick) -> [String:Any] {
        var properties:[String:Any] = [:]
        
        if let uploadedImageURL = matchstick.imageUrl {
            properties["screenshot-imageURL"] = uploadedImageURL
        }
        
        self.addScreenshotProperitesFrom(trackingData: matchstick.trackingInfo, toProperties: &properties)
        
        return properties
    }
    
    static func propertiesFor(_ screenshot:Screenshot) -> [String:Any] {
        var properties:[String:Any] = [:]
        if let uploadedImageURL = screenshot.uploadedImageURL {
            properties["screenshot-imageURL"] = uploadedImageURL
        }
        
        properties["screenshot-source"] = screenshot.source.rawValue
        
        if let screenshotId = screenshot.screenshotId {
            properties["screenshot-id"] = screenshotId
        }
        
        if let submittedDate = screenshot.submittedDate {
            properties["screenshot-submittedToDiscoverDate"] = submittedDate
        }
        
        properties["usc-experience"] = uscExperience()

        self.addScreenshotProperitesFrom(trackingData: screenshot.trackingInfo, toProperties: &properties)
        
        return properties
    }
    
    static func propertiesFor(_ user:AnalyticsUser) -> [String:Any] {
        return user.analyticsProperties
    }
    
    static func propertiesFor(_ cart:Cart) -> [String:Any] {
        var properties:[String:Any] = [:]

        properties["cart-uniqueItems"] = cart.items?.count ?? 0
        
        var totalItemCount = 0
        if let items = cart.items {
            items.forEach { (cartItem) in
                if let c = cartItem as? CartItem {
                    totalItemCount += Int(c.quantity)
                }
            }
        }
        
        properties["cart-items"] = totalItemCount

        properties["cart-shippingTotal"] = cart.shippingTotal
        properties["cart-subtotal"] = cart.subtotal
        properties["cart-taxEstimated"] = cart.estimatedTax
        properties["cart-orderTotal"] = cart.estimatedTotalOrder
        
        properties["cart-remoteId"] = cart.remoteId
        
        if let dateModified = cart.dateModified {
            properties["cart-dateModified"] = dateModified
        }
        if let dateSubmitted = cart.dateSubmitted {
            properties["cart-dateSubmitted"] = dateSubmitted
        }
        properties["cart-isPastOrder"] = cart.isPastOrder
        if let orderNumber = cart.orderNumber {
            properties["cart-orderNumber"] = orderNumber
        }
        
        properties["usc-experience"] = uscExperience()

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
        if let parent = shoppable.parentShoppable {
            if let offer = parent.offersURL {
                properties["shoppable-parentOfferUrl"] = offer
            }
            properties["shoppable-isBurrow"] = true

            properties["shoppable-burrowsCount"] =  parent.subShoppables?.count ?? 0
        }else{
            properties["shoppable-isBurrow"] = false
            let otherBurrows =  shoppable.subShoppables?.count ?? 0
            properties["shoppable-burrowsCount"] = otherBurrows
        }

       

        
        if let screenshot = shoppable.screenshot {
            propertiesFor(screenshot).forEach { properties[$0] = $1 }
        }
        
        return properties
    }
    static func propertiesFor(_ product:Product) -> [String:Any] {
        var properties:[String:Any] = [:]
        if let title = product.productTitle() {
            properties["product-title"] = title
        }
        if let brand = product.brand {
            
            properties["product-brand"] = brand
        }
        if let merchant = product.merchant {
            properties["product-merchant"] = merchant
        }
        if let brandOrMerchant = product.calculatedDisplayTitle {
            properties["product-brandOrMerchant"] = brandOrMerchant
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
        
        if let priceString = product.price {
            properties["product-price-display"] = priceString
        }
        
        if let partNumber = product.partNumber {
            properties["product-partNumber"] = partNumber
            properties["proudct-isUsc"] = NSNumber.init(value: true)
        }else{
            properties["proudct-isUsc"] = NSNumber.init(value: false)
        }

        if let shoppable = product.shoppable{
            propertiesFor(shoppable).forEach { properties[$0] = $1 }
        }else if let screenshot = product.screenshot {
            propertiesFor(screenshot).forEach { properties[$0] = $1 }
        }
        
        return properties
    }
    static func propertiesFor(_ cartItem:CartItem) -> [String:Any] {
        var properties:[String:Any] = [:]

        if let product = cartItem.product{
            propertiesFor(product).forEach { properties[$0] = $1 }
        }
        if let cart = cartItem.cart{
            propertiesFor(cart).forEach { properties[$0] = $1 }
        }
        
        properties["product-quantity"] = NSNumber(value:cartItem.quantity)
        if let color = cartItem.color {
            properties["product-color"] = color
        }
        if let size = cartItem.size {
            properties["product-size"] = size
        }
        
        properties["product-price"] = NSNumber(value:cartItem.price)
        if let sku = cartItem.sku {
            properties["product-sku"] = sku
        }
        
        

        return properties

    }

    
    static func trackTappedOnProduct(_ product: Product, atLocation location: Analytics.AnalyticsProductOpenedFromPage) {
        let willShowShoppingCartPage = product.isSupportingUSC
        let displayAs:Analytics.AnalyticsProductOpenedDisplayAs = {
            if willShowShoppingCartPage {
                return .productPage
            }else{
                if let urlString = product.offer, let url = URL(string:urlString) {
                    let willOpenWith = OpenWebPage.using(url:url)
                    if let a = Analytics.AnalyticsProductOpenedDisplayAs.init(rawValue: willOpenWith.analyticsString()){
                        return a
                    }else{
                        return .error
                    }
                }else{
                    return .error
                }
            }
        }()
        
        Analytics.trackProductOpened(product: product, order: nil, sort: nil, displayAs: displayAs, fromPage: location)
        
        if let email = UserDefaults.standard.string(forKey: UserDefaultsKeys.email), email.lengthOfBytes(using: .utf8) > 0 {
            Analytics.trackProductForEmail(product: product, email: email)
        }
        if let brand = product.brand, let brandEnum = Analytics.AnalyticsTappedOnProductByBrandBrand.init(rawValue: brand) {
            Analytics.trackTappedOnProductByBrand(product: product, brand: brandEnum)
        }
    }
    static func debugShowLoggedAnalytics(eventName: String, properties: [AnyHashable:Any], destinations:[String]){
        if UserDefaults.standard.bool(forKey: UserDefaultsKeys.showsDebugAnalyticsUI) {
            DispatchQueue.main.async {
                if let viewController = AppDelegate.shared.window?.rootViewController {
                    let announcement = Announcement(title: eventName, subtitle: destinations.joined(separator: ", "), image: nil, duration:10.0, action:{
                        //notification was tapped
                        let alert = UIAlertController.init(title: eventName, message: String(describing: properties), preferredStyle: .alert)
                        
                        alert.addAction(UIAlertAction.init(title: "OK", style: .cancel, handler: nil))
                        viewController.present(alert, animated: true, completion: nil)
                        
                    })
                    Whisper.show(shout: announcement, to: viewController, completion: {
                        print("The shout was silent.")
                    })
                }
            }
        }
        
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
            props["pushTokenString"] = UIDevice.current.pushString(data: token as Data)
        }
        
        let userAge:Int = {
            guard let dateInstalled = UserDefaults.standard.object(forKey: UserDefaultsKeys.dateInstalled) as? Date else {
                return 0
            }
            let components = Set<Calendar.Component>([.day])
            guard let ageInDays = Calendar.current.dateComponents(components, from: dateInstalled, to: Date()).day else {
                return 0
            }
            return ageInDays
        }()
        props["userAge"] = "\(userAge)"
        if InAppPurchaseManager.sharedInstance.didPurchase(_inAppPurchaseProduct: .personalStylist) {
            props["personalStylistPurchased"] = "true"
        }
        
        

        return props
    }
    
    func  sendToServers(){
        AnalyticsTrackers.autoGeneratedCodeApi.amplitude.identify(self)
        AnalyticsTrackers.autoGeneratedCodeApi.branch.identify(self)
        AnalyticsTrackers.autoGeneratedCodeApi.appsee.identify(self)
    }
}

protocol AnalyticsTracker {
    func track(_ event: String, properties: [AnyHashable : Any]?, sendEvenIfAdvertisingTrackingIsOptOut:Bool?)
    func identify(_ user: AnalyticsUser)
}

class AnalyticsTrackers : NSObject {
    static let autoGeneratedCodeApi = AnalyticsTrackers()

    let appsee = AppseeAnalyticsTracker()
    let kochava = KochavaAnalyticsTracker()
    let branch = BranchAnalyticsTracker()
    let pushwoosh = PushwooshAnalyticsTracker()
    let amplitude = AmplitudeAnalyticsTracker()

    
    class AppseeAnalyticsTracker : NSObject, AnalyticsTracker {
        func track(_ event: String, properties: [AnyHashable : Any]? = nil, sendEvenIfAdvertisingTrackingIsOptOut:Bool? = false ){
            if  ASIdentifierManager.shared().isAdvertisingTrackingEnabled || sendEvenIfAdvertisingTrackingIsOptOut == true {
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
        }
        
        func identify(_ user: AnalyticsUser) {
            guard ASIdentifierManager.shared().isAdvertisingTrackingEnabled else {
                return
            }
            Appsee.setUserID(user.email ?? user.identifier)
            Appsee.addEvent("User Properties", withProperties: user.analyticsProperties)
        }
    }
    
    class BranchAnalyticsTracker : NSObject, AnalyticsTracker {
        func track(_ event: String, properties: [AnyHashable : Any]? = nil, sendEvenIfAdvertisingTrackingIsOptOut:Bool? = false ){
            // Branch checks isAdvertisingTrackingEnabled in setup in AppDelegate.
            Branch.getInstance().userCompletedAction(event, withState: properties ?? [:])
        }
        
        func identify(_ user: AnalyticsUser) {
            // Branch checks isAdvertisingTrackingEnabled in setup in AppDelegate.
            Branch.getInstance().setIdentity(user.email ?? user.identifier)
            
            if let isEmpty = user.email?.isEmpty, isEmpty == false {
                Branch.getInstance().userCompletedAction("Submitted email")
            }
        }
    }
    
    
    class AmplitudeAnalyticsTracker : NSObject, AnalyticsTracker {
        func track(_ event: String, properties: [AnyHashable : Any]?, sendEvenIfAdvertisingTrackingIsOptOut: Bool?) {
            if  ASIdentifierManager.shared().isAdvertisingTrackingEnabled || sendEvenIfAdvertisingTrackingIsOptOut == true {
                Amplitude.instance().logEvent(event, withEventProperties: properties)
            }
        }
        
        func identify(_ user: AnalyticsUser) {
            guard ASIdentifierManager.shared().isAdvertisingTrackingEnabled else {
                return
            }
            Amplitude.instance().setUserId(user.identifier)
            Amplitude.instance().setUserProperties(user.analyticsProperties)
        }
    }
    
    class PushwooshAnalyticsTracker : NSObject, AnalyticsTracker {
        func track(_ event: String, properties: [AnyHashable : Any]? = nil, sendEvenIfAdvertisingTrackingIsOptOut:Bool? = false ){

            if  ASIdentifierManager.shared().isAdvertisingTrackingEnabled || sendEvenIfAdvertisingTrackingIsOptOut == true {
                PWInAppManager.shared().postEvent(event)
            }
        }
        
        func identify(_ user: AnalyticsUser) {
            guard ASIdentifierManager.shared().isAdvertisingTrackingEnabled else {
                return
            }
            
            PWInAppManager.shared().setUserId(user.identifier)

        }
    }
    
    class KochavaAnalyticsTracker : NSObject, AnalyticsTracker {
        func track(_ event: String, properties: [AnyHashable : Any]? = nil, sendEvenIfAdvertisingTrackingIsOptOut:Bool? = false ){
            DispatchQueue.mainAsyncIfNeeded {
                if  ASIdentifierManager.shared().isAdvertisingTrackingEnabled || sendEvenIfAdvertisingTrackingIsOptOut == true {
                    if let kEvent = KochavaEvent(eventTypeEnum: .custom) {
                        kEvent.nameString = event
                        kEvent.customEventNameString = event
                        //Do not track properties - there is an bug in ios 10 that will cause freezing.
                        kEvent.userIdString = AnalyticsUser.current.identifier
                        kEvent.userNameString = AnalyticsUser.current.name
                        KochavaTracker.shared.send(kEvent)
                        
                    }
                }
            }
        }
        
        func identify(_ user: AnalyticsUser) {
            guard ASIdentifierManager.shared().isAdvertisingTrackingEnabled else {
                return
            }
        }
    }
}

