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
#import "screenshot-Swift.h"

@import Appsee;
@import WebKit;
@import SpriteKit;

@interface WebViewController () {
    BOOL _isShorteningUrl;
}

@property (nonatomic, strong) UIView *loadingCoverView;
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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _webView = ({
        WKWebView *view = [[WKWebView alloc] init];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        view.navigationDelegate = self;
        [self.view addSubview:view];
        [view.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
        [view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
        [view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
        [view.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
        
        [view addObserver:self forKeyPath:NSStringFromSelector(@selector(canGoBack)) options:NSKeyValueObservingOptionNew context:NULL];
        [view addObserver:self forKeyPath:NSStringFromSelector(@selector(canGoForward)) options:NSKeyValueObservingOptionNew context:NULL];
        view;
    });
    
    _toolbar = ({
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
    
    self.webView.scrollView.contentInset = ({
        UIEdgeInsets insets = self.webView.scrollView.contentInset;
        insets.bottom = self.toolbar.bounds.size.height;
        insets;
    });

    self.webView.scrollView.scrollIndicatorInsets = ({
        UIEdgeInsets insets = self.webView.scrollView.scrollIndicatorInsets;
        insets.bottom = self.toolbar.bounds.size.height;
        insets;
    });
    
    [self showLoadingView];
    
    if (self.url) {
        [self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [Appsee startScreen:@"WebView"];
    [self.loader startAnimation:LoaderAnimationPoseThenSpin];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.webView) {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(canGoBack))] ||
            [keyPath isEqualToString:NSStringFromSelector(@selector(canGoForward))]) {
            [self syncToolbarNavigationItems];
            
        } else {
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        }
    }
}

- (void)dealloc {
    if ([self isViewLoaded]) {
        [self.webView removeObserver:self forKeyPath:NSStringFromSelector(@selector(canGoBack))];
        [self.webView removeObserver:self forKeyPath:NSStringFromSelector(@selector(canGoForward))];
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
    self.backItem.enabled = [self.webView canGoBack];
    self.forwardItem.enabled = [self.webView canGoForward];
}


#pragma mark - Url

- (void)setUrl:(NSURL *)url {
    _url = url;
    
    if (url && [self isViewLoaded]) {
        [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    }
}


#pragma mark - Web View

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self hideLoadingView];
}


#pragma mark - Loading

- (void)showLoadingView {
    _loadingCoverView = ({
        UIView *view = [[UIView alloc] init];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        view.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:view];
        [view.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor].active = YES;
        [view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
        [view.bottomAnchor constraintEqualToAnchor:self.bottomLayoutGuide.topAnchor].active = YES;
        [view.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
        view;
    });
    
    _loader = ({
        Loader *loader = [[Loader alloc] init];
        loader.translatesAutoresizingMaskIntoConstraints = NO;
        [self.loadingCoverView addSubview:loader];
        [loader.centerXAnchor constraintEqualToAnchor:self.loadingCoverView.centerXAnchor].active = YES;
        [NSLayoutConstraint constraintWithItem:loader attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.loadingCoverView attribute:NSLayoutAttributeCenterY multiplier:0.8f constant:0.f].active = YES;
        loader;
    });
    
    CGFloat padding = [Geometry padding];
    
    UILabel *loaderLabel = [[UILabel alloc] init];
    loaderLabel.translatesAutoresizingMaskIntoConstraints = NO;
    loaderLabel.text = @"Loading your store...";
    loaderLabel.textColor = [UIColor gray6];
    loaderLabel.textAlignment = NSTextAlignmentCenter;
    loaderLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    [self.loadingCoverView addSubview:loaderLabel];
    [loaderLabel.topAnchor constraintEqualToAnchor:self.loader.bottomAnchor constant:padding].active = YES;
    [loaderLabel.leadingAnchor constraintEqualToAnchor:self.loadingCoverView.leadingAnchor constant:padding].active = YES;
    [loaderLabel.trailingAnchor constraintEqualToAnchor:self.loadingCoverView.trailingAnchor constant:-padding].active = YES;
    
    MainButton *button = [MainButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.backgroundColor = [UIColor crazeGreen];
    [button setTitle:@"Get More Coins" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(showLoadingGame) forControlEvents:UIControlEventTouchUpInside];
    [self.loadingCoverView addSubview:button];
    [button.bottomAnchor constraintEqualToAnchor:self.loadingCoverView.bottomAnchor constant:-[Geometry extendedPadding]].active = YES;
    [button.centerXAnchor constraintEqualToAnchor:self.loadingCoverView.centerXAnchor].active = YES;
}

- (void)hideLoadingView {
    [self.loadingCoverView removeFromSuperview];
    self.loadingCoverView = nil;
    
    [self.loader stopAnimation];
    self.loader = nil;
}

- (void)showLoadingGame {
    SKView *gameView = [[SKView alloc] init];
    gameView.translatesAutoresizingMaskIntoConstraints = NO;
    gameView.ignoresSiblingOrder = YES;
    [self.loadingCoverView addSubview:gameView];
    [gameView.topAnchor constraintEqualToAnchor:self.loadingCoverView.topAnchor].active = YES;
    [gameView.leadingAnchor constraintEqualToAnchor:self.loadingCoverView.leadingAnchor].active = YES;
    [gameView.bottomAnchor constraintEqualToAnchor:self.loadingCoverView.bottomAnchor].active = YES;
    [gameView.trailingAnchor constraintEqualToAnchor:self.loadingCoverView.trailingAnchor].active = YES;
    
    GameScene *scene = (GameScene *)[GameScene unarchiveFromFile:@"GameScene"];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    [gameView presentScene:scene];
    
    [self.loader stopAnimation];
}


#pragma mark - Actions

- (void)backAction {
    [self.webView goBack];
}

- (void)forwardAction {
    [self.webView goForward];
}

- (void)refreshAction {
    [self.webView reload];
    
    [AnalyticsTrackers.standard track:@"Refreshed webpage" properties:@{@"url": self.url.absoluteString}];
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
    
    [AnalyticsTrackers.standard track:@"Shared webpage" properties:@{@"url": self.url.absoluteString}];
}

- (void)safariAction {
    [[UIApplication sharedApplication] openURL:self.url options:@{} completionHandler:nil];
    
    [AnalyticsTrackers.standard track:@"Opened webpage in Safari" properties:@{@"url": self.url.absoluteString}];
}

@end
