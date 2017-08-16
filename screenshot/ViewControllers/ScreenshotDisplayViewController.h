//
//  ScreenshotDisplayViewController.h
//  screenshot
//
//  Created by Corey Werner on 8/16/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "BaseViewController.h"

@interface ScreenshotDisplayViewController : BaseViewController

@property (nonatomic, copy) UIImage *image;
@property (nonatomic, strong, readonly) UIButton *closeButton;

@end