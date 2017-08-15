//
//  TutorialPermissionsSlideView.m
//  screenshot
//
//  Created by Corey Werner on 8/9/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "TutorialPermissionsSlideView.h"
#import "PermissionsManager.h"
#import "Geometry.h"
#import "screenshot-Swift.h"

@interface TutorialPermissionsSlideView ()

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, UISwitch *> *switchesDict;

@end

@implementation TutorialPermissionsSlideView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        
        self.switchesDict = [NSMutableDictionary dictionary];
        
        self.titleLabel.text = @"Get Started";
        self.subtitleLabel.text = @"Turn on permissions for the best CRAZE experience";
        
        UIView *photosRow = [self permissionViewWithImageNamed:@"IconPhotos" text:@"Allow Photo Gallery Access" type:PermissionTypePhoto action:@selector(photosSwitchChanged:)];
        [photosRow.topAnchor constraintGreaterThanOrEqualToAnchor:self.contentView.topAnchor].active = YES;
        
        UIView *notificationRow = [self permissionViewWithImageNamed:@"IconNotifications" text:@"Enable Notifications" type:PermissionTypePush action:@selector(notificationsSwitchChanged:)];
        [notificationRow.heightAnchor constraintEqualToAnchor:photosRow.heightAnchor].active = YES;
        [notificationRow.topAnchor constraintGreaterThanOrEqualToAnchor:photosRow.bottomAnchor].active = YES;
        
        UIView *locationRow = [self permissionViewWithImageNamed:@"IconLocation" text:@"Allow Location Access" type:PermissionTypeLocation action:@selector(locationSwitchChanged:)];
        [locationRow.heightAnchor constraintEqualToAnchor:notificationRow.heightAnchor].active = YES;
        [locationRow.topAnchor constraintGreaterThanOrEqualToAnchor:notificationRow.bottomAnchor].active = YES;
        [locationRow.bottomAnchor constraintLessThanOrEqualToAnchor:self.contentView.bottomAnchor].active = YES;
        
        [self separatorFromAnchor:self.contentView.topAnchor toAnchor:photosRow.topAnchor];
        [self separatorFromAnchor:photosRow.layoutMarginsGuide.bottomAnchor toAnchor:notificationRow.topAnchor];
        [self separatorFromAnchor:notificationRow.layoutMarginsGuide.bottomAnchor toAnchor:locationRow.topAnchor];
        [self separatorFromAnchor:locationRow.bottomAnchor toAnchor:self.contentView.bottomAnchor];
    }
    return self;
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    if (self.window) {
        [self syncSwitchesState];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Layout

- (UIView *)permissionViewWithImageNamed:(NSString *)imageName text:(NSString *)text type:(PermissionType)type action:(SEL)action {
    BOOL hasPermission = [[PermissionsManager sharedPermissionsManager] hasPermissionForType:type];
    CGFloat p = [Geometry padding];
    
    UIView *view = [[UIView alloc] init];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    view.layoutMargins = UIEdgeInsetsMake(-p, 0.f, -p, 0.f);
    [self.contentView addSubview:view];
    [view.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor].active = YES;
    [view.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor].active = YES;
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.layoutMargins = UIEdgeInsetsMake(0.f, 0.f, 0.f, -p);
    [view addSubview:imageView];
    [imageView setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [imageView setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [imageView.topAnchor constraintEqualToAnchor:view.topAnchor].active = YES;
    [imageView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor].active = YES;
    [imageView.bottomAnchor constraintEqualToAnchor:view.bottomAnchor].active = YES;
    
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.numberOfLines = 0;
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    label.text = text;
    label.layoutMargins = UIEdgeInsetsMake(0.f, 0.f, 0.f, -p);
    [view addSubview:label];
    [label setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [label.topAnchor constraintEqualToAnchor:view.topAnchor].active = YES;
    [label.leadingAnchor constraintEqualToAnchor:imageView.layoutMarginsGuide.trailingAnchor].active = YES;
    [label.bottomAnchor constraintEqualToAnchor:view.bottomAnchor].active = YES;
    
    UISwitch *aSwitch = [[UISwitch alloc] init];
    [self updatePermission:hasPermission forSwitch:aSwitch];
    aSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    [aSwitch addTarget:self action:action forControlEvents:UIControlEventValueChanged];
    [view addSubview:aSwitch];
    [aSwitch.leadingAnchor constraintEqualToAnchor:label.layoutMarginsGuide.trailingAnchor].active = YES;
    [aSwitch.trailingAnchor constraintEqualToAnchor:view.trailingAnchor].active = YES;
    [aSwitch.centerYAnchor constraintEqualToAnchor:view.centerYAnchor].active = YES;
    self.switchesDict[@(type)] = aSwitch;
    
    return view;
}


#pragma mark - Switch

- (void)updatePermission:(BOOL)hasPermission forSwitch:(UISwitch *)aSwitch {
    aSwitch.userInteractionEnabled = !hasPermission;
    [aSwitch setOn:hasPermission animated:YES];
}

- (void)photosSwitchChanged:(UISwitch *)aSwitch {
    [self switchChanged:aSwitch forPermissionType:PermissionTypePhoto];
}

- (void)notificationsSwitchChanged:(UISwitch *)aSwitch {
    [self switchChanged:aSwitch forPermissionType:PermissionTypePush];
}

- (void)locationSwitchChanged:(UISwitch *)aSwitch {
    [self switchChanged:aSwitch forPermissionType:PermissionTypeLocation];
}

- (void)switchChanged:(UISwitch *)aSwitch forPermissionType:(PermissionType)permissionType {
    if ([aSwitch isOn]) {
        [[PermissionsManager sharedPermissionsManager] requestPermissionForType:permissionType openSettingsIfNeeded:YES response:^(BOOL granted) {
            [self updatePermission:granted forSwitch:aSwitch];
            if (permissionType == PermissionTypePhoto) {
                [AssetSyncModel.sharedInstance syncPhotos];
            }
        }];
    }
}

- (void)syncSwitchesState {
    [self.switchesDict enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, UISwitch * _Nonnull obj, BOOL * _Nonnull stop) {
        BOOL hasPermission = [[PermissionsManager sharedPermissionsManager] hasPermissionForType:[key integerValue]];
        [self updatePermission:hasPermission forSwitch:obj];
    }];
}

@end
