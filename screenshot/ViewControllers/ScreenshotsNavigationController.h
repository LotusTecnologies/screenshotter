//
//  ScreenshotsNavigationController.h
//  screenshot
//
//  Created by Corey Werner on 8/8/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ScreenshotsViewController.h"

@interface ScreenshotsNavigationController : UINavigationController

@property (nonatomic, strong, readonly) ScreenshotsViewController *screenshotsViewController;

- (void)presentPickerViewController;

@end
