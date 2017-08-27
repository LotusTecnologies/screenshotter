//
//  UIDevice+Model.m
//  screenshot
//
//  Created by Corey Werner on 8/27/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "UIDevice+Model.h"

@implementation UIDevice (Model)

+ (BOOL)is568h {
    return [UIScreen mainScreen].bounds.size.height == 568.f;
}

@end
