//
//  WebViewController.m
//  screenshot
//
//  Created by Corey Werner on 8/14/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "WebViewController.h"
#import "Loader.h"
#import "Geometry.h"
#import "NetworkingModel.h"
#import "AnalyticsManager.h"

@import Appsee;
@import WebKit;

@interface WebViewController () <WKNavigationDelegate> {
    BOOL _isShorteningUrl;
}

@property (nonatomic, strong) Loader *loader;
@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, strong) UIBarButtonItem *backItem;
@property (nonatomic, strong) UIBarButtonItem *forwardItem;

@end

@implementation WebViewController
@dynamic view;


#pragma mark - Life Cycle

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _toolbarEnabled = YES;
    }
    return self;
}

- (void)loadView {
    self.view = [[WKWebView alloc] init];
    self.view.navigationDelegate = self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addObserver:self forKeyPath:NSStringFromSelector(@selector(canGoBack)) options:NSKeyValueObservingOptionNew context:NULL];
    [self.view addObserver:self forKeyPath:NSStringFromSelector(@selector(canGoForward)) options:NSKeyValueObservingOptionNew context:NULL];
    [self.view addObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) options:NSKeyValueObservingOptionNew context:NULL];
    
    self.toolbar = ({
        UIToolbar *toolbar = [[UIToolbar alloc] init];
        toolbar.frame = CGRectMake(0.f, 0.f, 0.f, [toolbar intrinsicContentSize].height);
        toolbar.translatesAutoresizingMaskIntoConstraints = NO;
        toolbar.hidden = !self.toolbarEnabled;
        [self.view addSubview:toolbar];
        [toolbar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
        [toolbar.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
        [toolbar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
        toolbar;
    });
    [self updateToolbarItems];
    
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
    
    [Appsee startScreen:@"WebView"];
    [self.loader startAnimation];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.view) {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(canGoBack))] ||
            [keyPath isEqualToString:NSStringFromSelector(@selector(canGoForward))]) {
            [self syncToolbarNavigationItems];
            
        } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(estimatedProgress))]) {
//            NSLog(@"||| %f", self.view.estimatedProgress);
            // TODO: hidding the loader should be done once the estimatedProgress hits above 0.5
            // however we first need to detect if there is a redirect before implementing this
        
        } else {
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        }
    }
}

- (void)dealloc {
    if ([self isViewLoaded]) {
        [self.view removeObserver:self forKeyPath:NSStringFromSelector(@selector(canGoBack))];
        [self.view removeObserver:self forKeyPath:NSStringFromSelector(@selector(canGoForward))];
        [self.view removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress))];
    }
}


#pragma mark - Toolbar

- (void)setToolbarEnabled:(BOOL)toolbarEnabled {
    _toolbarEnabled = toolbarEnabled;
    self.toolbar.hidden = !toolbarEnabled;
}

- (void)updateToolbarItems {
    UIBarButtonItem *fixed = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixed.width = [Geometry padding];
    
    UIBarButtonItem *flexible = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    self.backItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Back"] style:UIBarButtonItemStylePlain target:self action:@selector(backAction)];
    
    self.forwardItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Forward"] style:UIBarButtonItemStylePlain target:self action:@selector(forwardAction)];
    
    [self syncToolbarNavigationItems];
    
    UIBarButtonItem *refresh = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Refresh"] style:UIBarButtonItemStylePlain target:self action:@selector(refreshAction)];
    
    UIBarButtonItem *share = ({
        UIBarButtonItem *item;
        
        if (_isShorteningUrl) {
            UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
            [activityIndicatorView startAnimating];
            
            item = [[UIBarButtonItem alloc] initWithCustomView:activityIndicatorView];
            
        } else {
            item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareAction)];
        }
        
        item;
    });
    
    UIBarButtonItem *safari = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Safari"] style:UIBarButtonItemStylePlain target:self action:@selector(safariAction)];
    
    self.toolbar.items = @[self.backItem, fixed, self.forwardItem, fixed, refresh, flexible, share, fixed, safari];
}

- (void)syncToolbarNavigationItems {
    self.backItem.enabled = [self.view canGoBack];
    self.forwardItem.enabled = [self.view canGoForward];
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
    if (![self.loader isHidden]) {
        [self.loader stopAnimation];
        self.loader.hidden = YES;
    }
    
//    [self syncToolbarNavigationItems];
}


#pragma mark - Actions

- (void)backAction {
    [self.view goBack];
}

- (void)forwardAction {
    [self.view goForward];
}

- (void)refreshAction {
    [self.view reload];
    
    [AnalyticsManager track:@"Refreshed webpage" properties:@{@"url": self.url.absoluteString}];
}

- (void)shareAction {
    _isShorteningUrl = YES;
    [self updateToolbarItems];
    
    [NetworkingModel shortenUrl:self.url completion:^(NSURL * _Nullable url) {
        if (url) {
            UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[url] applicationActivities:nil];
            [self presentViewController:controller animated:YES completion:nil];
        }
        
        _isShorteningUrl = NO;
        [self updateToolbarItems];
    }];
    
    [AnalyticsManager track:@"Shared webpage" properties:@{@"url": self.url.absoluteString}];
}

- (void)safariAction {
    [[UIApplication sharedApplication] openURL:self.url options:@{} completionHandler:nil];
    
    [AnalyticsManager track:@"Opened webpage in Safari" properties:@{@"url": self.url.absoluteString}];
}

@end
