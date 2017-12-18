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
    fileprivate(set) var persistedPreviousVersion: String?
    
    private var setter: AppSettingsSetter
    
    init(withSetter setter: AppSettingsSetter) {
        persistedPreviousVersion = UserDefaults.standard.string(forKey: UserDefaultsKeys.previousAppVersion)
        UserDefaults.standard.set(currentVersion, forKey: UserDefaultsKeys.previousAppVersion)
        
        self.setter = setter
        super.init()
        setter.settings = self
    }
    
    private let currentVersion = Bundle.displayVersion
    
    var shouldUpdate: Bool {
        return updateVersion?.compare(currentVersion, options: .numeric) == .orderedDescending
    }
    
    var shouldForceUpdate: Bool {
        return forcedUpdateVersion?.compare(currentVersion, options: .numeric) == .orderedDescending
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
