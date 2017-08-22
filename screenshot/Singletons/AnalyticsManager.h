//
//  AnalyticsManager.h
//  screenshot
//
//  Created by Corey Werner on 8/22/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AnalyticsManager : NSObject

+ (void)track:(NSString *)track;
+ (void)track:(NSString *)track properties:(NSDictionary<NSString *, id> *)properties;

@end
