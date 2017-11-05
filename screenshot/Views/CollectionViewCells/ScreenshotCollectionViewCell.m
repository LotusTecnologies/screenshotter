//
//  ScreenshotCollectionViewCell.m
//  screenshot
//
//  Created by Corey Werner on 8/7/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "ScreenshotCollectionViewCell.h"

@interface ScreenshotCollectionViewCell ()

@property (nonatomic, strong) UIView *shadowView;
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
        _shadowView = ({
            UIView *view = [[UIView alloc] init];
            view.translatesAutoresizingMaskIntoConstraints = NO;
            view.layer.shadowColor = [UIColor blackColor].CGColor;
            view.layer.shadowOffset = [[self class] shadowOffset];
            view.layer.shadowRadius = [[self class] shadowRadius];
            view.layoutMargins = ({
                UIEdgeInsets insets = [[self class] shadowInsets];
                insets.top = -insets.top;
                insets.left = -insets.left;
                insets.bottom = -insets.bottom;
                insets.right = -insets.right;
                insets;
            });
            [self.contentView addSubview:view];
            [view.layoutMarginsGuide.topAnchor constraintEqualToAnchor:self.contentView.topAnchor].active = YES;
            [view.layoutMarginsGuide.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor].active = YES;
            [view.layoutMarginsGuide.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor].active = YES;
            [view.layoutMarginsGuide.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor].active = YES;
            view;
        });
        
        UIView *containerView = [[UIView alloc] init];
        containerView.translatesAutoresizingMaskIntoConstraints = NO;
        containerView.layer.cornerRadius = [[self class] cornerRadius];
        containerView.layer.masksToBounds = YES;
        [self.contentView addSubview:containerView];
        [containerView.topAnchor constraintEqualToAnchor:self.shadowView.topAnchor].active = YES;
        [containerView.leadingAnchor constraintEqualToAnchor:self.shadowView.leadingAnchor].active = YES;
        [containerView.bottomAnchor constraintEqualToAnchor:self.shadowView.bottomAnchor].active = YES;
        [containerView.trailingAnchor constraintEqualToAnchor:self.shadowView.trailingAnchor].active = YES;
        
        _imageView = ({
            UIImageView *imageView = [[UIImageView alloc] init];
            imageView.translatesAutoresizingMaskIntoConstraints = NO;
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            imageView.clipsToBounds = YES;
            [containerView addSubview:imageView];
            [imageView.topAnchor constraintEqualToAnchor:containerView.topAnchor].active = YES;
            [imageView.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor].active = YES;
            [imageView.bottomAnchor constraintEqualToAnchor:containerView.bottomAnchor].active = YES;
            [imageView.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor].active = YES;
            imageView;
        });
        
        UIView *toolbarBackgroundView = [[UIView alloc] init];
        toolbarBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
        toolbarBackgroundView.clipsToBounds = YES;
        [containerView addSubview:toolbarBackgroundView];
        [toolbarBackgroundView.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor].active = YES;
        [toolbarBackgroundView.bottomAnchor constraintEqualToAnchor:containerView.bottomAnchor].active = YES;
        [toolbarBackgroundView.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor].active = YES;
        
        _toolbarImageView = ({
            UIImageView *imageView = [[UIImageView alloc] init];
            imageView.translatesAutoresizingMaskIntoConstraints = NO;
            imageView.contentMode = self.imageView.contentMode;
            imageView.backgroundColor = [UIColor colorWithWhite:1.f alpha:.9f];
            [toolbarBackgroundView addSubview:imageView];
            [imageView.topAnchor constraintEqualToAnchor:self.imageView.topAnchor].active = YES;
            [imageView.leadingAnchor constraintEqualToAnchor:self.imageView.leadingAnchor].active = YES;
            [imageView.bottomAnchor constraintEqualToAnchor:self.imageView.bottomAnchor].active = YES;
            [imageView.trailingAnchor constraintEqualToAnchor:self.imageView.trailingAnchor].active = YES;
            imageView;
        });
        
        _toolbar = ({
            UIBarButtonItem *shareButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"SHARE" style:UIBarButtonItemStylePlain target:self action:@selector(shareAction:)];
            UIBarButtonItem *trashButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"DELETE" style:UIBarButtonItemStylePlain target:self action:@selector(trashAction:)];
            UIBarButtonItem *flexilbeItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            
            UIToolbar *toolbar = [[UIToolbar alloc] init];
            toolbar.translatesAutoresizingMaskIntoConstraints = NO;
            [toolbar setBackgroundImage:[[UIImage alloc] init] forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
            toolbar.tintColor = [UIColor gray3];
            
            toolbar.items = @[shareButtonItem, flexilbeItem, trashButtonItem];
            [toolbarBackgroundView addSubview:toolbar];
            [toolbar.topAnchor constraintEqualToAnchor:toolbarBackgroundView.topAnchor].active = YES;
            [toolbar.leadingAnchor constraintEqualToAnchor:toolbarBackgroundView.leadingAnchor].active = YES;
            [toolbar.bottomAnchor constraintEqualToAnchor:toolbarBackgroundView.bottomAnchor].active = YES;
            [toolbar.trailingAnchor constraintEqualToAnchor:toolbarBackgroundView.trailingAnchor].active = YES;
            toolbar;
        });
        
        _badge = ({
            CGRect rect = CGRectZero;
            rect.size.width = rect.size.height = 28.f;
            
            UIView *view = [[UIView alloc] initWithFrame:rect];
            view.translatesAutoresizingMaskIntoConstraints = NO;
            view.backgroundColor = [UIColor crazeRed];
            view.userInteractionEnabled = NO;
            view.hidden = YES;
            view.transform = CGAffineTransformMakeRotation(M_PI_4);
            view.layer.shadowPath = [UIBezierPath bezierPathWithRect:view.bounds].CGPath;
            view.layer.shadowColor = [UIColor blackColor].CGColor;
            view.layer.shadowOffset = CGSizeMake(0.f, 1.f);
            view.layer.shadowRadius = 2.f;
            view.layer.shadowOpacity = .4f;
            [containerView addSubview:view];
            [view.topAnchor constraintEqualToAnchor:containerView.topAnchor constant:-view.bounds.size.height / 2.f].active = YES;
            [view.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor constant:view.bounds.size.width / 2.f].active = YES;
            [view.widthAnchor constraintEqualToConstant:view.bounds.size.width].active = YES;
            [view.heightAnchor constraintEqualToConstant:view.bounds.size.height].active = YES;
            view;
        });
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (!self.shadowView.layer.shadowPath || !CGSizeEqualToSize(CGPathGetBoundingBox(self.shadowView.layer.shadowPath).size, self.shadowView.bounds.size)) {
        self.shadowView.layer.shadowOpacity = .2f;
        self.shadowView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.shadowView.bounds cornerRadius:[[self class] cornerRadius]].CGPath;
    }
}


#pragma mark - Border / Shadow

+ (CGFloat)cornerRadius {
    return 6.f;
}

+ (CGSize)shadowOffset {
    return CGSizeMake(0.f, 1.f);
}

+ (CGFloat)shadowRadius {
    return 2.f;
}

+ (UIEdgeInsets)shadowInsets {
    CGFloat shadowInset = [self shadowRadius] * 2.f;
    
    UIEdgeInsets shadowInsets = UIEdgeInsetsZero;
    shadowInsets.top = shadowInset - [self shadowOffset].height;
    shadowInsets.left = shadowInset;
    shadowInsets.bottom = shadowInset + [self shadowOffset].height;
    shadowInsets.right = shadowInset;
    return shadowInsets;
}


#pragma mark - Screenshot

- (void)setScreenshot:(Screenshot *)screenshot {
    if (_screenshot != screenshot) {
        _screenshot = screenshot;
        
        if (screenshot) {
            // TODO: set to default screenshot image
            self.imageView.image = [UIImage imageWithData:_screenshot.imageData];
            
            // TODO: create cache of these images for scrolling performance
//            self.toolbarImageView.image = [self.imageView.image extraLightImage];
            
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
