//
//  Geometry.m
//  screenshot
//
//  Created by Corey Werner on 8/8/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "Geometry.h"

@implementation Geometry

+ (CGFloat)padding {
    return 16.f;
}

+ (CGFloat)extendedPadding {
    return 40.f;
}

+ (CGFloat)halfPoint {
    return [UIScreen mainScreen].scale > 1.0f ? 0.5f : 1.0f;
}

@end
