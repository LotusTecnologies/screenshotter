//
//  MainTabBarController.m
//  screenshot
//
//  Created by Corey Werner on 8/7/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "MainTabBarController.h"
#import "ScreenShotsViewController.h"

@interface MainTabBarController ()

@property (nonatomic, strong) ScreenShotsViewController *screenShotsViewController;

@end

@implementation MainTabBarController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        ScreenShotsViewController *viewController = [[ScreenShotsViewController alloc] init];
        viewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Screen Shots" image:nil tag:0];
        self.screenShotsViewController = viewController;
        
        self.viewControllers = @[self.screenShotsViewController];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor cyanColor];
}

@end
