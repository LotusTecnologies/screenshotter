//
//  WebViewController.h
//  screenshot
//
//  Created by Corey Werner on 8/14/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "BaseViewController.h"

@import WebKit.WKWebView;

@interface WebViewController : BaseViewController

@property (nonatomic, copy) NSURL *url;

@property (nonatomic) BOOL toolbarEnabled;

@end
