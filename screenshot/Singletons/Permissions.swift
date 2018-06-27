//
//  Permissions.swift
//  screenshot
//
//  Created by Corey Werner on 12/14/17.
//  Copyright (c) 2017 crazeapp. All rights reserved.
//

import UIKit
import AVFoundation
import CoreLocation
import Photos
import UserNotifications
import Pushwoosh

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

final class PermissionsManager : NSObject, CLLocationManagerDelegate {
    static let shared = PermissionsManager()
    
    // MARK: Status
    
    private var pushStatus: PermissionStatus = .undetermined {
        didSet {
            let enabled = pushStatus == .authorized
            
            let tokenString = (UserDefaults.standard.object(forKey: UserDefaultsKeys.deviceToken) as? Data)?.description
            
            if enabled {
                Analytics.trackAPNEnabled(token: tokenString)
            }
            else {
                Analytics.trackAPNDisabled(token: tokenString)
            }
        }
    }
    
    func permissionStatus(for type: PermissionType) -> PermissionStatus {
        switch type {
        case .camera:
            return permissionStatus(forCamera: AVCaptureDevice.authorizationStatus(for: AVMediaType.video))
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
    
    func hasPermission(for type: PermissionType) -> Bool {
        return permissionStatus(for: type) == .authorized
    }
    
    // MARK: Request
    
    func requestPermission(for type: PermissionType, response: PermissionBlock? = nil) {
        func requestResponse(_ granted: Bool) {
            guard let response = response else {
                return
            }
            
            if Thread.isMainThread {
                response(granted)
                
            } else {
                DispatchQueue.main.async {
                    response(granted)
                }
            }
        }
        
        switch type {
        case .camera:
            requestCameraPermission(with: requestResponse)
        case .photo:
            requestPhotoPermission(with: requestResponse)
        case .push:
            requestPushPermission(with: requestResponse)
        case .location:
            requestLocationPermission(with: requestResponse)
        }
    }
    
    func requestPermission(for type: PermissionType, openSettingsIfNeeded open: Bool, response: PermissionBlock? = nil) {
        if open {
            let status = permissionStatus(for: type)
            
            if status == .undetermined {
                requestPermission(for: type, response: response)
                
            } else {
                if let url = URL(string: UIApplicationOpenSettingsURLString) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
            
        } else {
            requestPermission(for: type, response: response)
        }
    }
    
    fileprivate func requestCameraPermission(with response: PermissionBlock?) {
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        
        if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: response!)
            
        } else {
            if let response = response {
                response(status == .authorized)
            }
        }
    }
    
    fileprivate func requestPhotoPermission(with response: PermissionBlock?) {
        let status = PHPhotoLibrary.authorizationStatus()
        
        if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization { requestedStatus in
                if let response = response {
                    response(requestedStatus == .authorized)
                }
                NotificationCenter.default.post(name: .permissionsManagerDidUpdate, object: self)
            }
            
        } else {
            if let response = response {
                response(status == .authorized)
            }
        }
    }
    
    fileprivate func requestPushPermission(with response: PermissionBlock?) {
        PushNotificationManager.push().registerForPushNotifications()
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        
        UNUserNotificationCenter.current().requestAuthorization(options: options) { (granted, error) in
            self.pushStatus = granted ? .authorized : .denied
            
            if granted {
                DispatchQueue.main.async {
                    PushNotificationManager.push().registerForPushNotifications()
                }
            }
            
            if let response = response {
                response(granted)
            }
            NotificationCenter.default.post(name: .permissionsManagerDidUpdate, object: self)
        }
    }
    
    fileprivate func requestLocationPermission(with response: PermissionBlock?) {
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
                if let response = response {
                    response(false)
                }
            }
            
        } else {
            if let response = response {
                response(permissionStatus(forLocation: status) == .authorized)
            }
        }
    }
    
    // MARK: Push
    
    func fetchPushPermissionStatus() {
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
        NotificationCenter.default.post(name: .permissionsManagerDidUpdate, object: self)
    }
    
    // MARK: Alert
    
    func deniedAlertController(for type: PermissionType, opened: PermissionBlock? = nil) -> UIAlertController? {
        let message: String? = {
            switch type {
            case .photo:
                return "permission.photo.denied.message".localized
            case .push:
                return "permission.push.denied.message".localized
            default:
                return nil
            }
        }()
        
        switch type {
        case .photo, .push:
            let alertController = UIAlertController(title: "permission.denied.title".localized, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "generic.ok".localized, style: .default, handler: { action in
                if let url = URL(string: UIApplicationOpenSettingsURLString) {
                    UIApplication.shared.open(url, options: [:], completionHandler: opened)
                }
            }))
            return alertController
            
        default:
            return nil
        }
    }
}
