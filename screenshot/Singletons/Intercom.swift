//
//  Intercom.swift
//  screenshot
//
//  Created by Jacob Relkin on 9/6/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation
import Intercom

class IntercomHelper : NSObject {
    static let sharedInstance = IntercomHelper()
    
    private func updateIntercomDeviceToken() {
        if let token = deviceToken {
            Intercom.setDeviceToken(token)
        }
    }
    
    var deviceToken: Data? {
        set {
            if let token = newValue {
                UserDefaults.standard.set(token, forKey: UserDefaultsKeys.deviceToken)
            } else {
                UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.deviceToken)
            }
            
            UserDefaults.standard.synchronize()
            updateIntercomDeviceToken()
        } get {
            return UserDefaults.standard.object(forKey: UserDefaultsKeys.deviceToken) as? Data
        }
    }
    
    // MARK: -
    
    func performUserUpdate(_ closure:(ICMUserAttributes) -> ()) {
        let attributes = ICMUserAttributes()
        closure(attributes)
        Intercom.updateUser(attributes)
    }

    // MARK: -
    
    func start(withLaunchOptions launchOptions:[AnyHashable : Any]) {
        Intercom.setApiKey(Constants.intercomAPIKey, forAppId: Constants.intercomAppID)
        
        #if DEBUG
            Intercom.enableLogging()
        #endif
        
        // Register the user if we're already logged in.
        if let user = AnalyticsUser.current {
            register(user: user)
        } else if let email = UserDefaults.standard.string(forKey: UserDefaultsKeys.email) {
            // Backwards compatible w/version < 1.2
            Intercom.registerUser(withEmail: email)
        } else if UserDefaults.standard.bool(forKey: UserDefaultsKeys.onboardingCompleted) == false {
            registerAnonymousUser()
        }
        
        if let remoteNotification = launchOptions[UIApplicationLaunchOptionsKey.remoteNotification] as? [AnyHashable : Any] {
            handleRemoteNotification(remoteNotification, opened: true)
        }
    }
    
    func handleRemoteNotification(_ userInfo:[AnyHashable : Any], opened:Bool = false) {
        let isIntercomNotification = Intercom.isIntercomPushNotification(userInfo)
        let trackingPrefix = opened ? "Opened with" : "Received"
        
        AnalyticsTrackers.standard.track("\(trackingPrefix) remote notification", properties: ["fromIntercom": isIntercomNotification ? "true": "false"])
    }
    
    func registerAnonymousUser() {
        Intercom.registerUnidentifiedUser()
    }
    
    func register(user: AnalyticsUser) {
        updateIntercomDeviceToken()
        
        Intercom.registerUser(withUserId: user.identifier)
        
        performUserUpdate { attrs in
            attrs.userId = user.identifier
            
            if let email = user.email {
                attrs.email = email
            }
            
            if let name = user.name {
                attrs.name = name
            }
            
            var customAttrs = attrs.customAttributes ?? [:]
            user.analyticsProperties.forEach { key, value in
                customAttrs[key] = value
            }
            attrs.customAttributes = customAttrs
        }
    }
    
    func logoutUser() {
        Intercom.logout()
    }
    
    func presentMessagingUI() {
        Intercom.presentMessenger()
    }
    
    func hideMessagingUI() {
        Intercom.hideMessenger()
    }
    
    func presentMessageComposer(withInitialMessage message: String = "") {
        Intercom.presentMessageComposer(withInitialMessage: message)
    }
    
    func recordUnsatisfactoryRating() {
        Intercom.logEvent(withName: "Rated app less than 4 stars")
    }
        
    func record(event: String, properties: [AnyHashable : Any]? = nil) {
        if let properties = properties, properties.count > 0 {
            Intercom.logEvent(withName: event, metaData: properties)
        } else {
            Intercom.logEvent(withName: event)
        }
    }
}
