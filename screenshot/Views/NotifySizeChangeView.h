//
//  NotifySizeChangeView.h
//  screenshot
//
//  Created by Corey Werner on 9/11/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NotifySizeChangeView : UIView

@property (nonatomic, copy) void (^notification)(CGSize size);

@end
