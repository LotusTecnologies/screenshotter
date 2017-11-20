//
//  NotifySizeChangeView.m
//  screenshot
//
//  Created by Corey Werner on 9/11/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "NotifySizeChangeView.h"

@interface NotifySizeChangeView ()

@property (nonatomic) CGSize previousSize;
@property (nonatomic) NSUInteger previousSubviewCount;

@end

@implementation NotifySizeChangeView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.previousSize = frame.size;
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    self.previousSize = frame.size;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.notification && !CGSizeEqualToSize(self.previousSize, self.bounds.size)) {
        self.previousSize = self.bounds.size;
        self.notification(self.bounds.size);
    }
}


#pragma mark - Subview

- (void)notifySubviewChange {
    if (self.subviewNotification && self.previousSubviewCount != self.subviews.count) {
        self.previousSubviewCount = self.subviews.count;
        self.subviewNotification(self.subviews.count);
    }
}

- (void)didAddSubview:(UIView *)subview {
    [super didAddSubview:subview];
    
    [self notifySubviewChange];
}

- (void)willRemoveSubview:(UIView *)subview {
    [super willRemoveSubview:subview];
    
    // ???: should this be in a dispatch async to wait until the view is removed before rechecking the count
    [self notifySubviewChange];
}

@end
