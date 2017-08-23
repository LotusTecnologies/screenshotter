//
//  NotificationManager.h
//  screenshot
//
//  Created by Corey Werner on 8/23/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, NotificationManagerContentType) {
    NotificationManagerContentTypeOne,
    NotificationManagerContentTypeTwo
};

@interface NotificationManager : NSObject

+ (NotificationManager *)sharedNotificationManager;

- (void)presentWithContentType:(NotificationManagerContentType)contentType;
- (void)presentWithContentType:(NotificationManagerContentType)contentType duration:(NSTimeInterval)duration;
- (void)dismissWithContentType:(NotificationManagerContentType)contentType;

@end
