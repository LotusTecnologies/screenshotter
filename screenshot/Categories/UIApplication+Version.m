//
//  UIApplication+Version.m
//  screenshot
//
//  Created by Corey Werner on 8/14/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "UIApplication+Version.h"

// TODO: make as an extension on NSBundle

@implementation UIApplication (Version)

+ (nonnull NSString *)displayName {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"] ?: @"";
}

+ (nonnull NSString *)version {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"";
}

+ (nonnull NSString *)build {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey] ?: @"";
}

+ (nonnull NSString *)versionBuild {
    return [NSString stringWithFormat:@"%@.%@", [self version], [self build]];
}

@end

@implementation UIApplication (Environment)

+ (BOOL)isDev {
#if DEV
    return YES;
#else
    return NO;
#endif
}

@end

