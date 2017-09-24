//
//  TutorialWelcomeSlideView.m
//  screenshot
//
//  Created by Corey Werner on 8/24/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "TutorialWelcomeSlideView.h"
#import "screenshot-Swift.h"

@interface TutorialWelcomeSlideComponent: NSObject

@property (nonatomic, copy) NSString *imageName;
@property (nonatomic, copy) NSString *title;

@end

@interface TutorialWelcomeSlideView () <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) UIButton *nextButton;
@property (nonatomic, strong) NSArray<TutorialWelcomeSlideComponent *> *components;

@end

@implementation TutorialWelcomeSlideComponent

+ (instancetype)initWithImageName:(NSString *)imageName title:(NSString *)title {
    TutorialWelcomeSlideComponent *component = [[TutorialWelcomeSlideComponent alloc] init];
    component.imageName = imageName;
    component.title = title;
    return component;
}

@end

@implementation TutorialWelcomeSlideView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.titleLabel.attributedText = ({
            NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
            attachment.image = [UIImage imageNamed:@"Logo20h"];
                        
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@"Welcome to "];
            [attributedString appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
            attributedString;
        });
        
        self.subtitleLabel.text = @"Any fashion picture you screenshot becomes shoppable in the app";
        
        _pageControl = ({
            UIPageControl *control = [[UIPageControl alloc] init];
            control.translatesAutoresizingMaskIntoConstraints = NO;
            control.numberOfPages = 3;
            control.pageIndicatorTintColor = [UIColor gray8];
            control.currentPageIndicatorTintColor = [UIColor crazeRed];
            [self.contentView addSubview:control];
            [control.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor].active = YES;
            [control.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor].active = YES;
            control;
        });
        
        _nextButton = ({
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.translatesAutoresizingMaskIntoConstraints = NO;
            [button setTitle:@"Next" forState:UIControlStateNormal];
            [button setTitleColor:[UIColor crazeRed] forState:UIControlStateNormal];
            [button addTarget:self action:@selector(nextButtonAction) forControlEvents:UIControlEventTouchUpInside];
            [self.contentView addSubview:button];
            [button.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.pageControl.trailingAnchor].active = YES;
            [button.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor].active = YES;
            [button.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor].active = YES;
            button;
        });
        
        _scrollView = ({
            UIScrollView *scrollView = [[UIScrollView alloc] init];
            scrollView.translatesAutoresizingMaskIntoConstraints = NO;
            scrollView.delegate = self;
            scrollView.showsHorizontalScrollIndicator = NO;
            scrollView.pagingEnabled = YES;
            [self.contentView addSubview:scrollView];
            [scrollView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor].active = YES;
            [scrollView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor].active = YES;
            [scrollView.bottomAnchor constraintEqualToAnchor:self.pageControl.topAnchor].active = YES;
            [scrollView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor].active = YES;
            scrollView;
        });
        
        UIView *scrollContentView = ({
            UIView *view = [[UIView alloc] init];
            view.translatesAutoresizingMaskIntoConstraints = NO;
            [self.scrollView addSubview:view];
            [view.topAnchor constraintEqualToAnchor:self.contentView.topAnchor].active = YES;
            [view.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor].active = YES;
            [view.bottomAnchor constraintEqualToAnchor:self.pageControl.topAnchor].active = YES;
            [view.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor].active = YES;
            [view.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor multiplier:self.components.count].active = YES;
            [view.heightAnchor constraintEqualToAnchor:self.scrollView.heightAnchor].active = YES;
            view;
        });
        
        for (NSInteger i = 0; i < self.components.count; i++) {
            TutorialWelcomeSlideComponent *component = self.components[i];
            
            UIView *view = [[UIView alloc] init];
            view.translatesAutoresizingMaskIntoConstraints = NO;
            view.tag = i + 1;
            [scrollContentView addSubview:view];
            [view.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor].active = YES;
            [view.heightAnchor constraintEqualToAnchor:self.scrollView.heightAnchor].active = YES;
            [view.topAnchor constraintEqualToAnchor:scrollContentView.topAnchor].active = YES;
            
            if (i == 0) {
                [view.leadingAnchor constraintEqualToAnchor:scrollContentView.leadingAnchor].active = YES;
                
            } else if (i == self.components.count - 1) {
                [view.trailingAnchor constraintEqualToAnchor:scrollContentView.trailingAnchor].active = YES;
            }
            
            if (i > 0) {
                [view.leadingAnchor constraintEqualToAnchor:[scrollContentView viewWithTag:i].trailingAnchor].active = YES;
            }
            
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:component.imageName]];
            imageView.translatesAutoresizingMaskIntoConstraints = NO;
            imageView.contentMode = UIViewContentModeScaleAspectFit;
            [view addSubview:imageView];
            [imageView.topAnchor constraintEqualToAnchor:view.topAnchor].active = YES;
            [imageView.leadingAnchor constraintGreaterThanOrEqualToAnchor:view.leadingAnchor].active = YES;
            [imageView.trailingAnchor constraintLessThanOrEqualToAnchor:view.trailingAnchor].active = YES;
            [imageView.centerXAnchor constraintEqualToAnchor:view.centerXAnchor].active = YES;
            
            UILabel *label = [[UILabel alloc] init];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            label.text = component.title;
            label.textAlignment = NSTextAlignmentCenter;
            label.textColor = [UIColor gray3];
            label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle3];
            [view addSubview:label];
            [label setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
            [label.topAnchor constraintEqualToAnchor:imageView.bottomAnchor].active = YES;
            [label.leadingAnchor constraintEqualToAnchor:view.leadingAnchor].active = YES;
            [label.bottomAnchor constraintEqualToAnchor:view.bottomAnchor].active = YES;
            [label.trailingAnchor constraintEqualToAnchor:view.trailingAnchor].active = YES;
        }
    }
    return self;
}


#pragma mark - Components

- (NSArray<TutorialWelcomeSlideComponent *> *)components {
    if (!_components) {
        _components = @[[TutorialWelcomeSlideComponent initWithImageName:@"TutorialWelcomeGraphic1" title:@"Take Screenshots"],
                        [TutorialWelcomeSlideComponent initWithImageName:@"TutorialWelcomeGraphic2" title:@"Find Products"],
                        [TutorialWelcomeSlideComponent initWithImageName:@"TutorialWelcomeGraphic3" title:@"Shop"]
                        ];
    }
    return _components;
}



#pragma mark - Scroll View

- (NSInteger)currentComponentIndex {
    return ceil(self.scrollView.contentOffset.x / self.scrollView.bounds.size.width);
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        self.pageControl.currentPage = [self currentComponentIndex];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.pageControl.currentPage = [self currentComponentIndex];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    self.pageControl.currentPage = [self currentComponentIndex];
}


#pragma mark - Navigation

- (void)nextButtonAction {
    if ([self currentComponentIndex] == self.components.count - 1) {
        [self.delegate tutorialWelcomeSlideViewDidComplete:self];
        
    } else {
        CGPoint offset = CGPointZero;
        offset.x = self.scrollView.bounds.size.width + self.scrollView.contentOffset.x;
        
        [self.scrollView setContentOffset:offset animated:YES];
    }
}

@end
