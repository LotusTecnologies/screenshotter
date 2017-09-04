//
//  TutorialBaseSlideView.h
//  screenshot
//
//  Created by Corey Werner on 8/9/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "HelperView.h"

@interface TutorialBaseSlideView : HelperView

- (void)didEnterSlide;
- (void)willLeaveSlide;

- (UIView *)flexibleSpaceFromAnchor:(NSLayoutAnchor<NSLayoutYAxisAnchor *> *)fromAnchor toAnchor:(NSLayoutAnchor<NSLayoutYAxisAnchor *> *)toAnchor;

@end
