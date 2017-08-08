//
//  ScreenshotCollectionViewCell.h
//  screenshot
//
//  Created by Corey Werner on 8/7/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ScreenshotCollectionViewCell;

@protocol ScreenshotCollectionViewCellDelegate <NSObject>
@required

- (void)screenshotCollectionViewCellDidTapShare:(ScreenshotCollectionViewCell *)cell;
- (void)screenshotCollectionViewCellDidTapTrash:(ScreenshotCollectionViewCell *)cell;

@end

@interface ScreenshotCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) id<ScreenshotsViewControllerDelegate> delegate;

@property (nonatomic, copy) UIImage *image;

@end
