//
//  TutorialViewController.m
//  screenshot
//
//  Created by Corey Werner on 8/9/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "TutorialViewController.h"
#import "TutorialScreenshotSlideView.h"
#import "TutorialShopSlideView.h"
#import "TutorialPermissionsSlideView.h"
#import "TutorialEmailSlideView.h"
#import "TutorialWelcomeSlideView.h"
#import "UIColor+Appearance.h"
#import "Geometry.h"
#import "PermissionsManager.h"
#import "WebViewController.h"
#import "AnalyticsManager.h"

@interface TutorialViewController () <TutorialWelcomeSlideViewDelegate, TutorialPermissionsSlideViewDelegate, TutorialEmailSlideViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSArray<TutorialBaseSlideView *>* slides;

@end

@implementation TutorialViewController

#pragma mark - Life Cycle

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
        
        [AnalyticsManager track:@"Started Tutorial"];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.scrollView = ({
        UIScrollView *scrollView = [[UIScrollView alloc] init];
        scrollView.translatesAutoresizingMaskIntoConstraints = NO;
        scrollView.showsHorizontalScrollIndicator = NO;
        scrollView.pagingEnabled = YES;
        scrollView.scrollEnabled = NO;
        [self.view addSubview:scrollView];
        [scrollView.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor].active = YES;
        [scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
        [scrollView.bottomAnchor constraintEqualToAnchor:self.bottomLayoutGuide.topAnchor].active = YES;
        [scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
        scrollView;
    });
    
    UIView *contentView = ({
        UIView *view = [[UIView alloc] init];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [self.scrollView addSubview:view];
        [view.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor].active = YES;
        [view.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor].active = YES;
        [view.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor].active = YES;
        [view.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor].active = YES;
        [view.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor multiplier:self.slides.count].active = YES;
        [view.heightAnchor constraintEqualToAnchor:self.scrollView.heightAnchor].active = YES;
        view;
    });
    
    CGFloat p = [Geometry padding];
    
    for (NSInteger i = 0; i < self.slides.count; i++) {
        TutorialBaseSlideView *slide = self.slides[i];
        slide.translatesAutoresizingMaskIntoConstraints = NO;
        [contentView addSubview:slide];
        slide.layoutMargins = UIEdgeInsetsMake(p + 30.f, p, p, p);
        [slide.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor].active = YES;
        [slide.heightAnchor constraintEqualToAnchor:self.scrollView.heightAnchor].active = YES;
        [slide.topAnchor constraintEqualToAnchor:contentView.topAnchor].active = YES;
        
        if (i == 0) {
            [slide.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor].active = YES;
            
        } else if (i == self.slides.count - 1) {
            [slide.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor].active = YES;
        }
        
        if (i > 0) {
            TutorialBaseSlideView *previousSlide = self.slides[i - 1];
            [slide.leadingAnchor constraintEqualToAnchor:previousSlide.trailingAnchor].active = YES;
        }
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    NSUInteger currentPage = 0; // TODO: Update based on contentOffset before transition
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        CGPoint offset = self.scrollView.contentOffset;
        offset.x = size.width * currentPage;
        self.scrollView.contentOffset = offset;
    } completion:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Slides

- (NSArray<TutorialBaseSlideView *> *)slides {
    if (!_slides) {
        TutorialWelcomeSlideView *welcomeSlideView = [[TutorialWelcomeSlideView alloc] init];
        welcomeSlideView.delegate = self;
        
        TutorialEmailSlideView *emailSlideView = [[TutorialEmailSlideView alloc] init];
        emailSlideView.delegate = self;
        
        TutorialPermissionsSlideView *permissionsSlideView = [[TutorialPermissionsSlideView alloc] init];
        permissionsSlideView.delegate = self;
        
        _slides = @[welcomeSlideView,
                    [[TutorialScreenshotSlideView alloc] init],
                    [[TutorialShopSlideView alloc] init],
                    permissionsSlideView,
                    emailSlideView
                    ];
    }
    return _slides;
}

- (void)tutorialWelcomeSlideViewDidComplete:(TutorialWelcomeSlideView *)slideView {
    slideView.delegate = nil;
    [self scrollToNextSlide];
}

- (void)tutorialPermissionsSlideViewDidDenyPhotosPermission:(TutorialPermissionsSlideView *)slideView {
    UIAlertController *alertController = [[PermissionsManager sharedPermissionsManager] deniedAlertControllerForType:PermissionTypePhoto];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)tutorialEmailSlideViewDidFail:(TutorialEmailSlideView *)slideView {
    UIAlertController *alertController = [TutorialEmailSlideView failedAlertController];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)tutorialEmailSlideViewDidSubmit:(TutorialEmailSlideView *)slideView {
    [self.delegate tutorialViewControllerDidComplete:self];
    [AnalyticsManager track:@"Finished Tutorial"];
}

- (void)tutorialEmailSlideViewDidTapTermsOfService:(TutorialEmailSlideView *)slideView {
    UIViewController *viewController = [TutorialEmailSlideView termsOfServiceViewControllerWithDoneTarget:self doneAction:@selector(dismissViewController)];
    [self presentViewController:viewController animated:YES completion:nil];
}

- (void)tutorialEmailSlideViewDidTapPrivacyPolicy:(TutorialEmailSlideView *)slideView {
    UIViewController *viewController = [TutorialEmailSlideView privacyPolicyViewControllerWithDoneTarget:self doneAction:@selector(dismissViewController)];
    [self presentViewController:viewController animated:YES completion:nil];
}


#pragma mark - Scroll View

- (void)scrollToNextSlide {
    CGPoint offset = CGPointZero;
    offset.x = self.scrollView.bounds.size.width + self.scrollView.contentOffset.x;
    
    [self.scrollView setContentOffset:offset animated:YES];
}


#pragma mark - Keyboard

- (void)keyboardWillShow:(NSNotification *)notification {
    if (self.view.window) {
        self.scrollView.scrollEnabled = NO;
    }
}

- (void)keyboardDidHide:(NSNotification *)notification {
    if (self.view.window) {
        self.scrollView.scrollEnabled = YES;
    }
}


#pragma mark - Navigation

- (void)dismissViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
