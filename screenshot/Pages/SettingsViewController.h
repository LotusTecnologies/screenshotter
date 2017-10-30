//
//  SettingsViewController.h
//  screenshot
//
//  Created by Corey Werner on 8/8/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "BaseViewController.h"

@class SettingsViewController;

@protocol SettingsViewControllerDelegate
@required

- (void)settingsViewControllerDidGrantPermission:(SettingsViewController *)viewController;

@end

@interface SettingsViewController : BaseViewController

@property (nonatomic, weak) id<SettingsViewControllerDelegate> delegate;

@end
