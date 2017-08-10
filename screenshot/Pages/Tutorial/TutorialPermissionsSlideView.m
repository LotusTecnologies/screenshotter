//
//  TutorialPermissionsSlideView.m
//  screenshot
//
//  Created by Corey Werner on 8/9/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "TutorialPermissionsSlideView.h"
#import "PermissionsManager.h"
#import "Geometry.h"

@interface TutorialPermissionsSlideView ()

@property (nonatomic, strong) UIView *separatorView;

@end

@implementation TutorialPermissionsSlideView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.titleLabel.text = @"Get Started";
        self.subtitleLabel.text = @"Turn on permissions for the best CRAZE experience";
        
        UIView *photosRow = [self permissionWithImage:[UIImage imageNamed:@"IconPhotos"] text:@"Allow Photo Gallery Access" action:nil];
        [photosRow.topAnchor constraintGreaterThanOrEqualToAnchor:self.contentView.topAnchor].active = YES;
        
        UIView *notificationRow = [self permissionWithImage:[UIImage imageNamed:@"IconNotifications"] text:@"Enable Notifications" action:nil];
        [notificationRow.heightAnchor constraintEqualToAnchor:photosRow.heightAnchor].active = YES;
        [notificationRow.topAnchor constraintGreaterThanOrEqualToAnchor:photosRow.bottomAnchor].active = YES;
        
        UIView *locationRow = [self permissionWithImage:[UIImage imageNamed:@"IconLocation"] text:@"Allow Location Access" action:nil];
        [locationRow.heightAnchor constraintEqualToAnchor:notificationRow.heightAnchor].active = YES;
        [locationRow.topAnchor constraintGreaterThanOrEqualToAnchor:notificationRow.bottomAnchor].active = YES;
        [locationRow.bottomAnchor constraintLessThanOrEqualToAnchor:self.contentView.bottomAnchor].active = YES;
        
        [self separatorFromAnchor:self.contentView.topAnchor toAnchor:photosRow.topAnchor];
        [self separatorFromAnchor:photosRow.layoutMarginsGuide.bottomAnchor toAnchor:notificationRow.topAnchor];
        [self separatorFromAnchor:notificationRow.layoutMarginsGuide.bottomAnchor toAnchor:locationRow.topAnchor];
        [self separatorFromAnchor:locationRow.bottomAnchor toAnchor:self.contentView.bottomAnchor];
    }
    return self;
}

- (UIView *)permissionWithImage:(UIImage *)image text:(NSString *)text action:(SEL)action {
    CGFloat p = [Geometry padding];
    
    UIView *view = [[UIView alloc] init];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    view.layoutMargins = UIEdgeInsetsMake(-p, 0.f, -p, 0.f);
    [self.contentView addSubview:view];
    [view.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor].active = YES;
    [view.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor].active = YES;
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.layoutMargins = UIEdgeInsetsMake(0.f, 0.f, 0.f, -p);
    [view addSubview:imageView];
    [imageView setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [imageView setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [imageView.topAnchor constraintEqualToAnchor:view.topAnchor].active = YES;
    [imageView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor].active = YES;
    [imageView.bottomAnchor constraintEqualToAnchor:view.bottomAnchor].active = YES;
    
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.numberOfLines = 0;
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    label.text = text;
    label.layoutMargins = UIEdgeInsetsMake(0.f, 0.f, 0.f, -p);
    [view addSubview:label];
    [label setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [label.topAnchor constraintEqualToAnchor:view.topAnchor].active = YES;
    [label.leadingAnchor constraintEqualToAnchor:imageView.layoutMarginsGuide.trailingAnchor].active = YES;
    [label.bottomAnchor constraintEqualToAnchor:view.bottomAnchor].active = YES;
    
    UISwitch *aSwitch = [[UISwitch alloc] init];
    aSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:aSwitch];
    [aSwitch.leadingAnchor constraintEqualToAnchor:label.layoutMarginsGuide.trailingAnchor].active = YES;
    [aSwitch.trailingAnchor constraintEqualToAnchor:view.trailingAnchor].active = YES;
    [aSwitch.centerYAnchor constraintEqualToAnchor:view.centerYAnchor].active = YES;
    
    return view;
}

- (void)separatorFromAnchor:(NSLayoutAnchor<NSLayoutYAxisAnchor *> *)fromAnchor toAnchor:(NSLayoutAnchor<NSLayoutYAxisAnchor *> *)toAnchor {
    UIView *view = [[UIView alloc] init];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:view];
    [view.topAnchor constraintEqualToAnchor:fromAnchor].active = YES;
    [view.bottomAnchor constraintEqualToAnchor:toAnchor].active = YES;
    
    if (self.separatorView) {
        [view.heightAnchor constraintEqualToAnchor:self.separatorView.heightAnchor].active = YES;
        
    } else {
        self.separatorView = view;
    }
}

@end
