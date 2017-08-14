//
//  WebViewController.m
//  screenshot
//
//  Created by Corey Werner on 8/14/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "WebViewController.h"

@import WebKit;

@interface WebViewController () <WKNavigationDelegate>

@property (nonatomic, strong) WKWebView *webView;

@end

@implementation WebViewController

- (void)loadView {
    self.view = self.webView = [[WKWebView alloc] init];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.url) {
        [self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
    }
}

- (void)setUrl:(NSURL *)url {
    _url = url;
    
    if (url && [self isViewLoaded]) {
        [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    }
}

@end
