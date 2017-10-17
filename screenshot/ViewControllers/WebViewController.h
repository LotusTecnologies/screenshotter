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

@property (nonatomic, strong) WKWebView *view;
@property (nonatomic, copy) NSURL *url;

@property (nonatomic) BOOL toolbarEnabled;

@end
