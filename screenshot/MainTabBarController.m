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

@interface MainTabBarController ()

@property (nonatomic, strong) ScreenshotsViewController *screenshotsViewController;

@end

@implementation MainTabBarController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        ScreenshotsViewController *viewController = [[ScreenshotsViewController alloc] init];
        viewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Screenshots" image:[UIImage imageNamed:@"TabBarScreens"] tag:0];
        self.screenshotsViewController = viewController;
        
        self.viewControllers = @[self.screenshotsViewController];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor cyanColor];
}

@end
