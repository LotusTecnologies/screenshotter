//
//  NotificationManager.h
//  screenshot
//
//  Created by Corey Werner on 8/23/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, NotificationManagerContentType) {
    NotificationManagerContentTypeScreenshots,
    NotificationManagerContentTypeProducts
};

@interface NotificationManager : NSObject

+ (NotificationManager *)sharedNotificationManager;

- (void)presentWithContentType:(NotificationManagerContentType)contentType;
- (void)presentWithContentType:(NotificationManagerContentType)contentType autoDismiss:(BOOL)autoDismiss;
- (void)dismissWithContentType:(NotificationManagerContentType)contentType;

@end
