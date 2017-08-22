//
//  AnalyticsManager.m
//  screenshot
//
//  Created by Corey Werner on 8/22/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "AnalyticsManager.h"

@import Analytics;
@import Appsee;

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
}

+ (void)track:(NSString *)track properties:(NSDictionary<NSString *, id> *)properties {
    [[SEGAnalytics sharedAnalytics] track:track properties:properties];
    [Appsee addEvent:track withProperties:properties];
}

@end
