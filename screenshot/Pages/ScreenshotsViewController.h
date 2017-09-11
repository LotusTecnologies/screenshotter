//
//  ScreenshotsViewController.h
//  screenshot
//
//  Created by Corey Werner on 8/7/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "BaseViewController.h"

@class ScreenshotsViewController;
@class Screenshot;

@protocol ScreenshotsViewControllerDelegate <NSObject>
@required

- (void)screenshotsViewController:(ScreenshotsViewController *)viewController didSelectItemAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface ScreenshotsViewController : BaseViewController

@property (nonatomic, weak) id<ScreenshotsViewControllerDelegate> delegate;

- (Screenshot *)screenshotAtIndex:(NSInteger)index;

- (void)scrollTopTop;

@end
