//
//  PermissionsManager.h
//  screenshot
//
//  Created by Corey Werner on 8/8/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, PermissionType) {
    PermissionTypePhoto,
    PermissionTypePush,
    PermissionTypeLocation
};

typedef NS_ENUM(NSUInteger, PermissionStatus) {
    PermissionStatusNotDetermined,
    PermissionStatusRestricted,
    PermissionStatusDenied,
    PermissionStatusAuthorized
};

typedef void (^PermissionBlock)(BOOL granted);

@interface PermissionsManager : NSObject

+ (PermissionsManager *)sharedPermissionsManager;

- (PermissionStatus)permissionStatusForType:(PermissionType)type;
- (BOOL)hasPermissionForType:(PermissionType)type;
- (void)requestPermissionForType:(PermissionType)type response:(PermissionBlock)response;
- (void)requestPermissionForType:(PermissionType)type openSettingsIfNeeded:(BOOL)openSettings response:(PermissionBlock)response;

- (UIAlertController *)deniedAlertControllerForType:(PermissionType)type opened:(PermissionBlock)opened;

//  Called when the app starts
- (void)fetchPushPermissionStatus;

@end
