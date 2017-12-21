//
//  ScreenshotDisplayNavigationController.h
//  screenshot
//
//  Created by Corey Werner on 8/22/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ScreenshotDisplayViewController.h"

@interface ScreenshotDisplayNavigationController : UINavigationController

@property (nonatomic, strong, readonly) ScreenshotDisplayViewController *screenshotDisplayViewController;

@end
