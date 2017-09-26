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
    let name: String
    let email: String
    
    init(name n: String, email e:String) {
        name = n
        email = e
    }
}

@objc public protocol AnalyticsTracker {
    func track(_ event: String)
    func track(_ event: String, properties: [AnyHashable : Any]?)
    func identify(_ user: AnalyticsUser)
}

public class CompositeAnalyticsTracker : NSObject {
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
    
    // MARK: -
    
    public func track(_ event: String) {
        trackers.values.forEach { $0.track(event) }
    }

    public func track(_ event: String, properties: [AnyHashable : Any]? = nil) {
        track(event, properties: properties, excludingTrackers: [])
    }
    
    public func track(_ event: String, properties: [AnyHashable : Any]? = nil, excludingTrackers excluded: [AnalyticsTracker.Type]) {
        trackers.values.reduce([], { (trackers, tracker) -> [AnalyticsTracker] in
            var t = trackers
            
            if !excluded.contains(where: { $0 == type(of: tracker) }) {
                t.append(tracker)
            }
            
            
            return t
        }).forEach { $0.track(event, properties: properties) }
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
        _track(name: event, properties: properties) {
            SEGAnalytics.shared().track(event, properties: properties as? [String : Any])
        }
    }
    
    func identify(_ user: AnalyticsUser) {
        SEGAnalytics.shared().identify(nil, traits: ["email": user.email, "name":user.name])
    }
}

class AppSeeAnalyticsTracker : NSObject, AnalyticsTracker {
    func track(_ event: String) {
        track(event, properties: nil)
    }

    func track(_ event: String, properties: [AnyHashable : Any]? = nil) {
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
            
            _track(name: event, properties: props) {
                Appsee.addEvent(event, withProperties: props)
            }
        } else {
            _track(name: event) {
                Appsee.addEvent(event)
            }
        }
    }
    
    func identify(_ user: AnalyticsUser) {
        Appsee.setUserID(user.email)
    }
}

class IntercomAnalyticsTracker : NSObject, AnalyticsTracker {
    func track(_ event: String) {
        track(event, properties: nil)
    }

    func track(_ event: String, properties: [AnyHashable : Any]?) {
        _track(name: event, properties: properties) {
            IntercomHelper.sharedInstance.record(event: event, properties: properties)
        }
    }
    
    func identify(_ user: AnalyticsUser) {
        IntercomHelper.sharedInstance.registerUser(withEmail: user.email, name: user.name)
    }
}

class BranchAnalyticsTracker : NSObject, AnalyticsTracker {
    func track(_ event: String) {
        track(event, properties: nil)
    }

    func track(_ event: String, properties: [AnyHashable : Any]? = nil) {
        _track(name: event) {
            Branch.getInstance().userCompletedAction(event, withState: properties ?? [:])
        }
    }
    
    func identify(_ user: AnalyticsUser) {
        _track(name: "identify") {
            Branch.getInstance().userCompletedAction("identify")
        }
    }
}

public class AnalyticsTrackers : NSObject {
    static let appsee = AppSeeAnalyticsTracker()
    static let segment = SegmentAnalyticsTracker()
    static let intercom = IntercomAnalyticsTracker()
    static let branch = BranchAnalyticsTracker()
    
    static let standard = CompositeAnalyticsTracker(trackers: [segment, appsee])
}

extension AnalyticsTracker {
    fileprivate func _track(name: String, properties: [AnyHashable : Any]? = nil, _ closure:() -> ()) {
        print("[\(type(of: self))] \"\(name)\" tracked -- Properties: \((properties ?? [:]).debugDescription)")
        
        closure()
    }
}

