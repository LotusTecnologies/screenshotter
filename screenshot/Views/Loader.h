//
//  Loader.h
//  screenshot
//
//  Created by Corey Werner on 8/15/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, LoaderAnimation) {
    LoaderAnimationSpin,
    LoaderAnimationPoseThenSpin
};

@interface Loader : UIView

- (void)startAnimation:(LoaderAnimation)loaderAnimation;
- (void)stopAnimation;
- (BOOL)isAnimating;

@end
