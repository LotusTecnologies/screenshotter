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

#if DEBUG
    private static let apiKey = "ios_sdk-97795b9b5fdcdb25e81866ff066ffa4869376161"
    private static let appID = "z57orduu"
#else
    private static let apiKey = "ios_sdk-ddb9fad7f09f9b18ee7491740f99b6fd98e2296b"
    private static let appID = "avy9hyuz"
#endif

    class func start() {
        Intercom.setApiKey(apiKey, forAppId: appID)

        // Register the user if we're already logged in.
        if let email = UserDefaults.standard.string(forKey: UserDefaultsKeys.email) {
            registerUser(withEmail: email)
        }
    }
    
    class func registerUser(withEmail email: String) {
        Intercom.registerUser(withEmail: email)
    }
    
    class func logoutUser() {
        Intercom.reset()
    }
    
    class func presentMessagingUI() {
        Intercom.presentMessenger()
    }
    
    class func hideMessagingUI() {
        Intercom.hideMessenger()
    }
}
