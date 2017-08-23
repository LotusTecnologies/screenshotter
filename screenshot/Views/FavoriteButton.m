//
//  FavoriteButton.m
//  screenshot
//
//  Created by Corey Werner on 8/8/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "FavoriteButton.h"

@implementation FavoriteButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UIImage *emptyImage = [UIImage imageNamed:@"FavoriteHeartEmpty"];
        UIImage *filledImage = [UIImage imageNamed:@"FavoriteHeartFilled"];
        
        [self setImage:emptyImage forState:UIControlStateNormal];
        [self setImage:filledImage forState:UIControlStateSelected];
        [self setImage:filledImage forState:UIControlStateSelected | UIControlStateHighlighted];
        
        self.contentEdgeInsets = UIEdgeInsetsMake(6.f, 6.f, 6.f, 6.f);
        
        [self addTarget:self action:@selector(touchUpInside) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)touchUpInside {
    self.selected = !self.selected;
}

@end
