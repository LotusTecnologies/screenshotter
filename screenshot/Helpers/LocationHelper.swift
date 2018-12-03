//
//  LocationHelper.swift
//  productAlert
//
//  Created by Zachary Podbela on 12/3/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import CoreLocation

public class LocationHelper: NSObject, CLLocationManagerDelegate {
    public static let sharedInstance = LocationHelper()
    
    var locationManager:CLLocationManager = CLLocationManager()
    var lastKnownLocation:CLLocation?
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
    }
    
    public class func lastKnownLocation() -> CLLocation? {
        return sharedInstance.lastKnownLocation
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastKnownLocation = locations[0] as CLLocation
        
        // Call stopUpdatingLocation() to stop listening for location updates,
        // other wise this function will be called every time when user location changes.
        // manager.stopUpdatingLocation()
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("LOCATION MANAGER ERROR: \(error)")
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            manager.startUpdatingLocation()
        }
    }
}
