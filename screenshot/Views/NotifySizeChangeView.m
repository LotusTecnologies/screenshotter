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

@end
