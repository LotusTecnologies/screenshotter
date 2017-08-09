//
//  TutorialScreenshotSlideView.m
//  screenshot
//
//  Created by Corey Werner on 8/9/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "TutorialScreenshotSlideView.h"

@implementation TutorialScreenshotSlideView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.titleLabel.text = @"Screenshot Looks You Like";
        self.subtitleLabel.text = @"To take a screenshot press the power and home buttons at the same time";
    }
    return self;
}

@end
