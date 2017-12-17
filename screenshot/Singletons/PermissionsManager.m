//
//  PermissionsManager.m
//  screenshot
//
//  Created by Corey Werner on 8/8/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "PermissionsManager.h"
#import "screenshot-Swift.h"

//  Libraries
@import AVFoundation;
@import CoreLocation;
@import Photos;
@import UserNotifications;

@interface __PermissionsManager () <CLLocationManagerDelegate>

@property (nonatomic) PermissionStatus pushStatus;

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, copy) PermissionBlock locationPermissionBlock;

@end

@implementation __PermissionsManager 

+ (PermissionsManager *)sharedPermissionsManager {
    static dispatch_once_t pred;
    static PermissionsManager *shared = nil;
    
    dispatch_once(&pred, ^{
        shared = [[PermissionsManager alloc] init];
    });
    
    return shared;
}

#pragma mark - Status

- (void)setPushStatus:(PermissionStatus)pushStatus {
    if (_pushStatus != pushStatus) {
        _pushStatus = pushStatus;
        
        BOOL enabled = _pushStatus == PermissionStatusAuthorized;
        
        NSString *name = [NSString stringWithFormat:@"APN %@abled", enabled ? @"En" : @"Dis"];
        NSDictionary<NSString *, NSString *> *properties = nil;

        NSData *token = [NSUserDefaults.standardUserDefaults objectForKey:[UserDefaultsKeys deviceToken]];
        if (token != nil) {
            properties = @{ @"token" : token.description };
        }
        
        [AnalyticsTrackers.standard track:name properties:properties];
    }
}

- (PermissionStatus)permissionStatusForType:(PermissionType)type {
    switch (type) {
        case PermissionTypeCamera:
            return [self permissionStatusForCamera:[AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]];
            break;
            
        case PermissionTypePhoto:
            return [self permissionStatusForPhoto:[PHPhotoLibrary authorizationStatus]];
            break;
            
        case PermissionTypePush:
            return self.pushStatus;
            break;
            
        case PermissionTypeLocation:
            return [self permissionStatusForLocation:[CLLocationManager authorizationStatus]];
            break;
            
        default:
            return PermissionStatusNotDetermined;
            break;
    }
}

- (PermissionStatus)permissionStatusForCamera:(AVAuthorizationStatus)status {
    switch (status) {
        case AVAuthorizationStatusRestricted:
            return PermissionStatusRestricted;
            break;
            
        case AVAuthorizationStatusDenied:
            return PermissionStatusDenied;
            break;
            
        case AVAuthorizationStatusAuthorized:
            return PermissionStatusAuthorized;
            break;
            
        case AVAuthorizationStatusNotDetermined:
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

- (PermissionStatus)permissionStatusForPush:(UNAuthorizationStatus)status {
    // Fetch to try and keep the status always synced.
    [self fetchPushPermissionStatus];
    
    switch (status) {
        case UNAuthorizationStatusDenied:
            return PermissionStatusDenied;
            break;
            
        case UNAuthorizationStatusNotDetermined:
            return PermissionStatusNotDetermined;
            break;
            
        case UNAuthorizationStatusAuthorized:
            return PermissionStatusAuthorized;
            break;
    }
}

- (PermissionStatus)permissionStatusForLocation:(CLAuthorizationStatus)status {
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
        case PermissionTypeCamera:
            [self requestCameraPermissionWithResponse:responseCopyOnMainThread];
            break;
            
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

- (void)requestPermissionForType:(PermissionType)type openSettingsIfNeeded:(BOOL)openSettings response:(PermissionBlock)response {
    if (openSettings) {
        PermissionStatus status = [self permissionStatusForType:type];
        
        if (status == PermissionStatusNotDetermined) {
            [self requestPermissionForType:type response:response];
            
        } else {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
        }
        
    } else {
        [self requestPermissionForType:type response:response];
    }
}

- (void)requestCameraPermissionWithResponse:(PermissionBlock)response {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    if (status == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if (response) {
                response(granted);
            }
        }];
        
    } else {
        if (response) {
            response(status == AVAuthorizationStatusAuthorized);
        }
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
        self.pushStatus = granted ? PermissionStatusAuthorized : PermissionStatusDenied;
        
        if (granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] registerForRemoteNotifications];
            });
        }
        
        if (response) {
            response(granted);
        }
    }];
}

- (void)requestLocationPermissionWithResponse:(PermissionBlock)response {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    
    if (status == kCLAuthorizationStatusNotDetermined) {
        if ([CLLocationManager locationServicesEnabled]) {
            if (response) {
                if (self.locationPermissionBlock) {
                    self.locationPermissionBlock(NO);
                }
                
                self.locationPermissionBlock = response;
            }
            
            self.locationManager = [[CLLocationManager alloc] init];
            self.locationManager.delegate = self;
            [self.locationManager requestAlwaysAuthorization];
            
        } else {
            if (response) {
                response(NO);
            }
        }
        
    } else {
        if (response) {
            response([self permissionStatusForLocation:status] == PermissionStatusAuthorized);
        }
    }
}


#pragma mark - Push

- (void)fetchPushPermissionStatus {
    // The push status returns async, to maintain sync we need to manage the value.
    
    [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        self.pushStatus = [self permissionStatusForPush:settings.authorizationStatus];
    }];
}


#pragma mark - Location

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status != kCLAuthorizationStatusNotDetermined) {
        if (self.locationPermissionBlock) {
            self.locationPermissionBlock([self permissionStatusForLocation:status] == PermissionStatusAuthorized);
            self.locationPermissionBlock = nil;
            
            self.locationManager.delegate = nil;
            self.locationManager = nil;
        }
    }
}


#pragma mark - Alert

- (UIAlertController *)deniedAlertControllerForType:(PermissionType)type opened:(PermissionBlock)opened {
    if (type == PermissionTypePhoto) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Allow Permissions To Continue" message:@"We need access to your photos in order to show you shoppable items." preferredStyle:UIAlertControllerStyleAlert];
        
        [alertController addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:opened];
        }]];
        
        return alertController;
        
    } else {
        return nil;
    }
}

@end
