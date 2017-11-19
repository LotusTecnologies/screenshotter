//
//  ScreenshotDisplayViewController.m
//  screenshot
//
//  Created by Corey Werner on 8/16/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "ScreenshotDisplayViewController.h"

#import "screenshot-Swift.h"

// Uncomment to calculate b0,b1 for a new tutorial screenshot.
#define STORE_NEW_TUTORIAL_SCREENSHOT 1

@interface ScreenshotDisplayViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *screenshotImageView;
@property (nonatomic, strong) UIView *screenshotImageFrameView;
@property (nonatomic, assign) CGPoint b0;

@end

@implementation ScreenshotDisplayViewController

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGFloat p = [Geometry padding];
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    
    UIView *backgroundView = [[UIView alloc] init];
    backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    backgroundView.backgroundColor = [UIColor colorWithWhite:97.f/255.f alpha:1.f];
    [self.view addSubview:backgroundView];
    [backgroundView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:statusBarHeight].active = YES;
    [backgroundView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [backgroundView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    [backgroundView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
    
    self.scrollView = ({
        UIScrollView *scrollView = [[UIScrollView alloc] init];
        scrollView.translatesAutoresizingMaskIntoConstraints = NO;
        scrollView.delegate = self;
        scrollView.maximumZoomScale = 3.f;
        scrollView.contentInset = UIEdgeInsetsMake(p, p, p, p);
        [self.view addSubview:scrollView];
        [scrollView.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor].active = YES;
        [scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
        [scrollView.bottomAnchor constraintEqualToAnchor:self.bottomLayoutGuide.topAnchor].active = YES;
        [scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
        scrollView;
    });
    
    CGFloat horizontal = self.scrollView.contentInset.left + self.scrollView.contentInset.right;
    CGFloat vertical = self.scrollView.contentInset.top + self.scrollView.contentInset.bottom;
    
    UIImageView *screenshotImageView = self.screenshotImageView;
    screenshotImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.scrollView addSubview:screenshotImageView];
    screenshotImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [screenshotImageView.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor].active = YES;
    [screenshotImageView.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor].active = YES;
    [screenshotImageView.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor].active = YES;
    [screenshotImageView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor].active = YES;
    [screenshotImageView.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor constant:-horizontal].active = YES;
    [screenshotImageView.heightAnchor constraintEqualToAnchor:self.scrollView.heightAnchor constant:-vertical].active = YES;
    
#ifdef STORE_NEW_TUTORIAL_SCREENSHOT
    screenshotImageView.userInteractionEnabled = YES;
    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
    [screenshotImageView addGestureRecognizer:longPressGestureRecognizer];
#endif
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
#ifndef STORE_NEW_TUTORIAL_SCREENSHOT
    if (!CGRectIsEmpty(self.screenshotImageView.bounds)) {
        [self insertShoppableFrames];
    }
#endif
}


#pragma mark - Layout

- (CGRect)aspectFitRectForImageSized:(CGSize)imageSize inViewSized:(CGSize)viewSize {
    CGFloat imageScale = MIN(viewSize.width / imageSize.width, viewSize.height / imageSize.height);
    CGSize scaledImageSize = CGSizeMake(imageSize.width * imageScale, imageSize.height * imageScale);
    
    CGRect rect = CGRectZero;
    rect.origin.x = round((viewSize.width - scaledImageSize.width) * .5f);
    rect.origin.y = round((viewSize.height - scaledImageSize.height) * .5f);
    rect.size.width = round(scaledImageSize.width);
    rect.size.height = round(scaledImageSize.height);
    return rect;
}


#pragma mark - Image

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


#pragma mark - Shoppable

- (void)insertShoppableFrames {
    [self.screenshotImageFrameView removeFromSuperview];
    
    CGRect imageFrame = [self aspectFitRectForImageSized:self.image.size inViewSized:self.screenshotImageView.bounds.size];
    
    UIView *screenshotImageFrameView = [[UIView alloc] initWithFrame:imageFrame];
    screenshotImageFrameView.userInteractionEnabled = NO;
    [self.screenshotImageView addSubview:screenshotImageFrameView];
    self.screenshotImageFrameView = screenshotImageFrameView;
    
    for (Shoppable *shoppable in self.shoppables) {
        CGRect frame = [shoppable frameWithSize:screenshotImageFrameView.bounds.size];
        
        UIView *frameView = [[UIView alloc] initWithFrame:frame];
        frameView.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:.7f].CGColor;
        frameView.layer.borderWidth = 2.f;
        [screenshotImageFrameView addSubview:frameView];
    }
}


#pragma mark - Scroll View

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.screenshotImageView;
}

#pragma mark - Gesture Recognizer

- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }
    CGPoint longPressPoint = [gestureRecognizer locationInView:self.screenshotImageView];
    CGFloat normalizedX = longPressPoint.x / self.screenshotImageView.bounds.size.width;
    CGFloat normalizedY = longPressPoint.y / self.screenshotImageView.bounds.size.height;
    
//    MAX(0, normalizedX)
    if (normalizedX < 0) normalizedX = 0;
    if (normalizedY < 0) normalizedY = 0;
    if (normalizedX > 1) normalizedX = 1;
    if (normalizedY > 1) normalizedY = 1;
    CGPoint normalizedPressPoint = CGPointMake(normalizedX, normalizedY);
    if (CGPointEqualToPoint(self.b0, CGPointZero)) {
        self.b0 = normalizedPressPoint;
        NSLog(@"b0:%@  longPressPoint:%@  in size:%@", NSStringFromCGPoint(self.b0), NSStringFromCGPoint(longPressPoint), NSStringFromCGSize(self.screenshotImageView.bounds.size));
    } else {
        CGPoint b1 = normalizedPressPoint;
        NSLog(@"b1:%@  longPressPoint:%@  in size:%@", NSStringFromCGPoint(b1), NSStringFromCGPoint(longPressPoint), NSStringFromCGSize(self.screenshotImageView.bounds.size));
        CGFloat viewWidth = self.screenshotImageView.bounds.size.width;
        CGFloat viewHeight = self.screenshotImageView.bounds.size.height;
        CGRect frame = CGRectMake(self.b0.x * viewWidth, self.b0.y * viewHeight, (b1.x - self.b0.x) * viewWidth, (b1.y - self.b0.y) * viewHeight);
        UIView *frameView = [[UIView alloc] initWithFrame:frame];
        frameView.layer.borderColor = [[UIColor greenColor] colorWithAlphaComponent:.7f].CGColor;
        frameView.layer.borderWidth = 2.f;
        [self.screenshotImageView addSubview:frameView];
        self.b0 = CGPointZero;
    }
}


@end
