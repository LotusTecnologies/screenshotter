//
//  Intercom.swift
//  screenshot
//
//  Created by Jacob Relkin on 9/6/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation
import Intercom

extension Data {
    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}

class IntercomHelper : NSObject {
    static let sharedInstance = IntercomHelper()
    
#if DEBUG
    private let apiKey = "ios_sdk-97795b9b5fdcdb25e81866ff066ffa4869376161"
    private let appID = "z57orduu"
#else
    private let apiKey = "ios_sdk-ddb9fad7f09f9b18ee7491740f99b6fd98e2296b"
    private let appID = "avy9hyuz"
#endif
    
    private var email: String? {
        return UserDefaults.standard.string(forKey: UserDefaultsKeys.email)
    }
    
    private func updateIntercomDeviceToken() {
        if let token = deviceToken {
            print(token.hexEncodedString())
            Intercom.setDeviceToken(token)
        }
    }
    
    var deviceToken: Data? {
        didSet {
            updateIntercomDeviceToken()
        }
    }
    
    func start() {
        Intercom.setApiKey(apiKey, forAppId: appID)
        
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
