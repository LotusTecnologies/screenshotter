//
//  SilentPushSubscriptionManager.swift
//  screenshot
//
//  Created by Jacob Relkin on 11/27/17.
//  Copyright (c) 2017 crazeapp. All rights reserved.
//

import Foundation
import PromiseKit

class SilentPushSubscriptionManager : NSObject {
    static let sharedInstance = SilentPushSubscriptionManager()
    
    private var significantTimeChangeObserver: Any?
    private var timeZone: TimeZone!
    
    private var subscriptionARN: String? {
        get {
            return UserDefaults.standard.string(forKey: UserDefaultsKeys.subscriptionARN)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.subscriptionARN)
        }
    }
    
    private var deviceToken: NSData? {
        return UserDefaults.standard.object(forKey: UserDefaultsKeys.deviceToken) as? NSData
    }
    
    private var lastTimeZone: String? {
        get {
            return UserDefaults.standard.string(forKey: UserDefaultsKeys.lastTimeZone)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.lastTimeZone)
        }
    }
    
    override init() {
        timeZone = TimeZone.current
        
        super.init()
        
        beginObservingForSignificantTimeChange()
    }
    
    deinit {
        if let observer = significantTimeChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: -
    
    public func updateSubscriptionsIfNeeded() {
        let agreedToImageDetection = UserDefaults.standard.bool(forKey: UserDefaultsKeys.gdpr_agreedToImageDetection)
        let hasDeviceToken = deviceToken != nil
        let hasARN = subscriptionARN != nil
        let enabledSilentPush = UserDefaults.standard.bool(forKey: UserDefaultsKeys.enabledSilentPush)
        
        if agreedToImageDetection && hasDeviceToken && [hasARN, enabledSilentPush].contains(false) {
            updateSubscriptions().then { _ -> Void in
                UserDefaults.standard.set(true, forKey: UserDefaultsKeys.enabledSilentPush)
            }
        }
    }
    
    // MARK: - Significant Time Changes
    
    private func beginObservingForSignificantTimeChange() {
        guard significantTimeChangeObserver == nil else {
            return
        }
        
        significantTimeChangeObserver = NotificationCenter.default.addObserver(self, selector: #selector(significantTimeChange(_:)), name: NSNotification.Name.UIApplicationSignificantTimeChange, object: nil)
    }
    
    @objc private func significantTimeChange(_ notification: Notification) {
        if timeZone != TimeZone.current {
            timeZone = TimeZone.current
            
            let _ = updateSubscriptions()
        }
    }
    
    // MARK: - Subscriptions
    
    func updateSubscriptions() -> Promise<Void> {
        guard let token = deviceToken else {
            return Promise(error: NSError(domain: "Craze", code: 0, userInfo: [NSLocalizedDescriptionKey : "Invalid device token"]))
        }
        
        return NetworkingPromise.sharedInstance.createAndSubscribeToSilentPushEndpoint(pushToken: token.description,
                                                                        tzOffset: self.serverFormattedOffset(timezone: timeZone),
                                                                        subscriptionARN: self.subscriptionARN).then { ARN -> Void in
            self.subscriptionARN = ARN
        }
    }
    
    func serverFormattedOffset(timezone:TimeZone) -> String{
        let secondsFromGMT = timezone.secondsFromGMT()
        let isNegative = secondsFromGMT < 0
        let seconds = abs(secondsFromGMT)
        let minutes = Double(seconds) / 60
        var hours = Int(round(minutes / 60.0)) // Rounding because we don't want half timzeones like +3.5
        
        if hours < -12 || hours > 11 {
            hours = -12
        }
        
        let prefix = isNegative ? "-" : "+"
        let zeropad = hours < 10 && hours > -10 ? "0" : ""
        return "\(prefix)\(zeropad)\(abs(hours))"
    }
}

