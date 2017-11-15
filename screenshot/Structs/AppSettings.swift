//
//  AppSettings.swift
//  screenshot
//
//  Created by Corey Werner on 11/15/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

struct AppSettings {
    let discoverUrls: [String]?
    let forceVersion: String?
    let suggestedVersion: String?
    
    init(_ settings: [AnyHashable : Any]) {
        discoverUrls = settings["DiscoverURLs"] as? [String]
        forceVersion = settings["ForceUpdateVersion"] as? String
        suggestedVersion = settings["SuggestedUpdateVersion"] as? String
    }
}

// TODO: remove once classes converted to swift
class _AppSettings : NSObject {
    let discoverUrls: [String]?
    let forceVersion: String?
    let suggestedVersion: String?
    
    init(_ appSettings: AppSettings?) {
        discoverUrls = appSettings?.discoverUrls
        forceVersion = appSettings?.forceVersion
        suggestedVersion = appSettings?.suggestedVersion
    }
}
