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
    }
    return self;
}

@end
