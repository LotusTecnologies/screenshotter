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
- (void)screenshotsViewControllerDeletedLastScreenshot:(ScreenshotsViewController *)viewController;
- (void)screenshotsViewControllerWantsToPresentPicker:(ScreenshotsViewController *)viewController;

@end

@interface ScreenshotsViewController : BaseViewController

@property (nonatomic, weak) id<ScreenshotsViewControllerDelegate> delegate;

- (Screenshot *)screenshotAtIndex:(NSInteger)index;

- (void)scrollTopTop;

- (void)presentNotificationCellWithAssetId:(NSString *)assetId;
- (void)dismissNotificationCell;

@end
