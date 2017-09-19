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
            updateIntercomDeviceToken()
            
            if let token = deviceToken {
                UserDefaults.standard.set(token, forKey: UserDefaultsKeys.deviceToken)
            } else {
                UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.deviceToken)
            }
        } get {
            return UserDefaults.standard.object(forKey: UserDefaultsKeys.deviceToken) as? Data
        }
    }
    
    var userName: String? {
        didSet {
            let attrs = ICMUserAttributes()
            attrs.name = userName ?? ""

            Intercom.updateUser(attrs)
        }
    }
    
    // MARK: -
    
    func start(withLaunchOptions launchOptions:[AnyHashable : Any]) {
        Intercom.setApiKey(Constants.intercomAPIKey, forAppId: Constants.intercomAppID)
        
        #if DEBUG
            Intercom.enableLogging()
        #endif

        // Register the user if we're already logged in.
        if let email = UserDefaults.standard.string(forKey: UserDefaultsKeys.email) {
            registerUser(withEmail: email)
        }
    
        userName = UserDefaults.standard.string(forKey: UserDefaultsKeys.name)
        
        if let remoteNotification = launchOptions[UIApplicationLaunchOptionsKey.remoteNotification] as? [AnyHashable : Any] {
            handleRemoteNotification(remoteNotification, opened: true)
        }
    }
    
    func handleRemoteNotification(_ userInfo:[AnyHashable : Any], opened:Bool = false) {
        let isIntercomNotification = Intercom.isIntercomPushNotification(userInfo)
        let trackingPrefix = opened ? "Opened with" : "Received"
        
        if isIntercomNotification {
            Intercom.handlePushNotification(userInfo)
        }

        AnalyticsManager.track("\(trackingPrefix) remote notification", properties: ["fromIntercom": isIntercomNotification ? "true": "false"])
    }
    
    func registerUser(withEmail email: String) {
        updateIntercomDeviceToken()
    
        Intercom.registerUser(withEmail: email)
    }
    
    func logoutUser() {
        Intercom.reset()
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
}
