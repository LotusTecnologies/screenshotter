//
//  AppSettings.swift
//  screenshot
//
//  Created by Corey Werner on 11/15/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

enum AppSettingKeys : String {
    case updateVersion = "SuggestedUpdateVersion"
    case forcedUpdateVersion = "ForceUpdateVersion"
    case openWebPageDefault = "OpenProductsPageDefault"
}

class AppSettings  {
    var appSettingsDict:[String:Any]?  //DO NOT change AppSettingKeys.  future json may have more values than are listed in the appsetting keys
    private let currentVersion = Bundle.displayVersion

    var updateVersion: String? {
        return self.appSettingsDict?[AppSettingKeys.updateVersion.rawValue] as? String
    }
    
    var forcedUpdateVersion: String? {
        return self.appSettingsDict?[AppSettingKeys.forcedUpdateVersion.rawValue] as? String
    }
    
    var openWebPageDefault: String? {
        return self.appSettingsDict?[AppSettingKeys.openWebPageDefault.rawValue] as? String
    }
    
    var previousVersion: String? 
    
    init() {
        previousVersion = UserDefaults.standard.string(forKey: UserDefaultsKeys.persistentVersion)
        UserDefaults.standard.set(currentVersion, forKey: UserDefaultsKeys.persistentVersion)
    }
    
    func isCurrentVersion(lessThan version: String?) -> Bool {
        return version?.compare(currentVersion, options: .numeric) == .orderedDescending
    }
    
    func isCurrentVersion(greaterThan version: String?) -> Bool {
        return version?.compare(currentVersion, options: .numeric) == .orderedAscending
    }
    
    var shouldUpdate: Bool {
        return isCurrentVersion(lessThan: updateVersion)
    }
    
    var shouldForceUpdate: Bool {
        return isCurrentVersion(lessThan: forcedUpdateVersion)
    }
}

