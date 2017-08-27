//
//  Button.m
//  screenshot
//
//  Created by Corey Werner on 8/24/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "Button.h"
#import "UIColor+Appearance.h"

@implementation Button

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor crazeRedColor];
        self.contentEdgeInsets = UIEdgeInsetsMake(16.f, 16.f, 16.f, 16.f);
        self.layer.cornerRadius = 9.f;
    }
    return self;
}

- (CGSize)intrinsicContentSize {
    CGSize size = [super intrinsicContentSize];
    size.width = MAX(size.width, 160.f);
    return size;
}

@end
