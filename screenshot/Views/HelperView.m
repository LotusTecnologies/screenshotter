//
//  HelperView.m
//  screenshot
//
//  Created by Corey Werner on 8/16/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "HelperView.h"
#import "Geometry.h"
#import "screenshot-Swift.h"

@implementation HelperView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _titleLabel = ({
            UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle1];
            UIFontDescriptor *fontDescriptor = [font.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
            
            UILabel *label = [[UILabel alloc] init];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            label.textAlignment = NSTextAlignmentCenter;
            label.textColor = [UIColor gray3];
            label.font = [UIFont fontWithDescriptor:fontDescriptor size:0.f];
            label.numberOfLines = 0;
            label.layoutMargins = UIEdgeInsetsMake(0.f, 0.f, -[Geometry padding], 0.f);
            [self addSubview:label];
            [label setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
            [label.topAnchor constraintEqualToAnchor:self.layoutMarginsGuide.topAnchor].active = YES;
            [label.leadingAnchor constraintEqualToAnchor:self.layoutMarginsGuide.leadingAnchor].active = YES;
            [label.trailingAnchor constraintEqualToAnchor:self.layoutMarginsGuide.trailingAnchor].active = YES;
            label;
        });
        
        _subtitleLabel = ({
            UILabel *label = [[UILabel alloc] init];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            label.textAlignment = NSTextAlignmentCenter;
            label.textColor = [UIColor gray3];
            label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle3];
            label.numberOfLines = 0;
            label.layoutMargins = UIEdgeInsetsMake(0.f, 0.f, -[Geometry padding], 0.f);
            [self addSubview:label];
            [label setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
            [label.topAnchor constraintEqualToAnchor:self.titleLabel.layoutMarginsGuide.bottomAnchor].active = YES;
            [label.leadingAnchor constraintEqualToAnchor:self.layoutMarginsGuide.leadingAnchor].active = YES;
            [label.trailingAnchor constraintEqualToAnchor:self.layoutMarginsGuide.trailingAnchor].active = YES;
            label;
        });
        
        _contentView = ({
            UIView *view = [[UIView alloc] init];
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

@end
