//
//  Bundle_Extensions.swift
//  screenshot
//
//  Created by Jacob Relkin on 11/6/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

extension Bundle {
    var displayName: String? {
        return object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
    }
    
    var shortVersion: String? {
        return object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
}
