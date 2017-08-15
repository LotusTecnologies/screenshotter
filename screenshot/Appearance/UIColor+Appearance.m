//
//  UIColor+Appearance.m
//  screenshot
//
//  Created by Corey Werner on 8/8/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "UIColor+Appearance.h"

@implementation UIColor (Appearance)

+ (UIColor *)backgroundColor {
    return [UIColor colorWithWhite:244.f/255.f alpha:1.f];
}

+ (UIColor *)crazeRedColor {
    return [UIColor colorWithRed:237.f/255.f green:20.f/255.f blue:90.f/255.f alpha:1.f];
}

+ (UIColor *)softTextColor {
    return [UIColor colorWithWhite:155.f/255.f alpha:1.f];
}

@end
