//
//  PermissionsManager.m
//  screenshot
//
//  Created by Corey Werner on 8/8/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "PermissionsManager.h"

//  Libraries
@import AssetsLibrary;
@import Photos;
#import <CoreLocation/CoreLocation.h>

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
//            executeOrAsyncOnMain(^{
                if (responseCopy) {
                    responseCopy(granted);
                }
//            });
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
            //not supported use CLLocationManger
            break;
    }
}

- (void)requestPhotoPermissionWithResponse:(PermissionBlock)response {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    
    if (status == PHAuthorizationStatusNotDetermined) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus requestedStatus) {
            if (requestedStatus == PHAuthorizationStatusDenied) {
//                LoginLogDebug(@"Photo Library: User denied access");
            }
            
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
//    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
//    
//    [delegate promptForRemoteNotifications:^(BOOL granted) {
//        [[AnalyticsManager sharedAnalyticsManager] logAnalyticsEventForPermissionsType:@"Notifications" granted:granted];
//        
//        if (response) {
//            response(granted);
//        }
//    }];
}

@end
