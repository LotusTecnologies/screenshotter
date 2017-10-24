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

@interface WebViewController () <GameSceneDelegate> {
    BOOL _didViewAppear;
    BOOL _isShorteningUrl;
    BOOL _isShowingGame;
    BOOL _isPlayingGame;
}

@property (nonatomic, strong) UIView *loadingCoverView;
@property (nonatomic, strong) Loader *loader;
@property (nonatomic, strong) UIToolbar *toolbar;

@property (nonatomic) BOOL didLoadInitialPage;

@end

@implementation WebViewController
@dynamic view;


#pragma mark - Life Cycle

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _toolbarEnabled = YES;
        [self setupBarButtonItems];
        
        _loaderLabelText = @"Loading...";
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _webView = ({
        WebView *view = [[WebView alloc] init];
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
    
    [self setBarButtonItemsToToolbarIfPossible];
    
    if (self.url) {
        [self loadRequestUrl:self.url];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!self.didLoadInitialPage) {
        [self showLoadingView];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _didViewAppear = YES;
    
    if (!self.didLoadInitialPage) {
        [self.loader startAnimation:LoaderAnimationPoseThenSpin];
    }
    
    [Appsee startScreen:@"WebView"];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (_isShowingGame) {
        [AnalyticsTrackers.standard track:@"Game Interrupted" properties:@{@"From": @"User Navigating"}];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    _didViewAppear = NO;
    
    [self hideLoadingView];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    if (self.view.window) {
        [self.loader stopAnimation];
        
        if (_isShowingGame) {
            [AnalyticsTrackers.standard track:@"Game Interrupted" properties:@{@"From": @"App Backgrounding"}];
        }
    }
}

- (void)applicationWillEnterForeground:(NSNotification *)notification {
    if (self.view.window) {
        [self.loader startAnimation:LoaderAnimationSpin];
        
        if (_isShowingGame) {
            [AnalyticsTrackers.standard track:@"Game Resumed" properties:@{@"From": @"App Backgrounding"}];
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    BOOL shouldCallSuper = YES;
    
    if (object == self.webView) {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(canGoBack))] ||
            [keyPath isEqualToString:NSStringFromSelector(@selector(canGoForward))]) {
            shouldCallSuper = NO;
            
            [self syncToolbarNavigationItems];
        }
    }
    
    if (shouldCallSuper) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if ([self isViewLoaded]) {
        [self.webView removeObserver:self forKeyPath:NSStringFromSelector(@selector(canGoBack))];
        [self.webView removeObserver:self forKeyPath:NSStringFromSelector(@selector(canGoForward))];
    }
}


#pragma mark - Url

- (void)setUrl:(NSURL *)url {
    _url = url;
    
    if (url && [self isViewLoaded]) {
        [self.webView removeAllBackForwardListItems];
        [self loadRequestUrl:url];
    }
}

- (void)loadRequestUrl:(NSURL *)url {
    self.didLoadInitialPage = NO;
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}


#pragma mark - Toolbar

- (UIToolbar *)toolbar {
    if (!_toolbar) {
        UIToolbar *toolbar = [[UIToolbar alloc] init];
        toolbar.frame = CGRectMake(0.f, 0.f, 0.f, [toolbar intrinsicContentSize].height);
        toolbar.translatesAutoresizingMaskIntoConstraints = NO;
        toolbar.hidden = !self.toolbarEnabled;
        [self.view addSubview:toolbar];
        [toolbar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
        [toolbar.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
        [toolbar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
        _toolbar = toolbar;
        
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
    }
    return _toolbar;
}

- (void)setToolbarEnabled:(BOOL)toolbarEnabled {
    _toolbarEnabled = toolbarEnabled;
    _toolbar.hidden = !toolbarEnabled;
}

- (void)setupBarButtonItems {
    _backItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Back"] style:UIBarButtonItemStylePlain target:self action:@selector(backAction)];
    
    _forwardItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Forward"] style:UIBarButtonItemStylePlain target:self action:@selector(forwardAction)];
    
    [self syncToolbarNavigationItems];
    
    _refreshItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Refresh"] style:UIBarButtonItemStylePlain target:self action:@selector(refreshAction)];
    
    _shareItem = [self createShareItem];
    
    _safariItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Safari"] style:UIBarButtonItemStylePlain target:self action:@selector(safariAction)];
    
    UIColor *color = [UIColor crazeRed];
    self.backItem.tintColor = color;
    self.forwardItem.tintColor = color;
    self.refreshItem.tintColor = color;
    self.safariItem.tintColor = color;
}

- (void)setBarButtonItemsToToolbarIfPossible {
    if (self.toolbarEnabled) {
        UIBarButtonItem *fixed = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        fixed.width = [Geometry padding];
        
        UIBarButtonItem *flexible = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        self.toolbar.items = @[self.backItem, fixed, self.forwardItem, fixed, self.refreshItem, flexible, self.shareItem, fixed, self.safariItem];
    }
}

- (UIBarButtonItem *)createShareItem {
    UIBarButtonItem *item;
    
    if (_isShorteningUrl) {
        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        activityView.color = [UIColor crazeRed];
        [activityView startAnimating];
        
        // Resize the width to the share icon's size to prevent sibling views from jumping
        CGRect rect = activityView.frame;
        rect.size.width = 30.f;
        activityView.frame = rect;
        
        item = [[UIBarButtonItem alloc] initWithCustomView:activityView];
        
    } else {
        item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareAction)];
    }
    
    item.tintColor = [UIColor crazeRed];
    return item;
}

- (void)updateShareItem {
    _shareItem = [self createShareItem];
    [self setBarButtonItemsToToolbarIfPossible];
}

- (void)syncToolbarNavigationItems {
    self.backItem.enabled = [self.webView canGoBack];
    self.forwardItem.enabled = [self.webView canGoForward];
}


#pragma mark - Web View

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    if (!self.didLoadInitialPage) {
        [self showLoadingView];
        
        if (_didViewAppear) {
            [self.loader startAnimation:LoaderAnimationPoseThenSpin];
        }
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    self.didLoadInitialPage = YES;
    
    if (!_isPlayingGame) {
        [self hideLoadingView];
    }
}


#pragma mark - Loading

- (void)showLoadingView {
    if (!self.loadingCoverView) {
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
        loaderLabel.text = self.loaderLabelText;
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
}

- (void)hideLoadingView {
    [self.loadingCoverView removeFromSuperview];
    self.loadingCoverView = nil;
    
    [self.loader stopAnimation];
    self.loader = nil;
    
    if (_isShowingGame) {
        _isShowingGame = NO;
        
        [AnalyticsTrackers.standard track:@"Game Interrupted" properties:@{@"From": @"Page Loading"}];
    }
}


#pragma mark - Game

- (void)showLoadingGame {
    _isShowingGame = YES;
    
    SKView *gameView = [[SKView alloc] init];
    gameView.translatesAutoresizingMaskIntoConstraints = NO;
    gameView.ignoresSiblingOrder = YES;
    [self.loadingCoverView addSubview:gameView];
    [gameView.topAnchor constraintEqualToAnchor:self.loadingCoverView.topAnchor].active = YES;
    [gameView.leadingAnchor constraintEqualToAnchor:self.loadingCoverView.leadingAnchor].active = YES;
    [gameView.bottomAnchor constraintEqualToAnchor:self.loadingCoverView.bottomAnchor].active = YES;
    [gameView.trailingAnchor constraintEqualToAnchor:self.loadingCoverView.trailingAnchor].active = YES;
    
    GameScene *scene = (GameScene *)[GameScene unarchiveFromFile:@"GameScene"];
    scene.gameDelegate = self;
    scene.scaleMode = SKSceneScaleModeAspectFill;
    [gameView presentScene:scene];
    
    [self.loader stopAnimation];
}

- (void)gameSceneDidStartGame:(GameScene *)gameScene {
    _isPlayingGame = YES;
}

- (void)gameSceneDidEndGame:(GameScene *)gameScene {
    _isPlayingGame = NO;
    
    if (self.didLoadInitialPage) {
        [self hideLoadingView];
    }
}


#pragma mark - Actions

- (void)backAction {
    [self.webView goBack];
}

- (void)forwardAction {
    [self.webView goForward];
}

- (void)refreshAction {
    self.webView.URL ? [self.webView reload] : [self setUrl:self.url];
    
    [AnalyticsTrackers.standard track:@"Refreshed webpage" properties:@{@"url": self.url.absoluteString}];
}

- (void)shareAction {
    _isShorteningUrl = YES;
    [self updateShareItem];
    
    [NetworkingModel shortenUrl:self.url completion:^(NSURL * _Nullable url) {
        if (url) {
            UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[url] applicationActivities:nil];
            [self presentViewController:controller animated:YES completion:nil];
        }
        
        _isShorteningUrl = NO;
        [self updateShareItem];
    }];
    
    [AnalyticsTrackers.standard track:@"Shared webpage" properties:@{@"url": self.url.absoluteString}];
}

- (void)safariAction {
    [[UIApplication sharedApplication] openURL:self.url options:@{} completionHandler:nil];
    
    [AnalyticsTrackers.standard track:@"Opened webpage in Safari" properties:@{@"url": self.url.absoluteString}];
}

@end
