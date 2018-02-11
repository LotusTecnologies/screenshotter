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

@interface ShoppablesCollectionView : UICollectionView

@property (nonatomic, weak) ShoppablesToolbar* delegate;

@end

@interface ShoppablesToolbar : UIToolbar <ShoppablesControllerProtocol, UICollectionViewDelegate, UICollectionViewDataSource>


+ (UIEdgeInsets)preservedCollectionViewContentInset;
- (void)repositionShoppables;

@property (nonatomic, weak) id<ShoppablesToolbarDelegate> delegate;
@property (nonatomic) BOOL didViewControllerAppear;
@property (nonatomic) BOOL needsToSelectFirstShoppable;

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, copy) UIImage *screenshotImage;


@end
