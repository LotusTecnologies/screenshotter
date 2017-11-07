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
        if let id = UserDefaults.standard.string(forKey: UserDefaultsKeys.userID) {
            if let email = UserDefaults.standard.string(forKey: UserDefaultsKeys.email) {
                Intercom.registerUser(withUserId: id, email: email)
            } else {
                Intercom.registerUser(withUserId: id)
            }
        } else if let email = UserDefaults.standard.string(forKey: UserDefaultsKeys.email) {
            // Backwards compatible w/version < 1.2
            Intercom.registerUser(withEmail: email)
        }
        
        if let remoteNotification = launchOptions[UIApplicationLaunchOptionsKey.remoteNotification] as? [AnyHashable : Any] {
            handleRemoteNotification(remoteNotification, opened: true)
        }
    }
    
    func handleRemoteNotification(_ userInfo:[AnyHashable : Any], opened:Bool = false) {
        let isIntercomNotification = Intercom.isIntercomPushNotification(userInfo)
        let trackingPrefix = opened ? "Opened with" : "Received"
        
        track("\(trackingPrefix) remote notification", properties: ["fromIntercom": isIntercomNotification ? "true": "false"])
    }
    
    func registerUser(withID id:String, email: String? = nil, name: String? = nil) {
        updateIntercomDeviceToken()
        
        Intercom.registerUser(withUserId: id)
        
        performUserUpdate { attrs in
            attrs.email = email
            attrs.name = name
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
    
    func recordUnsatisfactoryRating() {
        Intercom.logEvent(withName: "Rated app less than 4 stars")
    }
    
    func recordPushNotificationStatus(_ enabled:Bool) {
        let name = "APN \(enabled ? "En" : "Dis")abled"
        track(name)
        Intercom.logEvent(withName: name)
    }
    
    func record(event: String, properties: [AnyHashable : Any]? = nil) {
        if let properties = properties {
            Intercom.logEvent(withName: event, metaData: properties)
        } else {
            Intercom.logEvent(withName: event)
        }
    }
}