//
//  AnalyticsManager.m
//  screenshot
//
//  Created by Corey Werner on 8/22/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "AnalyticsManager.h"
#import "screenshot-Swift.h"

@import Analytics;
@import Appsee;
@import Branch;

@implementation AnalyticsManager

//+ (AnalyticsManager *)sharedAnalyticsManager {
//    static dispatch_once_t pred;
//    static AnalyticsManager *shared = nil;
//    
//    dispatch_once(&pred, ^{
//        shared = [[AnalyticsManager alloc] init];
//    });
//    
//    return shared;
//}

+ (void)track:(NSString *)track {
    [[SEGAnalytics sharedAnalytics] track:track];
    [Appsee addEvent:track];
    [[Branch getInstance] userCompletedAction:track];
}

+ (void)identify:(NSString *)email {
    [[SEGAnalytics sharedAnalytics] identify:nil traits:@{ @"email": email }];
    [Appsee setUserID:email];
    [IntercomHelper.sharedInstance registerUserWithEmail:email];
    [[Branch getInstance] userCompletedAction:@"identify"];
}

+ (void)track:(NSString *)track properties:(NSDictionary<NSString *, id> *)properties {
    [[SEGAnalytics sharedAnalytics] track:track properties:properties];
    
    // Appsee properties can't exceed 300 bytes.
    // https://www.appsee.com/docs/ios/api?section=events
    
    NSMutableDictionary<NSString *, id> *appseeProperties = [NSMutableDictionary dictionary];
    
    [properties enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            NSString *appseeProperty = [NSString stringWithFormat:@"%@%@%@", track, key, obj];
            NSUInteger bytes = [appseeProperty lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
            
            if (bytes < 300) {
                appseeProperties[key] = obj;
            }
        }
    }];
    
    [Appsee addEvent:track withProperties:appseeProperties];
    [[Branch getInstance] userCompletedAction:track];
}

@end
