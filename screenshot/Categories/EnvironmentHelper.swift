//
//  EnvironmentHelper.swift
//  screenshot
//
//  Created by Corey Werner on 11/15/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit

extension Bundle {
    static let displayName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? ""
    static let displayVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    static let displayBuild = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? ""
    static var displayVersionBuild: String {
        return "\(Bundle.displayVersion).\(Bundle.displayBuild)" as String
    }
}

extension UIApplication {
    static var isDev: Bool {
        #if DEV
            return true
        #else
            return false
        #endif
    }
    
    static var isUSC: Bool {
        if isDev {
            return true
        }
        else {
            return UserDefaults.standard.bool(forKey: UserDefaultsKeys.isUSC)
        }
    }
}

extension DispatchQueue {
    static func mainAsyncIfNeeded(_ work:@escaping ()->Void ){
        if Thread.isMainThread {
            work()
        }else{
            DispatchQueue.main.async(execute: work)
        }
    }
}
