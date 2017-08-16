//
//  ScreenshotDisplayViewController.m
//  screenshot
//
//  Created by Corey Werner on 8/16/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "ScreenshotDisplayViewController.h"
#import "Geometry.h"
#import "screenshot-Swift.h"

@interface ScreenshotDisplayViewController () {
    BOOL _didLayoutShoppableFrames;
}

@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIImageView *screenshotImageView;

@end

@implementation ScreenshotDisplayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGFloat p = [Geometry padding];
    
    UIView *backgroundView = [[UIView alloc] init];
    backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    backgroundView.backgroundColor = [UIColor colorWithWhite:97.f/255.f alpha:1.f];
    [self.view addSubview:backgroundView];
    [backgroundView.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor].active = YES;
    [backgroundView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [backgroundView.bottomAnchor constraintEqualToAnchor:self.bottomLayoutGuide.topAnchor].active = YES;
    [backgroundView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
    
    UIButton *closeButton = self.closeButton;
    closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [closeButton setTitle:@"✕" forState:UIControlStateNormal];
    closeButton.titleLabel.font = [UIFont systemFontOfSize:20.f weight:UIFontWeightUltraLight];
    closeButton.titleLabel.textColor = [UIColor whiteColor];
    closeButton.contentEdgeInsets = UIEdgeInsetsMake(p, p, p, p);
    [self.view addSubview:closeButton];
    [closeButton.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor].active = YES;
    [closeButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    
    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LogoHollowC"]];
    logoImageView.translatesAutoresizingMaskIntoConstraints = NO;
    logoImageView.contentMode = UIViewContentModeScaleAspectFit;
    logoImageView.layoutMargins = UIEdgeInsetsMake(-p, 0.f, 0.f, 0.f);
    [self.view addSubview:logoImageView];
    [logoImageView setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [logoImageView.layoutMarginsGuide.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor].active = YES;
    [logoImageView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    
    UIImageView *screenshotImageView = self.screenshotImageView;
    screenshotImageView.translatesAutoresizingMaskIntoConstraints = NO;
    screenshotImageView.contentMode = UIViewContentModeScaleAspectFit;
    screenshotImageView.layoutMargins = UIEdgeInsetsMake(-p, -p, -p, -p);
    [self.view addSubview:screenshotImageView];
    [screenshotImageView.layoutMarginsGuide.topAnchor constraintEqualToAnchor:logoImageView.bottomAnchor].active = YES;
    [screenshotImageView.layoutMarginsGuide.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [screenshotImageView.layoutMarginsGuide.bottomAnchor constraintEqualToAnchor:self.bottomLayoutGuide.topAnchor].active = YES;
    [screenshotImageView.layoutMarginsGuide.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if (!_didLayoutShoppableFrames) {
        _didLayoutShoppableFrames = YES;
        [self insertShoppableFrames];
    }
}

- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    }
    return _closeButton;
}

- (UIImageView *)screenshotImageView {
    if (!_screenshotImageView) {
        _screenshotImageView = [[UIImageView alloc] init];
    }
    return _screenshotImageView;
}

- (void)setImage:(UIImage *)image {
    self.screenshotImageView.image = image;
}

- (UIImage *)image {
    return self.screenshotImageView.image;
}

- (void)insertShoppableFrames {
    CGFloat imageWidth = self.image.size.width;
    CGFloat imageHeight = self.image.size.height;
    CGFloat imageViewWidth = self.screenshotImageView.bounds.size.width;
    CGFloat imageViewHeight = self.screenshotImageView.bounds.size.height;
    
    CGFloat imageScale = MIN(imageViewWidth / imageWidth, imageViewHeight / imageHeight);
    CGSize scaledImageSize = CGSizeMake(imageWidth * imageScale, imageHeight * imageScale);
    
    CGRect imageFrame = CGRectZero;
    imageFrame.origin.x = round((imageViewWidth - scaledImageSize.width) * .5f);
    imageFrame.origin.y = round((imageViewHeight - scaledImageSize.height) * .5f);
    imageFrame.size.width = round(scaledImageSize.width);
    imageFrame.size.height = round(scaledImageSize.height);
    
    UIView *screenshotImageFrameView = [[UIView alloc] initWithFrame:imageFrame];
    screenshotImageFrameView.userInteractionEnabled = NO;
    [self.screenshotImageView addSubview:screenshotImageFrameView];
    
    
    for (Shoppable *shoppable in self.shoppables) {
        CGRect frame = [shoppable frameWithSize:screenshotImageFrameView.bounds.size];
        
        UIView *frameView = [[UIView alloc] initWithFrame:frame];
        frameView.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:.7f].CGColor;
        frameView.layer.borderWidth = 2.f;
        [screenshotImageFrameView addSubview:frameView];
    }
}

@end
