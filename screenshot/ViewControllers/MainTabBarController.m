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

@interface MainTabBarController () <UITabBarControllerDelegate> {
    BOOL _isObservingSettingsBadgeFont;
}

@property (nonatomic, strong) UINavigationController *favoritesNavigationController;
@property (nonatomic, strong) ScreenshotsNavigationController *screenshotsNavigationController;
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
        
        _favoritesNavigationController = ({
            UIImage *image = [UIImage imageNamed:@"TabBarHeart"];
            
            FavoritesViewController *viewController = [[FavoritesViewController alloc] init];
            viewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Favorites" image:image tag:0];
            
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
            navigationController.view.backgroundColor = [UIColor background];
            navigationController;
        });
        
        _screenshotsNavigationController = ({
            UIImage *image = [UIImage imageNamed:@"TabBarSnapshot"];
            
            ScreenshotsNavigationController *viewController = [[ScreenshotsNavigationController alloc] init];
            viewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Screenshots" image:image tag:1];
            viewController;
        });
        
        _settingsNavigationController = ({
            UIImage *image = [UIImage imageNamed:@"TabBarUser"];
            
            SettingsViewController *viewController = [[SettingsViewController alloc] init];
            viewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Settings" image:image tag:2];
            viewController.tabBarItem.badgeColor = [UIColor crazeRed];
            _settingsTabBarItem = viewController.tabBarItem;
            
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
            navigationController.view.backgroundColor = [UIColor background];
            navigationController;
        });
        
        self.viewControllers = @[self.screenshotsNavigationController, self.favoritesNavigationController, self.settingsNavigationController];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.updatePromptHandler = [[UpdatePromptHandler alloc] initWithContainerViewController:self];
    [self.updatePromptHandler start];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self refreshTabBarSettingsBadge];
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

- (void)dealloc {
    [self dismissTabBarSettingsBadge];
}


#pragma mark - Tab Bar

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    if (self.selectedViewController == self.settingsNavigationController) {
        [self.settingsNavigationController popToRootViewControllerAnimated:NO];
    }
    return YES;
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    NSString *tab;
    
    if (self.selectedViewController == self.favoritesNavigationController) {
        tab = @"Favorites";
        
    } else if (self.selectedViewController == self.screenshotsNavigationController) {
        tab = @"Screenshots";
        
    } else if (self.selectedViewController == self.settingsNavigationController) {
        tab = @"Settings";
    }
    
    if (tab) {
        [AnalyticsTrackers.standard track:@"Tab Bar tapped" properties:@{@"tab": tab}];
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

@end
