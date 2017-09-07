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
    
    private var email: String? {
        return UserDefaults.standard.string(forKey: UserDefaultsKeys.email)
    }
    
    private func updateIntercomDeviceToken() {
        if let token = deviceToken {
            Intercom.setDeviceToken(token)
        }
    }
    
    var deviceToken: Data? {
        didSet {
            updateIntercomDeviceToken()
        }
    }
    
    func start() {
        Intercom.setApiKey(Constants.intercomAPIKey, forAppId: Constants.intercomAppID)
        
        #if DEBUG
            Intercom.enableLogging()
        #endif
        
        // Register the user if we're already logged in.
        if let email = email {
            registerUser(withEmail: email)
        }
    }
    
    func registerUser(withEmail email: String) {
        Intercom.registerUser(withEmail: email)
        
        updateIntercomDeviceToken()
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
}
