//
//  MainTabBarController.m
//  screenshot
//
//  Created by Corey Werner on 8/7/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "MainTabBarController.h"
#import "FavoritesViewController.h"
#import "ScreenshotsNavigationController.h"
#import "ScreenshotsViewController.h"
#import "SettingsViewController.h"

@interface MainTabBarController ()

@property (nonatomic, strong) UINavigationController *favoritesNavigationController;
@property (nonatomic, strong) ScreenshotsNavigationController *screenshotsNavigationController;
@property (nonatomic, strong) UINavigationController *settingsNavigationController;

@end

@implementation MainTabBarController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.favoritesNavigationController = ({
            UIImage *image = [UIImage imageNamed:@"TabBarHeart"];
            
            FavoritesViewController *viewController = [[FavoritesViewController alloc] init];
            viewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Favorites" image:image tag:0];
            
            [[UINavigationController alloc] initWithRootViewController:viewController];
        });
        
        self.screenshotsNavigationController = ({
            UIImage *image = [UIImage imageNamed:@"TabBarScreens"];
            
            ScreenshotsNavigationController *viewController = [[ScreenshotsNavigationController alloc] init];
            viewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Screenshots" image:image tag:1];
            viewController;
        });
        
        self.settingsNavigationController = ({
            UIImage *image = [UIImage imageNamed:@"TabBarGear"];
            
            SettingsViewController *viewController = [[SettingsViewController alloc] init];
            viewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Settings" image:image tag:2];
            
            [[UINavigationController alloc] initWithRootViewController:viewController];
        });
        
        self.viewControllers = @[self.screenshotsNavigationController, self.favoritesNavigationController, self.settingsNavigationController];
    }
    return self;
}

@end
