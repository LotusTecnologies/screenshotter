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
    static let is480h = UIScreen.main.bounds.size.height == 480
    static let is568h = UIScreen.main.bounds.size.height == 568
}
