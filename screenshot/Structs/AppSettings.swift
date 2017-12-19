//
//  AppSettings.swift
//  screenshot
//
//  Created by Corey Werner on 11/15/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

final class AppSettings : NSObject {
    fileprivate(set) var discoverURLs: [URL?]?
    fileprivate(set) var forcedDiscoverURL: URL?
    fileprivate(set) var updateVersion: String?
    fileprivate(set) var forcedUpdateVersion: String?
    fileprivate(set) var previousVersion: String?
    
    private var setter: AppSettingsSetter
    
    init(withSetter setter: AppSettingsSetter) {
        previousVersion = UserDefaults.standard.string(forKey: UserDefaultsKeys.persistentVersion)
        UserDefaults.standard.set(currentVersion, forKey: UserDefaultsKeys.persistentVersion)
        
        self.setter = setter
        super.init()
        setter.settings = self
    }
    
    // MARK: Version
    
    private let currentVersion = Bundle.displayVersion
    
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

final class AppSettingsSetter : NSObject {
    fileprivate var settings: AppSettings!
    
    func setDiscoverURLs(withURLPaths urlPaths: [String]?) {
        guard let urlPaths = urlPaths else {
            return
        }
        
        settings.discoverURLs = urlPaths.map { urlPath in
            return URL(string: urlPath)
        }
    }
    
    func setForcedDiscoverURL(withURLPath urlPath: String?) {
        guard let urlPath = urlPath else {
            return
        }
        
        settings.forcedDiscoverURL = URL(string: urlPath)
    }
    
    func setUpdateVersion(_ version: String?) {
        settings.updateVersion = version
    }
    
    func setForcedUpdateVersion(_ version: String?) {
        settings.forcedUpdateVersion = version
    }
}

struct FetchedAppSettings {
    let discoverURLPaths: [String]?
    let updateVersion: String?
    let forcedUpdateVersion: String?
    
    init(_ settings: [AnyHashable : Any]) {
        discoverURLPaths = settings["DiscoverURLs"] as? [String]
        updateVersion = settings["SuggestedUpdateVersion"] as? String
        forcedUpdateVersion = settings["ForceUpdateVersion"] as? String
    }
}
