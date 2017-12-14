//
//  Permissions.swift
//  screenshot
//
//  Created by Corey Werner on 12/14/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation
import AVFoundation
import CoreLocation
import Photos
import UserNotifications

enum PermissionType {
    case camera
    case photo
    case push
    case location
}

enum PermissionStatus {
    case undetermined
    case restricted
    case denied
    case authorized
}

typealias PermissionBlock = (_ granted: Bool) -> ()

final class _PermissionsManager : NSObject, CLLocationManagerDelegate {
    static let shared = _PermissionsManager()
    
    // MARK: Status
    
    private var pushStatus: PermissionStatus = .undetermined {
        didSet {
            let enabled = pushStatus == .authorized
            IntercomHelper.sharedInstance.recordPushNotificationStatus(enabled)
        }
    }
    
    fileprivate func permissionStatus(forType type: PermissionType) -> PermissionStatus {
        switch type {
        case .camera:
            return permissionStatus(forCamera: AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo))
        case .photo:
            return permissionStatus(forPhoto: PHPhotoLibrary.authorizationStatus())
        case .push:
            return pushStatus
        case .location:
            return permissionStatus(forLocation: CLLocationManager.authorizationStatus())
        }
    }
    
    fileprivate func permissionStatus(forCamera status: AVAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        case .notDetermined:
            return .undetermined
        }
    }
    
    fileprivate func permissionStatus(forPhoto status: PHAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        case .notDetermined:
            return .undetermined
        }
    }
    
    fileprivate func permissionStatus(forPush status: UNAuthorizationStatus) -> PermissionStatus {
        fetchPushPermissionStatus()
        
        switch status {
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        case .notDetermined:
            return .undetermined
        }
    }
    
    fileprivate func permissionStatus(forLocation status: CLAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorizedAlways, .authorizedWhenInUse:
            return .authorized
        case .notDetermined:
            return .undetermined
        }
    }
    
    func hasPermission(forType type: PermissionType) -> Bool {
        return permissionStatus(forType: type) == .authorized
    }
    
    // MARK: Request
    
    func requestPermission(forType type: PermissionType, response: @escaping PermissionBlock) {
        func requestResponse() {
            if Thread.isMainThread {
//                response()
            } else {
                
            }
        }
        
        
    }
    
    func requestPermission(forType type: PermissionType, openSettingsIfNeeded open: Bool, response: @escaping PermissionBlock) {
        if open {
            let status = permissionStatus(forType: type)
            
            if status == .undetermined {
                requestPermission(forType: type, response: response)
                
            } else {
                if let url = URL(string: UIApplicationOpenSettingsURLString) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
            
        } else {
            requestPermission(forType: type, response: response)
        }
    }
    
    fileprivate func requestCameraPermission(with response: @escaping PermissionBlock) {
        let status = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        
        if status == .notDetermined {
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: response)
            
        } else {
            response(status == .authorized)
        }
    }
    
    fileprivate func requestPhotoPermission(with response: @escaping PermissionBlock) {
        let status = PHPhotoLibrary.authorizationStatus()
        
        if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization { requestedStatus in
                response(requestedStatus == .authorized)
            }
            
        } else {
            response(status == .authorized)
        }
    }
    
    fileprivate func requestPushPermission(with response: @escaping PermissionBlock) {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        
        UNUserNotificationCenter.current().requestAuthorization(options: options) { (granted, error) in
            self.pushStatus = granted ? .authorized : .denied
            
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            
            response(granted)
        }
    }
    
    fileprivate func requestLocationPermission(with response: @escaping PermissionBlock) {
        let status = CLLocationManager.authorizationStatus()
        
        if status == .notDetermined {
            if CLLocationManager.locationServicesEnabled() {
                if let locationPermissionBlock = locationPermissionBlock {
                    locationPermissionBlock(false)
                }
                
                locationPermissionBlock = response
                
                locationManager = CLLocationManager()
                locationManager?.delegate = self
                locationManager?.requestAlwaysAuthorization()
                
            } else {
                response(false)
            }
            
        } else {
            response(permissionStatus(forLocation: status) == .authorized)
        }
    }
    
    // MARK: Push
    
    fileprivate func fetchPushPermissionStatus() {
        // The push status returns async, to maintain sync we need to manage the value.
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            self.pushStatus = self.permissionStatus(forPush: settings.authorizationStatus)
        }
    }
    
    // MARK: Location
    
    private var locationManager: CLLocationManager?
    private var locationPermissionBlock: PermissionBlock?
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status != .notDetermined, let locationPermissionBlock = locationPermissionBlock {
            locationPermissionBlock(permissionStatus(forLocation: status) == .authorized)
            self.locationPermissionBlock = nil
            
            locationManager?.delegate = nil
            locationManager = nil
        }
    }
    
    // MARK: Alert
    
}
