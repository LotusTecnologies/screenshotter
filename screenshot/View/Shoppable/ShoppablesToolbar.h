//
//  ShoppablesToolbar.h
//  screenshot
//
//  Created by Corey Werner on 8/13/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ShoppablesToolbar;
@class Shoppable;
@protocol ShoppablesControllerProtocol;

@protocol ShoppablesToolbarDelegate <UIToolbarDelegate>
@required

- (void)shoppablesToolbarDidChange:(ShoppablesToolbar *)toolbar;
- (void)shoppablesToolbar:(ShoppablesToolbar *)toolbar didSelectShoppableAtIndex:(NSUInteger)index;

@end

@interface ShoppablesToolbar : UIToolbar <ShoppablesControllerProtocol>

@property (nonatomic, weak) id<ShoppablesToolbarDelegate> delegate;
@property (nonatomic) BOOL didViewControllerAppear;

@property (nonatomic, strong, readonly) UICollectionView *collectionView;
@property (nonatomic, copy) UIImage *screenshotImage;

- (void)selectFirstShoppable;
- (NSInteger)selectedShoppableIndex;

@end
