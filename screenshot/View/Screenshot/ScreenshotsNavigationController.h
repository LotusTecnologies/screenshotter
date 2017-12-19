//
//  ScreenshotsNavigationController.h
//  screenshot
//
//  Created by Corey Werner on 8/8/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ScreenshotsViewController.h"

@class ScreenshotsNavigationController;

@protocol ScreenshotsNavigationControllerDelegate

- (void)screenshotsNavigationControllerDidGrantPushPermissions:(ScreenshotsNavigationController *)navigationController;

@end

@interface ScreenshotsNavigationController : UINavigationController

@property (nonatomic, weak) id<ScreenshotsNavigationControllerDelegate> screenshotsNavigationControllerDelegate;
@property (nonatomic, strong, readonly) ScreenshotsViewController *screenshotsViewController;

- (void)presentPickerViewController;

@end
