//
//  Loader.m
//  screenshot
//
//  Created by Corey Werner on 8/15/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "Loader.h"

@import QuartzCore;

@interface Loader () {
    BOOL _isAnimating;
}

@property (nonatomic, strong) UIImageView *bagImageView;
@property (nonatomic, strong) UIImageView *cImageView;
@property (nonatomic, strong) NSLayoutConstraint *cImageViewCenterXConstraint;

@end

@implementation Loader

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _bagImageView = ({
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LoaderBag"]];
            imageView.translatesAutoresizingMaskIntoConstraints = NO;
            imageView.contentMode = UIViewContentModeScaleAspectFit;
            [self addSubview:imageView];
            [imageView.topAnchor constraintEqualToAnchor:self.topAnchor].active = YES;
            [imageView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor].active = YES;
            [imageView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;
            [imageView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor].active = YES;
            imageView;
        });
        
        _cImageView = ({
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LoaderC"]];
            imageView.translatesAutoresizingMaskIntoConstraints = NO;
            imageView.contentMode = UIViewContentModeScaleAspectFit;
            [self addSubview:imageView];
            [imageView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;
            
            self.cImageViewCenterXConstraint = [imageView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor];
            
            NSLayoutConstraint *leadingConstraint = [NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.1f constant:0.f];
            leadingConstraint.priority = UILayoutPriorityDefaultHigh;
            leadingConstraint.active = YES;
            
            imageView;
        });
    }
    return self;
}


#pragma mark - Layout

- (CGSize)intrinsicContentSize {
    return self.bagImageView.image.size;
}


#pragma mark - Animation

- (CABasicAnimation *)rotationAnimation {
    CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    animation.toValue = @(M_PI * 2.0);
    animation.duration = 1.5;
    animation.repeatCount = HUGE_VALF;
    return animation;
}

- (void)startAnimation:(LoaderAnimation)loaderAnimation {
    switch (loaderAnimation) {
        case LoaderAnimationSpin:
            [self startSpinAnimation];
            break;
            
        case LoaderAnimationPoseThenSpin:
            [self startPoseThenSpinAnimation];
            break;
    }
}

- (void)startSpinAnimation {
    if (![self isAnimating]) {
        _isAnimating = YES;
        self.cImageViewCenterXConstraint.active = YES;
        
        [self.cImageView.layer addAnimation:[self rotationAnimation] forKey:@"rotation"];
    }
}

- (void)startPoseThenSpinAnimation {
    if (![self isAnimating]) {
        _isAnimating = YES;
        self.cImageViewCenterXConstraint.active = YES;
        
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            [self layoutIfNeeded];
            
        } completion:^(BOOL finished) {
            if (finished) {
                [self.cImageView.layer addAnimation:[self rotationAnimation] forKey:@"rotation"];
            }
        }];
    }
}

- (void)stopAnimation {
    if ([self isAnimating]) {
        _isAnimating = NO;
        self.cImageViewCenterXConstraint.active = NO;
        
        [self.cImageView.layer removeAnimationForKey:@"rotation"];
    }
}

- (BOOL)isAnimating {
    return _isAnimating;
}

@end
