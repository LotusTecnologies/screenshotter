//
//  PermissionsManager.m
//  screenshot
//
//  Created by Corey Werner on 8/8/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "PermissionsManager.h"

//  Libraries
@import CoreLocation;
@import Photos;
@import UserNotifications;

@interface PermissionsManager () <CLLocationManagerDelegate>

@end

@implementation PermissionsManager 

+ (PermissionsManager *)sharedPermissionsManager {
    static dispatch_once_t pred;
    static PermissionsManager *shared = nil;
    
    dispatch_once(&pred, ^{
        shared = [[PermissionsManager alloc] init];
    });
    
    return shared;
}


#pragma mark - Status

- (PermissionStatus)permissionStatusForType:(PermissionType)type {
    switch (type) {
        case PermissionTypePhoto:
            return [self permissionStatusForPhoto:[PHPhotoLibrary authorizationStatus]];
            break;
            
        case PermissionTypePush:
            return [self permissionStatusForPush];
            break;
            
        case PermissionTypeLocation:
            return [self permissionStatusForLocationStatus:[CLLocationManager authorizationStatus]];
            break;
            
        default:
            return PermissionStatusNotDetermined;
            break;
    }
}

- (PermissionStatus)permissionStatusForPhoto:(PHAuthorizationStatus)status {
    switch (status) {
        case PHAuthorizationStatusRestricted:
            return PermissionStatusRestricted;
            break;
            
        case PHAuthorizationStatusDenied:
            return PermissionStatusDenied;
            break;
            
        case PHAuthorizationStatusAuthorized:
            return PermissionStatusAuthorized;
            break;
            
        case PHAuthorizationStatusNotDetermined:
            return PermissionStatusNotDetermined;
            break;
    }
}

- (PermissionStatus)permissionStatusForPush {
    BOOL hasPermission = [[UIApplication sharedApplication] isRegisteredForRemoteNotifications];
    return hasPermission ? PermissionStatusAuthorized : PermissionStatusDenied;
}

- (PermissionStatus)permissionStatusForLocationStatus:(CLAuthorizationStatus)status {
    switch (status) {
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            return PermissionStatusAuthorized;
            break;
            
        case kCLAuthorizationStatusDenied:
            return PermissionStatusDenied;
            break;
            
        case kCLAuthorizationStatusRestricted:
            return PermissionStatusRestricted;
            break;
            
        case kCLAuthorizationStatusNotDetermined:
        default:
            return PermissionStatusNotDetermined;
            break;
    }
}

- (BOOL)hasPermissionForType:(PermissionType)type {
    return [self permissionStatusForType:type] == PermissionStatusAuthorized;
}


#pragma mark - Request

- (void)requestPermissionForType:(PermissionType)type response:(PermissionBlock)response {
    PermissionBlock responseCopy = [response copy];
    PermissionBlock responseCopyOnMainThread = [^(BOOL granted) {
        if (responseCopy) {
            if ([NSThread isMainThread]) {
                responseCopy(granted);
                
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    responseCopy(granted);
                });
            }
        }
    } copy];
    
    switch (type) {
        case PermissionTypePhoto:
            [self requestPhotoPermissionWithResponse:responseCopyOnMainThread];
            break;
            
        case PermissionTypePush:
            [self requestPushPermissionWithResponse:responseCopyOnMainThread];
            break;
            
        case PermissionTypeLocation:
            [self requestLocationPermissionWithResponse:responseCopyOnMainThread];
            break;
    }
}

- (void)requestPhotoPermissionWithResponse:(PermissionBlock)response {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    
    if (status == PHAuthorizationStatusNotDetermined) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus requestedStatus) {
            if (response) {
                response(requestedStatus == PHAuthorizationStatusAuthorized);
            }
        }];
        
    } else {
        if (response) {
            response(status == PHAuthorizationStatusAuthorized);
        }
    }
}

- (void)requestPushPermissionWithResponse:(PermissionBlock)response {
    UNAuthorizationOptions options = UNAuthorizationOptionAlert | UNAuthorizationOptionBadge | UNAuthorizationOptionSound;
    
    [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:options completionHandler:^(BOOL granted, NSError * _Nullable error) {
        // ???: is this needed
//        [[UIApplication sharedApplication] registerForRemoteNotifications];
        
        if (response) {
            response(granted);
        }
    }];
}

- (void)requestLocationPermissionWithResponse:(PermissionBlock)response {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    
    if (status == kCLAuthorizationStatusNotDetermined) {
        if ([CLLocationManager locationServicesEnabled]) {
            CLLocationManager *locationManager = [[CLLocationManager alloc] init];
            locationManager.delegate = self;
            
            // TODO: call one of the below.
//            [locationManager requestAlwaysAuthorization];
//            [locationManager requestWhenInUseAuthorization];
            
            // TODO: once the delegate is called, take the response and pass it here
            if (response) {
                response(NO);
            }
            
        } else {
            if (response) {
                response(NO);
            }
        }
        
    } else {
        if (response) {
            response(status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse);
        }
    }
}


#pragma mark - Location Manager

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    
}

@end
