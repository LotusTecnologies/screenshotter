//
//  InsetPresentationController.m
//  screenshot
//
//  Created by Corey Werner on 8/31/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "InsetPresentationController.h"
#import "screenshot-Swift.h"

@interface InsetPresentationController ()

@property (nonatomic, strong) UIView *dimmingView;

@end

@implementation InsetPresentationController

- (instancetype)initWithPresentedViewController:(UIViewController *)presentedViewController presentingViewController:(UIViewController *)presentingViewController {
    self = [super initWithPresentedViewController:presentedViewController presentingViewController:presentingViewController];
    if (self) {
        _dimmingView = ({
            UIView *view = [[UIView alloc] init];
            view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.7f];
            view;
        });
    }
    return self;
}

- (CGRect)frameOfPresentedViewInContainerView {
    CGRect rect = CGRectInset(self.containerView.frame, [Geometry padding], [Geometry padding]);
    
    CGSize contentSize = self.presentedView.intrinsicContentSize;
    contentSize.width = MAX(contentSize.width, 0.f);
    contentSize.height = MAX(contentSize.height, 0.f);
    
    if (!CGSizeEqualToSize(contentSize, CGSizeZero)) {
        if (contentSize.width > 0.f) {
            rect.size.width = MIN(rect.size.width, contentSize.width);
            rect.origin.x = (self.containerView.bounds.size.width - rect.size.width) / 2.f;
        }
        
        if (contentSize.height > 0.f) {
            rect.size.height = MIN(rect.size.height, contentSize.height);
            rect.origin.y = (self.containerView.bounds.size.height - rect.size.height) / 2.f;
        }
    }
    
    return rect;
}

- (void)containerViewWillLayoutSubviews {
    self.dimmingView.frame = self.containerView.bounds;
    self.presentedView.frame = [self frameOfPresentedViewInContainerView];
}

- (void)presentationTransitionWillBegin {
    UIView *presentedView = self.presentedViewController.view;
    presentedView.layer.cornerRadius = 10.f;
    
    self.dimmingView.frame = self.containerView.bounds;
    self.dimmingView.alpha = 0.f;
    [self.containerView addSubview:self.dimmingView];
    
    [self.presentedViewController.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        self.dimmingView.alpha = 1.f;
    } completion:nil];
}

- (void)presentationTransitionDidEnd:(BOOL)completed {
    if (!completed) {
        [self.dimmingView removeFromSuperview];
    }
}

- (void)dismissalTransitionWillBegin {
    [self.presentedViewController.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        self.dimmingView.alpha = 0.f;
    } completion:nil];
}

- (void)dismissalTransitionDidEnd:(BOOL)completed {
    if (completed) {
        [self.dimmingView removeFromSuperview];
    }
}

@end
