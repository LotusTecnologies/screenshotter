//
//  UIApplication+Version.h
//  screenshot
//
//  Created by Corey Werner on 8/14/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIApplication (Version)

+ (nonnull NSString *)displayName;
+ (nonnull NSString *)version;
+ (nonnull NSString *)build;
+ (nonnull NSString *)versionBuild;

@end
