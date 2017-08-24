//
//  TutorialWelcomeSlideView.m
//  screenshot
//
//  Created by Corey Werner on 8/24/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "TutorialWelcomeSlideView.h"
#import "UIColor+Appearance.h"

@implementation TutorialWelcomeSlideView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.titleLabel.text = @"Welcome to CRAZE"; // TODO: use craze logo
        self.subtitleLabel.text = @"Any picture you screenshot becomes shoppable in the app";
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"TutorialWelcomeGraphic"]];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:imageView];
        [imageView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
        [imageView.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.contentView.leadingAnchor].active = YES;
        [imageView.trailingAnchor constraintLessThanOrEqualToAnchor:self.contentView.trailingAnchor].active = YES;
        [imageView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor].active = YES;
        
        [self flexibleSpaceFromAnchor:self.contentView.topAnchor toAnchor:imageView.topAnchor];
        
        // TODO: turn into class
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        button.backgroundColor = [UIColor crazeRedColor];
        button.contentEdgeInsets = UIEdgeInsetsMake(16.f, 16.f, 16.f, 16.f);
        [button setTitle:@"Next" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(slideCompleted) forControlEvents:UIControlEventTouchUpInside];
        button.layer.cornerRadius = 9.f;
        [self.contentView addSubview:button];
        [button setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [button.widthAnchor constraintGreaterThanOrEqualToConstant:160.f].active = YES;
        [button.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.contentView.leadingAnchor].active = YES;
        [button.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-50.f].active = YES;
        [button.trailingAnchor constraintLessThanOrEqualToAnchor:self.contentView.trailingAnchor].active = YES;
        [button.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor].active = YES;
        
        [self flexibleSpaceFromAnchor:imageView.bottomAnchor toAnchor:button.topAnchor];
    }
    return self;
}

- (void)slideCompleted {
    [self.delegate tutorialWelcomeSlideViewDidComplete:self];
}

@end
