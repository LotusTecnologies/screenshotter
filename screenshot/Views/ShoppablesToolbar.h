//
//  ShoppablesToolbar.h
//  screenshot
//
//  Created by Corey Werner on 8/13/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ShoppablesToolbar;
@class Screenshot, Shoppable;

@protocol ShoppablesToolbarDelegate <UIToolbarDelegate>
@required

- (void)shoppablesToolbar:(ShoppablesToolbar *)toolbar didSelectShoppableAtIndex:(NSUInteger)index;

@end

@interface ShoppablesToolbar : UIToolbar

@property (nonatomic, weak) id<ShoppablesToolbarDelegate> delegate;

- (void)insertShoppables:(NSArray<Shoppable *> *)shoppables withScreenshot:(Screenshot *)screenshot;

@end
