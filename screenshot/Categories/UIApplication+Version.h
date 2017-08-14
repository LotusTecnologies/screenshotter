//
//  UIApplication+Version.h
//  screenshot
//
//  Created by Corey Werner on 8/14/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIApplication (Version)

+ (NSString *)version;
+ (NSString *)build;
+ (NSString *)versionBuild;

@end
