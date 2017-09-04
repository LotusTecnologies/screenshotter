//
//  TutorialWelcomeSlideView.m
//  screenshot
//
//  Created by Corey Werner on 8/24/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "TutorialWelcomeSlideView.h"
#import "UIColor+Appearance.h"
#import "screenshot-Swift.h"

@implementation TutorialWelcomeSlideView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.titleLabel.attributedText = ({
            NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
            attachment.image = [UIImage imageNamed:@"Logo36h"];
            
            CGRect rect = attachment.bounds;
            rect.origin.y = -3.f;
            rect.size = attachment.image.size;
            attachment.bounds = rect;
            
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@"Welcome to "];
            [attributedString appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
            attributedString;
        });
        
        self.subtitleLabel.text = @"Any fashion picture you screenshot becomes shoppable in the app";
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"TutorialWelcomeGraphic"]];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:imageView];
        [imageView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
        [imageView.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.contentView.leadingAnchor].active = YES;
        [imageView.trailingAnchor constraintLessThanOrEqualToAnchor:self.contentView.trailingAnchor].active = YES;
        [imageView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor].active = YES;
        
        [self flexibleSpaceFromAnchor:self.contentView.topAnchor toAnchor:imageView.topAnchor];
        
        Button *button = [Button buttonWithType:UIButtonTypeCustom];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        [button setTitle:@"Next" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(slideCompleted) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:button];
        [button setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [button setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
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
