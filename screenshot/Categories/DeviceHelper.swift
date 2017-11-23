//
//  DeviceHelper.swift
//  screenshot
//
//  Created by Corey Werner on 10/3/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

// MARK: Type

extension UIDevice {
    static let isSimulator = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil
    
    static var isHomeButtonless: Bool {
        guard #available(iOS 11, *), let window = UIApplication.shared.windows.first else {
            return false
        }
        
        return window.safeAreaInsets.bottom > 0
    }
}

// MARK: Size

extension UIDevice {
    static let is480h = UIScreen.main.bounds.size.height == 480 // 4
    static let is568h = UIScreen.main.bounds.size.height == 568 // 5
    static let is667h = UIScreen.main.bounds.size.height == 667 // 6, 7, 8
    static let is736h = UIScreen.main.bounds.size.height == 736 // 6+, 7+, 8+
    static let is812h = UIScreen.main.bounds.size.height == 812 // X
}
