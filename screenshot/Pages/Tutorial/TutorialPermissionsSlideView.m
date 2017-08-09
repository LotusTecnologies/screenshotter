//
//  TutorialPermissionsSlideView.m
//  screenshot
//
//  Created by Corey Werner on 8/9/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "TutorialPermissionsSlideView.h"

@implementation TutorialPermissionsSlideView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.titleLabel.text = @"Get Started";
        self.subtitleLabel.text = @"Turn on permissions for the best CRAZE experience";
    }
    return self;
}

@end
