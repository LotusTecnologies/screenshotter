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
#import "AnalyticsManager.h"
#import "UIColor+Appearance.h"
#import "Button.h"

@interface TutorialPermissionsSlideView ()

@property (nonatomic, strong) Button *button;
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
        
        CGFloat p = [Geometry padding];
        
        UIView *photosRow = [self permissionViewWithImageNamed:@"TutorialPhotosIcon" text:@"Allow Photo Gallery Access" type:PermissionTypePhoto action:@selector(photosSwitchChanged:)];
        [photosRow.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:p].active = YES;
        
        UILabel *photosLabel = [[UILabel alloc] init];
        photosLabel.translatesAutoresizingMaskIntoConstraints = NO;
        photosLabel.numberOfLines = 0;
        photosLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        photosLabel.textColor = [UIColor softTextColor];
        photosLabel.text = @"CRAZE needs access to your photo gallery to turn your screenshots into shoppable experiences";
        [self.contentView addSubview:photosLabel];
        [photosLabel.topAnchor constraintEqualToAnchor:photosRow.bottomAnchor constant:p].active = YES;
        [photosLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor].active = YES;
        [photosLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor].active = YES;
        
        UIView *notificationRow = [self permissionViewWithImageNamed:@"TutorialNotificationsIcon" text:@"Enable Notifications" type:PermissionTypePush action:@selector(notificationsSwitchChanged:)];
        [notificationRow.topAnchor constraintEqualToAnchor:photosLabel.bottomAnchor constant:p * 2.f].active = YES;
        
        UIImageView *arrowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"TutorialPermissionsArrow"]];
        arrowImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:arrowImageView];
        [arrowImageView.topAnchor constraintEqualToAnchor:notificationRow.bottomAnchor].active = YES;
        [arrowImageView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor].active = YES;
        
        UILabel *notificationLabel = [[UILabel alloc] init];
        notificationLabel.translatesAutoresizingMaskIntoConstraints = NO;
        notificationLabel.numberOfLines = 0;
        notificationLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        notificationLabel.textColor = [UIColor softTextColor];
        notificationLabel.text = @"We’ll send you a notification when your screenshot is ready to be shopped";
        [self.contentView addSubview:notificationLabel];
        [notificationLabel.topAnchor constraintEqualToAnchor:notificationRow.bottomAnchor constant:p].active = YES;
        [notificationLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor].active = YES;
        [notificationLabel.trailingAnchor constraintEqualToAnchor:arrowImageView.leadingAnchor].active = YES;
        
        UILabel *arrowLabel = [[UILabel alloc] init];
        arrowLabel.translatesAutoresizingMaskIntoConstraints = NO;
        arrowLabel.text = @"Tap\nme!";
        arrowLabel.numberOfLines = 0;
        arrowLabel.textAlignment = NSTextAlignmentCenter;
        arrowLabel.textColor = [UIColor crazeRedColor];
        arrowLabel.transform = CGAffineTransformMakeRotation(M_PI_4);
        [self.contentView addSubview:arrowLabel];
        [arrowLabel.topAnchor constraintEqualToAnchor:arrowImageView.bottomAnchor constant:-2.f].active = YES;
        [arrowLabel.trailingAnchor constraintEqualToAnchor:arrowImageView.leadingAnchor constant:2.f].active = YES;
        
        self.button = ({
            Button *button = [Button buttonWithType:UIButtonTypeCustom];
            button.translatesAutoresizingMaskIntoConstraints = NO;
            [button setTitle:@"Next" forState:UIControlStateNormal];
            [button addTarget:self action:@selector(slideCompleted) forControlEvents:UIControlEventTouchUpInside];
            button.alpha = [self shouldButtonBeVisible];
            [self.contentView addSubview:button];
            [button setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
            [button setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
            [button.topAnchor constraintGreaterThanOrEqualToAnchor:notificationLabel.bottomAnchor constant:p].active = YES;
            [button.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.contentView.leadingAnchor].active = YES;
            
            NSLayoutConstraint *constraint = [button.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-50.f];
            constraint.priority = UILayoutPriorityDefaultHigh;
            constraint.active = YES;
            
            [button.trailingAnchor constraintLessThanOrEqualToAnchor:self.contentView.trailingAnchor].active = YES;
            [button.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor].active = YES;
            button;
        });
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
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle3];
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

- (BOOL)shouldButtonBeVisible {
    return [[PermissionsManager sharedPermissionsManager] permissionStatusForType:PermissionTypePhoto] != PermissionStatusNotDetermined;
}

- (void)syncButtonVisibility {
    BOOL shouldButtonBeVisible = [self shouldButtonBeVisible];
    
    if (self.button.alpha != shouldButtonBeVisible) {
        [UIView animateWithDuration:.3f delay:0.f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.button.alpha = shouldButtonBeVisible;
            
        } completion:nil];
    }
}


#pragma mark - Permissions

- (void)updatePermission:(BOOL)hasPermission forSwitch:(UISwitch *)aSwitch {
    aSwitch.enabled = !hasPermission;
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
            
            NSString *event;
            NSString *grantedString = granted ? @"yes" : @"no";
            
            switch (permissionType) {
                case PermissionTypePhoto:
                    [[AssetSyncModel sharedInstance] syncPhotos];
                    [self syncButtonVisibility];
                    
                    if (!granted) {
                        [self.delegate tutorialPermissionsSlideViewDidDenyPhotosPermission:self];
                    }
                    
                    event = @"Granted photo permissions";
                    break;
                    
                case PermissionTypePush:
                    event = @"Granted push permissions";
                    break;
                    
                case PermissionTypeLocation:
                    event = @"Granted location permissions";
                    break;
            }
            
            [AnalyticsManager track:event properties:@{@"granted": grantedString}];
            
            if ([self didDetermineAllPermissions]) {
                [self.delegate tutorialPermissionsSlideViewDidComplete:self];
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

- (BOOL)didDetermineAllPermissions {
    PermissionStatus photoStatus = [[PermissionsManager sharedPermissionsManager] permissionStatusForType:PermissionTypePhoto];
    PermissionStatus pushStatus = [[PermissionsManager sharedPermissionsManager] permissionStatusForType:PermissionTypePush];
    
    return photoStatus != PermissionStatusNotDetermined && pushStatus != PermissionStatusNotDetermined;
}


#pragma mark - Action

- (void)slideCompleted {
    [self.delegate tutorialPermissionsSlideViewDidComplete:self];
}


#pragma mark - Alert

- (UIAlertController *)determinePushAlertController {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Continue Without Notifications?" message:@"If you don't enable notifications we won't be able to let you know when you have new shoppable screenshots!" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Enable" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[PermissionsManager sharedPermissionsManager] requestPermissionForType:PermissionTypePush openSettingsIfNeeded:YES response:^(BOOL granted) {
            if (granted) {
                [self syncSwitchesState];
            }
            
            // Create delay for a natural feel from the switch animating
            // to the slide transitioning.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.delegate tutorialPermissionsSlideViewDidComplete:self];
            });
        }];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Not Now" style:UIAlertActionStyleCancel handler:nil]];
    return alertController;
}

@end
