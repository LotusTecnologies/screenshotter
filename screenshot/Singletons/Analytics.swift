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

public class AnalyticsUser : NSObject {
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
        
        return props
    }
}

@objc public protocol AnalyticsTracker {
    func track(_ event: String)
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
    
    public func track(_ event: String) {
        trackers.values.forEach { $0.track(event) }
    }

    public func track(_ event: String, properties: [AnyHashable : Any]? = nil) {
        trackers.values.forEach { $0.track(event, properties: properties) }
    }
    
    public func identify(_ user: AnalyticsUser) {
        trackers.values.forEach { $0.identify(user) }
    }
}

class SegmentAnalyticsTracker : NSObject, AnalyticsTracker {
    func track(_ event: String) {
        track(event, properties: nil)
    }
    
    func track(_ event: String, properties: [AnyHashable : Any]? = nil) {
        SEGAnalytics.shared().track(event, properties: properties as? [String : Any])
    }
    
    func identify(_ user: AnalyticsUser) {
        SEGAnalytics.shared().identify(user.identifier, traits: user.analyticsProperties)
    }
    
    func error(_ error: Error) {
        SEGAnalytics.shared().track("Error", properties: ["Description" : error.localizedDescription])
    }
}

class AppseeAnalyticsTracker : NSObject, AnalyticsTracker {
    func track(_ event: String) {
        track(event, properties: nil)
    }

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
    func track(_ event: String) {
        track(event, properties: nil)
    }

    func track(_ event: String, properties: [AnyHashable : Any]?) {
        IntercomHelper.sharedInstance.record(event: event, properties: properties)
    }
    
    func identify(_ user: AnalyticsUser) {
        IntercomHelper.sharedInstance.registerUser(withID: user.identifier, email: user.email, name: user.name)
    }
}

class BranchAnalyticsTracker : NSObject, AnalyticsTracker {
    func track(_ event: String) {
        track(event, properties: nil)
    }

    func track(_ event: String, properties: [AnyHashable : Any]? = nil) {
        Branch.getInstance().userCompletedAction(event, withState: properties ?? [:])
    }
    
    func identify(_ user: AnalyticsUser) {
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

public func track(_ name: String, properties: [AnyHashable : Any]? = nil, tracker: AnalyticsTracker = AnalyticsTrackers.standard) {
    tracker.track(name, properties: properties)
}

public func identify(_ name: String? = nil, email: String? = nil, tracker: AnalyticsTracker = AnalyticsTrackers.standard) -> AnalyticsUser {
    let user = AnalyticsUser(name: name, email: email)
    tracker.identify(user)
    return user
}

extension AnalyticsTracker {
    func trackTappedOnProduct(_ product: Product, onPage page: String) {
        track("Tapped on product", properties: [
            "merchant": product.merchant ?? "",
            "brand": product.brand ?? "",
            "url": product.offer ?? "",
            "imageUrl": product.imageURL ?? "",
            "sale": product.isSale(),
            "page": page
            ])
    }
}
