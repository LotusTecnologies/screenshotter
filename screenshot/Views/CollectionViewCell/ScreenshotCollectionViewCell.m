//
//  ScreenshotCollectionViewCell.m
//  screenshot
//
//  Created by Corey Werner on 8/7/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "ScreenshotCollectionViewCell.h"
#import "UIColor+Appearance.h"

#import <ImageEffects/ImageEffects.h>

@interface ScreenshotCollectionViewCell ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImageView *toolbarImageView;
@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, strong) UIView *badge;

@end

@implementation ScreenshotCollectionViewCell

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _imageView = ({
            UIImageView *imageView = [[UIImageView alloc] init];
            imageView.translatesAutoresizingMaskIntoConstraints = NO;
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            imageView.clipsToBounds = YES;
            [self.contentView addSubview:imageView];
            [imageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor].active = YES;
            [imageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor].active = YES;
            [imageView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor].active = YES;
            [imageView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor].active = YES;
            imageView;
        });
        
        UIView *toolbarBackgroundView = [[UIView alloc] init];
        toolbarBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
        toolbarBackgroundView.clipsToBounds = YES;
        [self.contentView addSubview:toolbarBackgroundView];
        [toolbarBackgroundView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor].active = YES;
        [toolbarBackgroundView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor].active = YES;
        [toolbarBackgroundView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor].active = YES;
        
        _toolbarImageView = ({
            UIImageView *imageView = [[UIImageView alloc] init];
            imageView.translatesAutoresizingMaskIntoConstraints = NO;
            imageView.contentMode = self.imageView.contentMode;
            [toolbarBackgroundView addSubview:imageView];
            [imageView.topAnchor constraintEqualToAnchor:self.imageView.topAnchor].active = YES;
            [imageView.leadingAnchor constraintEqualToAnchor:self.imageView.leadingAnchor].active = YES;
            [imageView.bottomAnchor constraintEqualToAnchor:self.imageView.bottomAnchor].active = YES;
            [imageView.trailingAnchor constraintEqualToAnchor:self.imageView.trailingAnchor].active = YES;
            imageView;
        });
        
        _toolbar = ({
            // Restore when Share feature implemented.
            //UIBarButtonItem *shareButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ScreenshotShare"] style:UIBarButtonItemStylePlain target:self action:@selector(shareAction:)];
            UIBarButtonItem *trashButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ScreenshotTrash"] style:UIBarButtonItemStylePlain target:self action:@selector(trashAction:)];
            UIBarButtonItem *flexilbeItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            
            UIToolbar *toolbar = [[UIToolbar alloc] init];
            toolbar.translatesAutoresizingMaskIntoConstraints = NO;
            [toolbar setBackgroundImage:[[UIImage alloc] init] forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
            toolbar.tintColor = [UIColor crazeRedColor];
            
            //toolbar.items = @[shareButtonItem, flexilbeItem, trashButtonItem];
            toolbar.items = @[flexilbeItem, trashButtonItem];
            [toolbarBackgroundView addSubview:toolbar];
            [toolbar.topAnchor constraintEqualToAnchor:toolbarBackgroundView.topAnchor].active = YES;
            [toolbar.leadingAnchor constraintEqualToAnchor:toolbarBackgroundView.leadingAnchor].active = YES;
            [toolbar.bottomAnchor constraintEqualToAnchor:toolbarBackgroundView.bottomAnchor].active = YES;
            [toolbar.trailingAnchor constraintEqualToAnchor:toolbarBackgroundView.trailingAnchor].active = YES;
            toolbar;
        });
        
        _badge = ({
            CGFloat diameter= 16.f;
            
            CGRect rect = CGRectZero;
            rect.size.width = rect.size.height = diameter;
            
            UIView *view = [[UIView alloc] initWithFrame:rect];
            view.translatesAutoresizingMaskIntoConstraints = NO;
            view.backgroundColor = [UIColor crazeRedColor];
            view.userInteractionEnabled = NO;
            view.hidden = YES;
            view.layer.cornerRadius = diameter / 2.f;
            view.layer.shadowPath = [UIBezierPath bezierPathWithOvalInRect:view.bounds].CGPath;
            view.layer.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:.5f].CGColor;
            view.layer.shadowOffset = CGSizeMake(0.f, 1.f);
            view.layer.shadowRadius = 2.f;
            view.layer.shadowOpacity = 1.f;
            [self.contentView addSubview:view];
            [view.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:-2.f].active = YES;
            [view.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:2.f].active = YES;
            [view.widthAnchor constraintEqualToConstant:view.bounds.size.width].active = YES;
            [view.heightAnchor constraintEqualToConstant:view.bounds.size.height].active = YES;
            view;
        });
    }
    return self;
}


#pragma mark - Screenshot

- (void)setScreenshot:(Screenshot *)screenshot {
    if (_screenshot != screenshot) {
        _screenshot = screenshot;
        
        if (screenshot) {
            // TODO: set to default screenshot image
            self.imageView.image = [UIImage imageWithData:_screenshot.imageData];
            self.toolbarImageView.image = [self.imageView.image extraLightImage];
            
        } else {
            self.imageView.image = nil;
            self.toolbarImageView.image = nil;
        }
    }
}


#pragma mark - Badge

- (void)setBadgeEnabled:(BOOL)badgeEnabled {
    self.badge.hidden = !badgeEnabled;
}

- (BOOL)badgeEnabled {
    return !self.badge.hidden;
}


#pragma mark - Actions

- (void)shareAction:(UIBarButtonItem *)buttonItem {
    [self.delegate screenshotCollectionViewCellDidTapShare:self];
}

- (void)trashAction:(UIBarButtonItem *)buttonItem {
    [self.delegate screenshotCollectionViewCellDidTapTrash:self];
}

@end
