//
//  MainTabBarController.m
//  screenshot
//
//  Created by Corey Werner on 8/7/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "MainTabBarController.h"
#import "ScreenshotsViewController.h"
#import "screenshot-Swift.h"

@interface MainTabBarController () <UITabBarControllerDelegate, ScreenshotsNavigationControllerDelegate, SettingsViewControllerDelegate, ScreenshotDetectionProtocol> {
    BOOL _isObservingSettingsBadgeFont;
}

@property (nonatomic, strong) FavoritesNavigationController *favoritesNavigationController;
@property (nonatomic, strong) ScreenshotsNavigationController *screenshotsNavigationController;
@property (nonatomic, strong) DiscoverNavigationController *discoverNavigationController;
@property (nonatomic, strong) UINavigationController *settingsNavigationController;
@property (nonatomic, strong) UITabBarItem *settingsTabBarItem;
@property (nonatomic, strong) UpdatePromptHandler *updatePromptHandler;
@property (nonatomic) NSInteger discoverTabTag;

@end

@implementation MainTabBarController

NSString *const TabBarBadgeFontKey = @"view.badge.label.font";

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.delegate = self;
        
        _screenshotsNavigationController = ({
            UIImage *image = [UIImage imageNamed:@"TabBarScreenshot"];
            
            ScreenshotsNavigationController *navigationController = [[ScreenshotsNavigationController alloc] init];
            navigationController.screenshotsNavigationControllerDelegate = self;
            navigationController.title = navigationController.screenshotsViewController.title;
            navigationController.tabBarItem = [self tabBarItemWithTitle:navigationController.title image:image tag:0];
            navigationController;
        });
        
        _favoritesNavigationController = ({
            UIImage *image = [UIImage imageNamed:@"TabBarHeart"];
            
            FavoritesNavigationController *navigationController = [[FavoritesNavigationController alloc] init];
            navigationController.title = navigationController.favoritesViewController.title;
            navigationController.tabBarItem = [self tabBarItemWithTitle:navigationController.title image:image tag:1];
            navigationController;
        });
        
        _discoverNavigationController = ({
            self.discoverTabTag = 2;
            
            UIImage *image = [UIImage imageNamed:@"TabBarGlobe"];
            
            DiscoverNavigationController *navigationController = [[DiscoverNavigationController alloc] init];
            navigationController.title = navigationController.discoverScreenshotViewController.title;
            navigationController.tabBarItem = [self tabBarItemWithTitle:navigationController.title image:image tag:self.discoverTabTag];
            navigationController;
        });

        _settingsNavigationController = ({
            UIImage *image = [UIImage imageNamed:@"TabBarUser"];
            
            SettingsViewController *viewController = [[SettingsViewController alloc] init];
            viewController.delegate = self;
            
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
            navigationController.title = viewController.title;
            navigationController.view.backgroundColor = [UIColor background];
            navigationController.tabBarItem = [self tabBarItemWithTitle:navigationController.title image:image tag:3];
            navigationController.tabBarItem.badgeColor = [UIColor crazeRed];
            _settingsTabBarItem = navigationController.tabBarItem;
            navigationController;
        });
        
        self.viewControllers = @[self.screenshotsNavigationController,
                                 self.favoritesNavigationController,
                                 self.discoverNavigationController,
                                 self.settingsNavigationController
                                 ];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationUserDidTakeScreenshot:) name:UIApplicationUserDidTakeScreenshotNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationFetchedAppSettings:) name:[NotificationCenterKeys fetchedAppSettings] object:nil];
        
        [AssetSyncModel sharedInstance].screenshotDetectionDelegate = self;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self refreshTabBarSettingsBadge];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self presentUpdatePromptIfNeeded];
    [self presentChangelogAlertIfNeeded];
}

- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    
    if (self.view.window.safeAreaInsets.bottom > 0) {
        for (UIViewController *viewController in self.viewControllers) {
            CGFloat offset = 16.f;
            viewController.tabBarItem.imageInsets = UIEdgeInsetsMake(offset, 0.f, -offset, 0.f);
        }
    }
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    if (self.view.window) {
        [self refreshTabBarSettingsBadge];
    }
}

- (void)applicationUserDidTakeScreenshot:(NSNotification *)notification {
    if (self.view.window) {
        BOOL foundIntercomWindow = NO;
        
        for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
            if ([window isKindOfClass:NSClassFromString(@"ICMWindow")]) {
                foundIntercomWindow = YES;
                break;
            }
        }
        
        NSString *eventName = foundIntercomWindow ? @"Took Screenshot While Showing Intercom Window" : @"Took Screenshot";
        [AnalyticsTrackers.standard track:eventName properties:nil];
    }
}

- (void)applicationFetchedAppSettings:(NSNotification *)notification {
    if ([self isViewLoaded] && self.view.window) {
        [self presentUpdatePromptIfNeeded];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:TabBarBadgeFontKey]) {
        NSDictionary *badgeAttributes = @{NSFontAttributeName:[UIFont fontWithName:@"Optima-ExtraBlack" size:14.f]};
        
        // Remove the previous value so UIKit recognizes the update.
        [self.settingsTabBarItem setBadgeTextAttributes:nil forState:UIControlStateNormal];
        [self.settingsTabBarItem setBadgeTextAttributes:badgeAttributes forState:UIControlStateNormal];
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)dealloc {
    [self dismissTabBarSettingsBadge];
    
    [AssetSyncModel sharedInstance].screenshotDetectionDelegate = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Tab Bar

- (UITabBarItem *)tabBarItemWithTitle:(NSString *)title image:(UIImage *)image tag:(NSInteger)tag {
    CGFloat offset = 6.f;
    
    UITabBarItem *tabBarItem = [[UITabBarItem alloc] initWithTitle:title image:image tag:tag];
    tabBarItem.imageInsets = UIEdgeInsetsMake(offset, 0.f, -offset, 0.f);
    tabBarItem.titlePositionAdjustment = UIOffsetMake(0.f, self.tabBar.intrinsicContentSize.height * 2.f);
    return tabBarItem;
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    if (self.selectedViewController == self.settingsNavigationController) {
        [self.settingsNavigationController popToRootViewControllerAnimated:NO];
    }
    return YES;
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    NSString *tabTitle = self.selectedViewController.title;
    
    if (item.tag == self.discoverTabTag) {
        tabTitle = @"Matchsticks";
    }
    
    if (tabTitle) {
        [AnalyticsTrackers.standard track:@"Tab Bar tapped" properties:@{@"tab": tabTitle}];
    }
}

- (void)presentTabBarSettingsBadge {
    self.settingsTabBarItem.badgeValue = @"!";
    
    if (!_isObservingSettingsBadgeFont) {
        @try {
            _isObservingSettingsBadgeFont = YES;
            [self.settingsTabBarItem addObserver:self forKeyPath:TabBarBadgeFontKey options:NSKeyValueObservingOptionNew context:nil];
            
        } @catch (id anException) {
            _isObservingSettingsBadgeFont = NO;
        }
    }
}

- (void)dismissTabBarSettingsBadge {
    if (_isObservingSettingsBadgeFont) {
        _isObservingSettingsBadgeFont = NO;
        
        [self.settingsTabBarItem removeObserver:self forKeyPath:TabBarBadgeFontKey context:nil];
    }
    
    self.settingsTabBarItem.badgeValue = nil;
}

- (void)refreshTabBarSettingsBadge {
    BOOL hasPhotoPermissions = [[PermissionsManager shared] _hasPhotoPermission];
    BOOL hasPushPermissions = [[PermissionsManager shared] _hasPushPermission];
    
    if (!hasPhotoPermissions || !hasPushPermissions) {
        [self presentTabBarSettingsBadge];
        
    } else {
        [self dismissTabBarSettingsBadge];
    }
}


#pragma mark - Screenshots

- (void)screenshotsNavigationControllerDidGrantPushPermissions:(ScreenshotsNavigationController *)navigationController {
    [self refreshTabBarSettingsBadge];
}


#pragma mark - Settings View Controller

- (void)settingsViewControllerDidGrantPermission:(SettingsViewController *)viewController {
    [self refreshTabBarSettingsBadge];
}


#pragma mark - Foreground Screenshots

- (void)foregroundScreenshotTakenWithAssetId:(NSString *)assetId {
    if (self.selectedViewController != self.screenshotsNavigationController) {
        [[NotificationManager shared] presentForegroundScreenshotWithAssetId:assetId action:^{
            self.selectedViewController = self.screenshotsNavigationController;
        }];
    }
}

- (void)backgroundScreenshotsWereTakenWithAssetIds:(NSSet<NSString *> *)assetIds {
    [self.screenshotsNavigationController.screenshotsViewController presentNotificationCellWithAssetId:[assetIds anyObject]];
}


#pragma mark - Update Prompt

- (void)presentUpdatePromptIfNeeded {
    if (!self.updatePromptHandler) {
        self.updatePromptHandler = [[UpdatePromptHandler alloc] init];
        [self.updatePromptHandler presentUpdatePromptIfNeeded];
    }
}

#pragma mark - Changelog Alerts

- (void)presentChangelogAlertIfNeeded {
    [ChangelogAlertController presentIfNeededInViewController:self];
}

@end
