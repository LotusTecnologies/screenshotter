//
//  TutorialBaseSlideView.h
//  screenshot
//
//  Created by Corey Werner on 8/9/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "HelperView.h"

@interface TutorialBaseSlideView : HelperView

// TODO: make into a protocol
- (void)didEnterSlide;
- (void)willLeaveSlide;

@end
