//
//  MainTabBarController.m
//  screenshot
//
//  Created by Corey Werner on 8/7/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "MainTabBarController.h"
#import "FavoritesViewController.h"
#import "ScreenshotsViewController.h"
#import "SettingsViewController.h"
#import "screenshot-Swift.h"

@interface MainTabBarController () <UITabBarControllerDelegate, ScreenshotsNavigationControllerDelegate> {
    BOOL _isObservingSettingsBadgeFont;
}

@property (nonatomic, strong) id didTakeScreenshotObserver;

@property (nonatomic, strong) UINavigationController *favoritesNavigationController;
@property (nonatomic, strong) ScreenshotsNavigationController *screenshotsNavigationController;
@property (nonatomic, strong) UINavigationController *discoverNavigationController;
@property (nonatomic, strong) UINavigationController *settingsNavigationController;
@property (nonatomic, strong) UITabBarItem *settingsTabBarItem;
@property (nonatomic, strong) UpdatePromptHandler *updatePromptHandler;

@end

@implementation MainTabBarController

NSString *const TabBarBadgeFontKey = @"view.badge.label.font";

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.delegate = self;
        
        _screenshotsNavigationController = ({
            UIImage *image = [UIImage imageNamed:@"TabBarSnapshot"];
            
            ScreenshotsNavigationController *navigationController = [[ScreenshotsNavigationController alloc] init];
            navigationController.title = navigationController.screenshotsViewController.title;
            navigationController.delegate = self;
            navigationController.tabBarItem = [[UITabBarItem alloc] initWithTitle:navigationController.title image:image tag:0];
            navigationController;
        });
        
        _favoritesNavigationController = ({
            UIImage *image = [UIImage imageNamed:@"TabBarHeart"];
            
            FavoritesViewController *viewController = [[FavoritesViewController alloc] init];
            
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
            navigationController.title = viewController.title;
            navigationController.view.backgroundColor = [UIColor background];
            navigationController.tabBarItem = [[UITabBarItem alloc] initWithTitle:navigationController.title image:image tag:1];
            navigationController;
        });
        
        _discoverNavigationController = ({
            UIImage *image = [UIImage imageNamed:@"TabBarGlobe"];
            
            DiscoverWebViewController *viewController = [[DiscoverWebViewController alloc] init];
            
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
            navigationController.title = viewController.title;
            navigationController.view.backgroundColor = [UIColor background];
            navigationController.tabBarItem = [[UITabBarItem alloc] initWithTitle:navigationController.title image:image tag:2];
            navigationController;
        });

        _settingsNavigationController = ({
            UIImage *image = [UIImage imageNamed:@"TabBarUser"];
            
            SettingsViewController *viewController = [[SettingsViewController alloc] init];
            
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
            navigationController.title = viewController.title;
            navigationController.view.backgroundColor = [UIColor background];
            navigationController.tabBarItem = [[UITabBarItem alloc] initWithTitle:navigationController.title image:image tag:3];
            navigationController.tabBarItem.badgeColor = [UIColor crazeRed];
            _settingsTabBarItem = navigationController.tabBarItem;
            navigationController;
        });
        
        self.viewControllers = @[self.screenshotsNavigationController,
                                 self.favoritesNavigationController,
                                 self.discoverNavigationController,
                                 self.settingsNavigationController
                                 ];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [self dismissTabBarSettingsBadge];
    
    self.screenshotsNavigationController.delegate = nil;

    if (self.didTakeScreenshotObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.didTakeScreenshotObserver];
        self.didTakeScreenshotObserver = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.didTakeScreenshotObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationUserDidTakeScreenshotNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        BOOL foundIntercomWindow = NO;
        
        NSArray<UIWindow *> *windows = [[UIApplication sharedApplication] windows];
        for (UIWindow *window in windows) {
            if ([window isKindOfClass:NSClassFromString(@"ICMWindow")]) {
                foundIntercomWindow = YES;
                break;
            }
        }
        
        NSString *eventName = foundIntercomWindow ? @"Took Screenshot While Showing Intercom Window" : @"Took Screenshot";
        [AnalyticsTrackers.standard track:eventName properties:nil];
    }];
    
    self.updatePromptHandler = [[UpdatePromptHandler alloc] initWithContainerViewController:self];
    [self.updatePromptHandler start];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self refreshTabBarSettingsBadge];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self attemptPresentNotification];
}

- (void)applicationWillEnterForeground:(NSNotification *)notification {
    if (self.view.window) {
        [self attemptPresentNotification];
    }
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    if (self.view.window) {
        [self refreshTabBarSettingsBadge];
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

#pragma mark - Tab Bar

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    if (self.selectedViewController == self.settingsNavigationController) {
        [self.settingsNavigationController popToRootViewControllerAnimated:NO];
    }
    return YES;
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    NSString *tabTitle = self.selectedViewController.title;
    
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
    BOOL hasPhotoPermissions = [[PermissionsManager sharedPermissionsManager] hasPermissionForType:PermissionTypePhoto];
    BOOL hasPushPermissions = [[PermissionsManager sharedPermissionsManager] hasPermissionForType:PermissionTypePush];
    
    if (!hasPhotoPermissions || !hasPushPermissions) {
        [self presentTabBarSettingsBadge];
        
    } else {
        [self dismissTabBarSettingsBadge];
    }
}


#pragma mark - Screenshot View Controller

- (void)screenshotsNavigationControllerDidGrantPushPermissions:(ScreenshotsNavigationController *)navigationController {
    [self refreshTabBarSettingsBadge];
}


#pragma mark - Notifications

- (void)attemptPresentNotification {
    NSInteger newScreenshotsCount = [[AccumulatorModel sharedInstance] getNewScreenshotsCount];
    [[AccumulatorModel sharedInstance] resetNewScreenshotsCount];
    
    if (newScreenshotsCount > 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (newScreenshotsCount == 1) {
                [[NotificationManager shared] presentScreenshotWith:^{
                    [[AssetSyncModel sharedInstance] refetchLastScreenshot];
                }];
                
            } else {
                [[NotificationManager shared] presentScreenshotWithCount:newScreenshotsCount userTapped:^{
                    [self.screenshotsNavigationController presentPickerViewController];
                }];
            }
        });
    }
}

@end
