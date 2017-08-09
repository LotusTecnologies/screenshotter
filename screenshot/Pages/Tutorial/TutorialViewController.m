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
#import "UIColor+Appearance.h"

@interface TutorialViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) NSArray <TutorialBaseSlideView *>* slides;
@end

@implementation TutorialViewController

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.pageControl = ({
        UIPageControl *control = [[UIPageControl alloc] init];
        control.translatesAutoresizingMaskIntoConstraints = NO;
        control.numberOfPages = self.slides.count;
        control.defersCurrentPageDisplay = YES;
        control.currentPageIndicatorTintColor = [UIColor crazeRedColor];
        control.pageIndicatorTintColor = [UIColor colorWithWhite:216.f/255.f alpha:1.f];
        [self.view addSubview:control];
        [control.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
        [control.bottomAnchor constraintEqualToAnchor:self.bottomLayoutGuide.topAnchor].active = YES;
        control;
    });
    
    self.scrollView = ({
        UIScrollView *scrollView = [[UIScrollView alloc] init];
        scrollView.translatesAutoresizingMaskIntoConstraints = NO;
        scrollView.delegate = self;
        scrollView.showsHorizontalScrollIndicator = NO;
        scrollView.pagingEnabled = YES;
        [self.view addSubview:scrollView];
        [scrollView.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor].active = YES;
        [scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
        [scrollView.bottomAnchor constraintEqualToAnchor:self.pageControl.topAnchor].active = YES;
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
        view;
    });
    
    for (NSInteger i = 0; i < self.slides.count; i++) {
        TutorialBaseSlideView *slide = self.slides[i];
        slide.translatesAutoresizingMaskIntoConstraints = NO;
        [contentView addSubview:slide];
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

- (void)dealloc {
    self.scrollView.delegate = nil;
}


#pragma mark - Slides

- (NSArray<TutorialBaseSlideView *> *)slides {
    if (!_slides) {
        _slides = @[[[TutorialScreenshotSlideView alloc] init],
                    [[TutorialShopSlideView alloc] init],
                    [[TutorialPermissionsSlideView alloc] init],
                    [[TutorialEmailSlideView alloc] init]
                    ];
    }
    return _slides;
}


#pragma mark - Scroll View

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self updateCurrentPage];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self updateCurrentPage];
}


#pragma mark - Page Control

- (void)updateCurrentPage {
    self.pageControl.currentPage = self.scrollView.contentOffset.x / self.scrollView.bounds.size.width;
}

@end
