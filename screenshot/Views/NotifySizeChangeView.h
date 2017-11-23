//
//  NotifySizeChangeView.h
//  screenshot
//
//  Created by Corey Werner on 9/11/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import <UIKit/UIKit.h>

// TODO: Change class name to include subview notifications

@interface NotifySizeChangeView : UIView

@property (nonatomic, copy) void (^notification)(CGSize size);
@property (nonatomic, copy) void (^subviewNotification)(NSUInteger count);

@end
