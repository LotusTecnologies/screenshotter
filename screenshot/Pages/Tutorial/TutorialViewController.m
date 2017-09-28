//
//  TutorialViewController.m
//  screenshot
//
//  Created by Corey Werner on 8/9/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "TutorialViewController.h"
#import "TutorialEmailSlideView.h"
#import "TutorialWelcomeSlideView.h"
#import "TutorialTrySlideView.h"
#import "Geometry.h"
#import "PermissionsManager.h"
#import "WebViewController.h"
#import "AnalyticsManager.h"
#import "screenshot-Swift.h"

@interface TutorialViewController () <UIScrollViewDelegate, TutorialWelcomeSlideViewDelegate, TutorialEmailSlideViewDelegate, TutorialTrySlideViewDelegate> {
    BOOL _didPresentDeterminePushAlertController;
    BOOL _scrollViewIsScrollingAnimation;
}

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) NSArray<TutorialBaseSlideView *>* slides;
@property (nonatomic, strong) UpdatePromptHandler *handler;

@end

@implementation TutorialViewController

#pragma mark - Life Cycle

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Tutorial";
        
        [AnalyticsManager track:@"Started Tutorial"];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.handler = [[UpdatePromptHandler alloc] initWithContainerViewController:self];
    [self.handler start];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.scrollView = ({
        UIScrollView *scrollView = [[UIScrollView alloc] init];
        scrollView.translatesAutoresizingMaskIntoConstraints = NO;
        scrollView.delegate = self;
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
        UIView *view = self.contentView;
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [self.scrollView addSubview:view];
        [view.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor].active = YES;
        [view.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor].active = YES;
        [view.bottomAnchor constraintEqualToAnchor:self.bottomLayoutGuide.topAnchor].active = YES;
        [view.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor].active = YES;
        [view.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor multiplier:self.slides.count].active = YES;
        [view.heightAnchor constraintEqualToAnchor:self.scrollView.heightAnchor].active = YES;
        view;
    });
    
    CGFloat p = [Geometry padding];
    CGFloat t = self.contentView.layoutMargins.top;
    
    for (NSInteger i = 0; i < self.slides.count; i++) {
        TutorialBaseSlideView *slide = self.slides[i];
        slide.translatesAutoresizingMaskIntoConstraints = NO;
        [contentView addSubview:slide];
        slide.layoutMargins = UIEdgeInsetsMake(p, p, p, p);
        [slide.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor].active = YES;
        [slide.heightAnchor constraintEqualToAnchor:self.scrollView.heightAnchor constant:-t].active = YES;
        [slide.topAnchor constraintEqualToAnchor:contentView.topAnchor constant:t].active = YES;
        
        if (i == 0) {
            [slide.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor].active = YES;
            [slide didEnterSlide];
            
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
    
    NSUInteger currentSlideIndex = [self currentSlideIndex];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        CGPoint offset = self.scrollView.contentOffset;
        offset.x = size.width * currentSlideIndex;
        self.scrollView.contentOffset = offset;
    } completion:nil];
}


#pragma mark - Layout

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
    }
    return _contentView;
}

- (void)setContentLayoutMargins:(UIEdgeInsets)contentLayoutMargins {
    self.contentView.layoutMargins = contentLayoutMargins;
}

- (UIEdgeInsets)contentLayoutMargins {
    return self.contentView.layoutMargins;
}


#pragma mark - Slides

- (NSArray<TutorialBaseSlideView *> *)slides {
    if (!_slides) {
        TutorialWelcomeSlideView *welcomeSlideView = [[TutorialWelcomeSlideView alloc] init];
        welcomeSlideView.delegate = self;
        
        TutorialEmailSlideView *emailSlideView = [[TutorialEmailSlideView alloc] init];
        emailSlideView.delegate = self;
        
        TutorialTrySlideView *trySlideView = [[TutorialTrySlideView alloc] init];
        trySlideView.delegate = self;
        
        _slides = @[welcomeSlideView,
                    emailSlideView,
                    trySlideView
                    ];
    }
    return _slides;
}

- (NSUInteger)currentSlideIndex {
    return ceil(self.scrollView.contentOffset.x / self.scrollView.bounds.size.width);
}

- (TutorialBaseSlideView *)currentSlide {
    return self.slides[[self currentSlideIndex]];
}

- (void)tutorialWelcomeSlideViewDidComplete:(TutorialWelcomeSlideView *)slideView {
    slideView.delegate = nil;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:UserDefaultsKeys.tutorialCompleted]) {
        // The tutorial is being presented elsewhere and shouldn't
        // include the try slide
        
        [self.delegate tutorialViewControllerDidComplete:self];
        
    } else {
        [self scrollToNextSlide];
    }
}

- (void)tutorialEmailSlideViewDidComplete:(TutorialEmailSlideView *)slideView {
    slideView.delegate = nil;
    [self scrollToNextSlide];
}

- (void)tutorialEmailSlideViewDidTapTermsOfService:(TutorialEmailSlideView *)slideView {
    UIViewController *viewController = [TutorialEmailSlideView termsOfServiceViewControllerWithDoneTarget:self doneAction:@selector(dismissViewController)];
    [self presentViewController:viewController animated:YES completion:nil];
}

- (void)tutorialEmailSlideViewDidTapPrivacyPolicy:(TutorialEmailSlideView *)slideView {
    UIViewController *viewController = [TutorialEmailSlideView privacyPolicyViewControllerWithDoneTarget:self doneAction:@selector(dismissViewController)];
    [self presentViewController:viewController animated:YES completion:nil];
}

- (void)tutorialTrySlideViewDidComplete:(TutorialTrySlideView *)slideView {
    slideView.delegate = nil;
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:UserDefaultsKeys.tutorialCompleted];
    
    [self.delegate tutorialViewControllerDidComplete:self];
    [AnalyticsManager track:@"Finished Tutorial"];
}


#pragma mark - Scroll View

- (void)scrollToNextSlide {
    if (!_scrollViewIsScrollingAnimation) {
        _scrollViewIsScrollingAnimation = YES;
        
        [[self currentSlide] willLeaveSlide];
        
        CGPoint offset = CGPointZero;
        offset.x = self.scrollView.bounds.size.width + self.scrollView.contentOffset.x;
        
        [self.scrollView setContentOffset:offset animated:YES];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    _scrollViewIsScrollingAnimation = NO;
    
    [[self currentSlide] didEnterSlide];
}


#pragma mark - Navigation

- (void)dismissViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
