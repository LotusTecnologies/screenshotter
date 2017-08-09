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
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"SlideScreenshot"]];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:imageView];
        [imageView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
        [imageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor].active = YES;
        [imageView.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.contentView.leadingAnchor].active = YES;
        [imageView.bottomAnchor constraintLessThanOrEqualToAnchor:self.contentView.bottomAnchor].active = YES;
        [imageView.trailingAnchor constraintLessThanOrEqualToAnchor:self.contentView.trailingAnchor].active = YES;
        [imageView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor].active = YES;
    }
    return self;
}

@end
