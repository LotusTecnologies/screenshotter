//
//  WebViewController.m
//  screenshot
//
//  Created by Corey Werner on 8/14/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "WebViewController.h"
#import "Loader.h"

@import WebKit;

@interface WebViewController () <WKNavigationDelegate>

@property (nonatomic, strong) Loader *loader;
@property (nonatomic, strong) UIToolbar *toolbar;

@end

@implementation WebViewController
@dynamic view;


#pragma mark - Life Cycle

- (void)loadView {
    self.view = [[WKWebView alloc] init];
    self.view.navigationDelegate = self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.toolbar = ({
        UIToolbar *toolbar = [[UIToolbar alloc] init];
        toolbar.frame = CGRectMake(0.f, 0.f, 0.f, [toolbar intrinsicContentSize].height);
        toolbar.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:toolbar];
        [toolbar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
        [toolbar.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
        [toolbar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
        toolbar;
    });
    
    self.loader = ({
        Loader *loader = [[Loader alloc] init];
        loader.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:loader];
        [loader.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
        [loader.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor].active = YES;
        loader;
    });
    
    self.view.scrollView.contentInset = ({
        UIEdgeInsets insets = self.view.scrollView.contentInset;
        insets.bottom = self.toolbar.bounds.size.height;
        insets;
    });
    
    self.view.scrollView.scrollIndicatorInsets = ({
        UIEdgeInsets insets = self.view.scrollView.scrollIndicatorInsets;
        insets.bottom = self.toolbar.bounds.size.height;
        insets;
    });
    
    if (self.url) {
        [self.view loadRequest:[NSURLRequest requestWithURL:self.url]];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.loader startAnimation];
}


#pragma mark - Url

- (void)setUrl:(NSURL *)url {
    _url = url;
    
    if (url && [self isViewLoaded]) {
        [self.view loadRequest:[NSURLRequest requestWithURL:url]];
    }
}


#pragma mark - Delegate

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    [self.loader stopAnimation];
    self.loader.hidden = YES;
}

@end
