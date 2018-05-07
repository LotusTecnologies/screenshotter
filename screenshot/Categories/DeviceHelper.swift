//
//  DeviceHelper.swift
//  screenshot
//
//  Created by Corey Werner on 10/3/17.
//  Copyright © 2017 crazeapp. All rights reserved.
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
    
    func freeDiskSpace() -> String? {
        do {
            if let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last
            {
                let dictionary = try FileManager.default.attributesOfFileSystem(forPath: path)
                if let freeFileSystemSizeInBytes = dictionary[FileAttributeKey.systemFreeSize] as? NSNumber {
                    let totalFreeSpace = freeFileSystemSizeInBytes.int64Value;
                    let formater = ByteCountFormatter.init()
                    formater.countStyle = .memory
                    let string = formater.string(fromByteCount: totalFreeSpace)
                    return string;
                }
            }
        }catch {
            //eh
        }
        
        return nil
    }
    func totalDiskSpace() -> String? {
        do {
            if let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last
            {
                let dictionary = try FileManager.default.attributesOfFileSystem(forPath: path)
                if let freeFileSystemSizeInBytes = dictionary[FileAttributeKey.systemSize] as? NSNumber {
                    let totalFreeSpace = freeFileSystemSizeInBytes.int64Value;
                    
                    let formater = ByteCountFormatter.init()
                    formater.countStyle = .memory
                    let string = formater.string(fromByteCount: totalFreeSpace)
                    
                    return string;
                }
            }
        }catch {
            //eh
        }
        
        return nil
    }
    func ramUsed() -> String {
        var pagesize: vm_size_t = 0
        
        let host_port: mach_port_t = mach_host_self()
        var host_size: mach_msg_type_number_t = mach_msg_type_number_t(MemoryLayout<vm_statistics_data_t>.stride / MemoryLayout<integer_t>.stride)
        host_page_size(host_port, &pagesize)
        
        var vm_stat: vm_statistics = vm_statistics_data_t()
        withUnsafeMutablePointer(to: &vm_stat) { (vmStatPointer) -> Void in
            vmStatPointer.withMemoryRebound(to: integer_t.self, capacity: Int(host_size)) {
                if (host_statistics(host_port, HOST_VM_INFO, $0, &host_size) != KERN_SUCCESS) {
                    NSLog("Error: Failed to fetch vm statistics")
                }
            }
        }
        
        let mem_used: Int64 = Int64(vm_stat.active_count +
            vm_stat.inactive_count +
            vm_stat.wire_count) * Int64(pagesize)
        let formater = ByteCountFormatter.init()
        formater.countStyle = .memory
        let used_string = formater.string(fromByteCount: mem_used)
        
        return used_string
    }
    
    func ramFree() -> String {
        var pagesize: vm_size_t = 0
        
        let host_port: mach_port_t = mach_host_self()
        var host_size: mach_msg_type_number_t = mach_msg_type_number_t(MemoryLayout<vm_statistics_data_t>.stride / MemoryLayout<integer_t>.stride)
        host_page_size(host_port, &pagesize)
        
        var vm_stat: vm_statistics = vm_statistics_data_t()
        withUnsafeMutablePointer(to: &vm_stat) { (vmStatPointer) -> Void in
            vmStatPointer.withMemoryRebound(to: integer_t.self, capacity: Int(host_size)) {
                if (host_statistics(host_port, HOST_VM_INFO, $0, &host_size) != KERN_SUCCESS) {
                    NSLog("Error: Failed to fetch vm statistics")
                }
            }
        }
        
       let mem_free: Int64 = Int64(vm_stat.free_count) * Int64(pagesize)
        
        let formater = ByteCountFormatter.init()
        formater.countStyle = .memory
        let free_string = formater.string(fromByteCount: mem_free)
        
        return free_string
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
