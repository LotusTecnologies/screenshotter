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

@end

@implementation WebViewController
@dynamic view;

- (void)loadView {
    self.view = [[WKWebView alloc] init];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.url) {
        [self.view loadRequest:[NSURLRequest requestWithURL:self.url]];
    }
}

- (void)setUrl:(NSURL *)url {
    _url = url;
    
    if (url && [self isViewLoaded]) {
        [self.view loadRequest:[NSURLRequest requestWithURL:url]];
    }
}

@end
