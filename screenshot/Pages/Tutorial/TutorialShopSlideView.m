//
//  TutorialShopSlideView.m
//  screenshot
//
//  Created by Corey Werner on 8/9/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "TutorialShopSlideView.h"

@implementation TutorialShopSlideView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.titleLabel.text = @"Shop The Photo";
        self.subtitleLabel.text = @"Every screenshot you take is shoppable on CRAZE!";
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"SlideShop"]];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:imageView];
        [imageView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
        [imageView.topAnchor constraintGreaterThanOrEqualToAnchor:self.contentView.topAnchor].active = YES;
        [imageView.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.contentView.leadingAnchor].active = YES;
        [imageView.bottomAnchor constraintLessThanOrEqualToAnchor:self.contentView.bottomAnchor].active = YES;
        [imageView.trailingAnchor constraintLessThanOrEqualToAnchor:self.contentView.trailingAnchor].active = YES;
        [imageView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor].active = YES;
        [NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterY multiplier:0.8f constant:0.f].active = YES;
    }
    return self;
}

@end
