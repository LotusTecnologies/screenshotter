//
//  WebViewController.h
//  screenshot
//
//  Created by Corey Werner on 8/14/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "BaseViewController.h"

@import WebKit.WKWebView;
@import WebKit.WKNavigationDelegate;

@interface WebViewController : BaseViewController <WKNavigationDelegate>

@property (nonatomic, copy) NSURL *url;

@property (nonatomic) BOOL toolbarEnabled;
@property (nonatomic, strong, readonly) UIBarButtonItem *backItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *forwardItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *refreshItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *shareItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *safariItem;
- (void)updateShareItem;

@property (nonatomic, strong) WKWebView *webView;

@property (nonatomic, copy) NSString *loaderLabelText; // Set this early, it's not persistent

@end
