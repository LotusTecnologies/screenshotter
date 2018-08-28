//
//  Analytics.swift
//  screenshot
//
//  Created by Jacob Relkin on 9/26/17.
//  Copyright (c) 2017 crazeapp. All rights reserved.
//

import Foundation
import Analytics
import Appsee
import Branch
import FBSDKCoreKit
import Whisper
import AdSupport
import Amplitude_iOS
import SwiftLog


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
   
    
    static func propertiesForAllEvents() -> [String:Any] {
        var properties:[String:Any] = [:]
        
        let dateInstalled = (UserDefaults.standard.object(forKey:  UserDefaultsKeys.dateInstalled) as? Date ) ?? Date()
        let timeSinceInstall:Double = abs(dateInstalled.timeIntervalSinceNow)
        let daysSinceInstall = Int(round(timeSinceInstall / TimeInterval.oneDay))
        
        properties["user-age"] = daysSinceInstall
        
        properties["user-sessionCount"] = UserDefaults.standard.integer(forKey: UserDefaultsKeys.sessionCount)
        
        return properties
    }
    
    static func propertiesFor(_ matchstick:Matchstick) -> [String:Any] {
        var properties:[String:Any] = [:]
        
        if let uploadedImageURL = matchstick.imageUrl {
            properties["screenshot-imageURL"] = uploadedImageURL
        }
        
        if let remoteId = matchstick.remoteId {
            properties["screenshot-id"] = remoteId
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
        
        self.addScreenshotProperitesFrom(trackingData: screenshot.trackingInfo, toProperties: &properties)
        
        return properties
    }
    
    static func propertiesFor(_ user:AnalyticsUser) -> [String:Any] {
        return user.analyticsProperties
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
    
    static func trackTappedOnProduct(_ product: Product, atLocation location: Analytics.AnalyticsProductOpenedFromPage) {
        let displayAs:Analytics.AnalyticsProductOpenedDisplayAs = {
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
        
        let prop = properties.mapValues { (a) -> Any in
            if let a = a as? String {
                return a
            }else if let a = a as? NSNumber {
                return a
            }else if let  a = a as? Date {
                return String.init(describing: a)
            }else{
                return String.init(describing: a)
            }
        }        
        var propertiesString = ""
        if JSONSerialization.isValidJSONObject(prop), let jsonData = try? JSONSerialization.data(withJSONObject: prop, options: []), let string = String.init(data: jsonData, encoding: .utf8) {
            propertiesString = string
        }else{
            propertiesString = String.init(describing: prop)
        }
        
        
        
        func tryToLog(_ string:String) throws{
            logw(string)
        }
        
        do{
            if eventName == "Log", let line = properties["line"] as? Int, let file = properties["file"] as? NSString, let message =  properties["message"] as? String {
                try tryToLog("[\(eventName) - \(message)] - \( file.lastPathComponent ):\( line )")
            }else{
                try tryToLog("[\(eventName)] - \( propertiesString )")
            }
        }catch  {
        }
        
    
        
    }
    init() {
        Log.logger.printToConsole = false
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
    
    var randomSeed: UInt64{
        if let uuid = UUID.init(uuidString: identifier ){
            return uuid.toRandomSeed()
        }
        return 0
    }
    
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
        
        if let firebaseId = UserAccountManager.shared.user?.uid {
            props["firebaseId"] = firebaseId
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
    let amplitude = AmplitudeAnalyticsTracker()
    let recombee = RecombeeAnalyticsTracker()
    
    class RecombeeAnalyticsTracker : NSObject {
        enum RecombeeEvent:String {
            case addBookmark
            case positiveRating
            case negativeRating
            case detailView    // burrow
            case addToCart     // went to safari
            
            func path() -> String{
                switch self {
                case .addBookmark:
                    return "bookmarks/"
                case .positiveRating, .negativeRating:
                    return "ratings/"
                case .detailView:
                    return "detailviews/"
                case .addToCart:
                    return "cartadditions/"
                }
            }
            func postData(itemId:String) -> [String:Any]? {
                var toReturn:[String:Any] = [:]
                toReturn["userId"] = AnalyticsUser.current.identifier
                toReturn["itemId"] = itemId
                toReturn["cascadeCreate"] = true
                switch self {
                case .addBookmark:
                    break;
                case .positiveRating:
                    toReturn["rating"] = NSNumber.init(value: 0.5)
                case .negativeRating:
                    toReturn["rating"] = NSNumber.init(value: -0.5)
                case .detailView:
                    break;
                case .addToCart:
                    break;
                }
                return toReturn
            }
        }
        
        func track(event:RecombeeEvent, itemId:String){
        let _ = NetworkingPromise.sharedInstance.recombeeRequest(path: event.path(), method: "POST", params: event.postData(itemId: itemId))
        }
       
    }

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
                DispatchQueue.mainAsyncIfNeeded {
                    var outOfSession = (UIApplication.shared.applicationState == .background)
                    if event == "sessionStarted" || event == "sessionEnded" {
                        outOfSession = false
                    }
                    Amplitude.instance().logEvent(event, withEventProperties: properties, outOfSession: outOfSession)
                }
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

