//
//  MainTabBarController.h
//  screenshot
//
//  Created by Corey Werner on 8/7/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ScreenshotsNavigationController.h"

@interface MainTabBarController : UITabBarController

@property (nonatomic, strong, readonly) UINavigationController *favoritesNavigationController;
@property (nonatomic, strong, readonly) ScreenshotsNavigationController *screenshotsNavigationController;
@property (nonatomic, strong, readonly) UINavigationController *settingsNavigationController;

@end
