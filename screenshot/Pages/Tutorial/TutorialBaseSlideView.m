//
//  TutorialBaseSlideView.m
//  screenshot
//
//  Created by Corey Werner on 8/9/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "TutorialBaseSlideView.h"

@interface TutorialBaseSlideView ()

@property (nonatomic, strong) UIView *separatorView;

@end

@implementation TutorialBaseSlideView

- (UIView *)flexibleSpaceFromAnchor:(NSLayoutAnchor<NSLayoutYAxisAnchor *> *)fromAnchor toAnchor:(NSLayoutAnchor<NSLayoutYAxisAnchor *> *)toAnchor {
    UIView *view = [[UIView alloc] init];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:view];
    [view setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
    [view setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
    [view.topAnchor constraintEqualToAnchor:fromAnchor].active = YES;
    [view.bottomAnchor constraintEqualToAnchor:toAnchor].active = YES;
    
    if (self.separatorView) {
        [view.heightAnchor constraintEqualToAnchor:self.separatorView.heightAnchor].active = YES;
        
    } else {
        self.separatorView = view;
    }
    
    return view;
}

@end
