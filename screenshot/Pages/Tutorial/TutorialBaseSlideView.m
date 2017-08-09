//
//  TutorialBaseSlideView.m
//  screenshot
//
//  Created by Corey Werner on 8/9/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "TutorialBaseSlideView.h"
#import "Geometry.h"

@implementation TutorialBaseSlideView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _titleLabel = ({
            UILabel *label = [[UILabel alloc] init];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            label.textAlignment = NSTextAlignmentCenter;
            label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle1];
            label.numberOfLines = 0;
            label.layoutMargins = UIEdgeInsetsMake(0.f, 0.f, -[Geometry padding], 0.f);
            [self addSubview:label];
            [label.topAnchor constraintEqualToAnchor:self.layoutMarginsGuide.topAnchor].active = YES;
            [label.leadingAnchor constraintEqualToAnchor:self.layoutMarginsGuide.leadingAnchor].active = YES;
            [label.trailingAnchor constraintEqualToAnchor:self.layoutMarginsGuide.trailingAnchor].active = YES;
            label;
        });
        
        _subtitleLabel = ({
            UILabel *label = [[UILabel alloc] init];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            label.textAlignment = NSTextAlignmentCenter;
            label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle3];
            label.numberOfLines = 0;
            label.layoutMargins = UIEdgeInsetsMake(0.f, 0.f, -[Geometry padding], 0.f);
            [self addSubview:label];
            [label.topAnchor constraintEqualToAnchor:self.titleLabel.layoutMarginsGuide.bottomAnchor].active = YES;
            [label.leadingAnchor constraintEqualToAnchor:self.layoutMarginsGuide.leadingAnchor].active = YES;
            [label.trailingAnchor constraintEqualToAnchor:self.layoutMarginsGuide.trailingAnchor].active = YES;
            label;
        });
        
        _contentView = ({
            UIView *view = [[UIView alloc] init];
            view.backgroundColor = [UIColor yellowColor];
            view.translatesAutoresizingMaskIntoConstraints = NO;
            [self addSubview:view];
            [view.topAnchor constraintEqualToAnchor:self.subtitleLabel.layoutMarginsGuide.bottomAnchor].active = YES;
            [view.leadingAnchor constraintEqualToAnchor:self.layoutMarginsGuide.leadingAnchor].active = YES;
            [view.bottomAnchor constraintEqualToAnchor:self.layoutMarginsGuide.bottomAnchor].active = YES;
            [view.trailingAnchor constraintEqualToAnchor:self.layoutMarginsGuide.trailingAnchor].active = YES;
            view;
        });
    }
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    
    if (newSuperview) {
        CGFloat p = [Geometry padding];
        self.layoutMargins = UIEdgeInsetsMake(50.f, p, p, p);
    }
}

@end
