//
//  NotificationManager.m
//  screenshot
//
//  Created by Corey Werner on 8/23/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "NotificationManager.h"
#import "UIColor+Appearance.h"
#import "Geometry.h"

@interface NotificationManager ()

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, UIView *> *notificationViewDict;

@property (nonatomic) CGFloat contentHeight;

@end

@implementation NotificationManager

+ (NotificationManager *)sharedNotificationManager {
    static dispatch_once_t pred;
    static NotificationManager *shared = nil;
    
    dispatch_once(&pred, ^{
        shared = [[NotificationManager alloc] init];
    });
    
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _notificationViewDict = [NSMutableDictionary dictionary];
        
        _contentHeight = [[[UINavigationBar alloc] init] intrinsicContentSize].height;
        
        _window = ({
            CGRect rect = CGRectZero;
            rect.size.width = [UIScreen mainScreen].bounds.size.width;
            rect.size.height = [UIApplication sharedApplication].statusBarFrame.size.height + self.contentHeight;
            
            UIWindow *window = [[UIWindow alloc] initWithFrame:rect];
            window.windowLevel = UIWindowLevelNormal;
            window;
        });
    }
    return self;
}


#pragma mark - View

- (UIView *)notificationViewForContentType:(NotificationManagerContentType)contentType {
    UIView *notificationView = [self.notificationViewDict objectForKey:@(contentType)];
    
    if (!notificationView) {
        CGFloat p = [Geometry padding];
        
        CGRect viewRect = self.window.bounds;
        viewRect.origin.y = -viewRect.size.height;
        
        notificationView = [[UIView alloc] initWithFrame:viewRect];
        notificationView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        notificationView.backgroundColor = [UIColor whiteColor];
        notificationView.layoutMargins = UIEdgeInsetsMake(0.f, p, 0.f, p);
        [self.window addSubview:notificationView];
        
        UIView *contentView = [[UIView alloc] init];
        contentView.translatesAutoresizingMaskIntoConstraints = NO;
        [notificationView addSubview:contentView];
        [contentView.topAnchor constraintEqualToAnchor:notificationView.bottomAnchor constant:-self.contentHeight].active = YES;
        [contentView.leadingAnchor constraintGreaterThanOrEqualToAnchor:notificationView.layoutMarginsGuide.leadingAnchor].active = YES;
        [contentView.bottomAnchor constraintEqualToAnchor:notificationView.bottomAnchor].active = YES;
        [contentView.trailingAnchor constraintLessThanOrEqualToAnchor:notificationView.layoutMarginsGuide.trailingAnchor].active = YES;
        [contentView.centerXAnchor constraintEqualToAnchor:notificationView.centerXAnchor].active = YES;
        
        CGFloat borderHeight = ([UIScreen mainScreen].scale > 1.f) ? .5f : 1.f;
        
        UIView *border = [[UIView alloc] init];
        border.translatesAutoresizingMaskIntoConstraints = NO;
        border.backgroundColor = [UIColor colorWithWhite:178.f/255.f alpha:1.f];
        border.userInteractionEnabled = NO;
        [notificationView addSubview:border];
        [border.leadingAnchor constraintEqualToAnchor:notificationView.leadingAnchor].active = YES;
        [border.bottomAnchor constraintEqualToAnchor:notificationView.bottomAnchor].active = YES;
        [border.trailingAnchor constraintEqualToAnchor:notificationView.trailingAnchor].active = YES;
        [border.heightAnchor constraintEqualToConstant:borderHeight].active = YES;
        
        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        activityView.translatesAutoresizingMaskIntoConstraints = NO;
        activityView.color = [UIColor crazeRedColor];
        activityView.transform = CGAffineTransformMakeScale(.6f, .6f);
        [activityView startAnimating];
        [contentView addSubview:activityView];
        [activityView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor].active = YES;
        [activityView.centerYAnchor constraintEqualToAnchor:contentView.centerYAnchor].active = YES;
        
        UILabel *label = [[UILabel alloc] init];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        label.textColor = [UIColor crazeRedColor];
        label.text = [self textForContentType:contentType];
        [contentView addSubview:label];
        [label.topAnchor constraintEqualToAnchor:contentView.topAnchor].active = YES;
        [label.leadingAnchor constraintEqualToAnchor:activityView.trailingAnchor].active = YES;
        [label.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor].active = YES;
        [label.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor].active = YES;
    }
    
    return notificationView;
}

- (NSString *)textForContentType:(NotificationManagerContentType)contentType {
    switch (contentType) {
        case NotificationManagerContentTypeOne:
            return @"Identifying new screenshots...";
            break;
        case NotificationManagerContentTypeTwo:
            return @"Identifying new products...";
            break;
    }
}


#pragma mark - Present / Dismiss

- (void)presentWithContentType:(NotificationManagerContentType)contentType {
    [self.window makeKeyAndVisible];
    
    UIView *notificationView = [self.notificationViewDict objectForKey:@(contentType)];
    
    if (notificationView) {
        if (self.window.subviews.lastObject != notificationView) {
            CGRect rect = notificationView.frame;
            rect.origin.y = -rect.size.height;
            notificationView.frame = rect;
            
            [self.window bringSubviewToFront:notificationView];
            
            [UIView animateWithDuration:.3f delay:0.f options:UIViewAnimationOptionCurveEaseOut animations:^{
                CGRect rect = notificationView.frame;
                rect.origin.y = 0.f;
                notificationView.frame = rect;
                
            } completion:nil];
        }
        
    } else {
        notificationView = [self notificationViewForContentType:contentType];
        
        [self.notificationViewDict setObject:notificationView forKey:@(contentType)];
        
        [UIView animateWithDuration:.3f delay:0.f options:UIViewAnimationOptionCurveEaseOut animations:^{
            CGRect rect = notificationView.frame;
            rect.origin.y = 0.f;
            notificationView.frame = rect;
            
        } completion:nil];
    }
}

- (void)presentWithContentType:(NotificationManagerContentType)contentType duration:(NSTimeInterval)duration {
    [self presentWithContentType:contentType];
    [self performSelector:@selector(dismissWithContentTypeNumber:) withObject:@(contentType) afterDelay:duration];
}

- (void)dismissWithContentType:(NotificationManagerContentType)contentType {
    UIView *notificationView = [self.notificationViewDict objectForKey:@(contentType)];
    
    if (notificationView) {
        [self.notificationViewDict removeObjectForKey:@(contentType)];
        
        [UIView animateWithDuration:.3f delay:0.f options:UIViewAnimationOptionCurveEaseIn animations:^{
            CGRect rect = notificationView.frame;
            rect.origin.y = -rect.size.height;
            notificationView.frame = rect;
            
        } completion:^(BOOL finished) {
            [notificationView removeFromSuperview];
            
            if (!self.notificationViewDict.count) {
                self.window.hidden = YES;
            }
        }];
        
    } else {
        if (!self.notificationViewDict.count) {
            self.window.hidden = YES;
        }
    }
}

- (void)dismissWithContentTypeNumber:(NSNumber *)contentTypeNumber {
    [self dismissWithContentType:[contentTypeNumber unsignedIntegerValue]];
}

@end
