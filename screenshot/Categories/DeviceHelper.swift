//
//  DeviceHelper.swift
//  screenshot
//
//  Created by Corey Werner on 10/3/17.
//  Copyright (c) 2017 crazeapp. All rights reserved.
//

import UIKit

// MARK: Type

extension UIDevice {
    static let isSimulator = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil
    
    static var isHomeButtonless: Bool {
        guard #available(iOS 11.0, *), let window = UIApplication.shared.windows.first else {
            return false
        }
        
        return window.safeAreaInsets.bottom > 0
    }
    
    func pushString(data:Data) -> String{
        let token = data.map { String(format: "%02.2hhx", $0) }.joined()
        if isDevelopmentEnvironment() {
            return "dev|\(token)"
        }else{
            return "prod|\(token)"
        }
    }
    
    
    func isDevelopmentEnvironment() -> Bool {
        guard let filePath = Bundle.main.path(forResource: "embedded", ofType:"mobileprovision") else {
            return false
        }
        do {
            let url = URL(fileURLWithPath: filePath)
            let data = try Data(contentsOf: url)
            guard let string = String(data: data, encoding: .ascii) else {
                return false
            }
            if string.contains("<key>aps-environment</key>\n\t\t<string>development</string>") {
                return true
            }
        } catch {}
        return false
    }
    
    fileprivate var modelIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        
        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else {
                return identifier
            }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }
    
    fileprivate var modelIdentifierNumber: Double {
        return Double(modelIdentifier.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: CharacterSet.decimalDigits.inverted)) ?? 0
    }
    
    var hasTapticEngine: Bool {
        return modelIdentifierNumber >= 8 // greater then iPhone 6s
    }
}

// MARK: Size

extension UIDevice {
    static let is320w = UIScreen.main.bounds.size.width == 320 // 4, 5
    static let is375w = UIScreen.main.bounds.size.width == 375 // 6, 7, 8, X
    static let is414w = UIScreen.main.bounds.size.width == 414 // 6+, 7+, 8+
    
    static let is480h = UIScreen.main.bounds.size.height == 480 // 4
    static let is568h = UIScreen.main.bounds.size.height == 568 // 5
    static let is667h = UIScreen.main.bounds.size.height == 667 // 6, 7, 8
    static let is736h = UIScreen.main.bounds.size.height == 736 // 6+, 7+, 8+
    static let is812h = UIScreen.main.bounds.size.height == 812 // X
}
