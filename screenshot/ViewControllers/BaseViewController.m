//
//  BaseViewController.m
//  screenshot
//
//  Created by Corey Werner on 8/8/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "BaseViewController.h"
#import "screenshot-Swift.h"

@interface BaseViewController()

@property (nonatomic) BOOL isStatusBarHidden;

@end

@implementation BaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor background];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([self.lifeCycleDelegate respondsToSelector:@selector(viewController:willAppear:)]) {
        [self.lifeCycleDelegate viewController:self willAppear:animated];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if ([self.lifeCycleDelegate respondsToSelector:@selector(viewController:didAppear:)]) {
        [self.lifeCycleDelegate viewController:self didAppear:animated];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    if ([self.lifeCycleDelegate respondsToSelector:@selector(viewController:willDisappear:)]) {
        [self.lifeCycleDelegate viewController:self willDisappear:animated];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    if ([self.lifeCycleDelegate respondsToSelector:@selector(viewController:didDisappear:)]) {
        [self.lifeCycleDelegate viewController:self didDisappear:animated];
    }
}


#pragma mark - Status Bar

- (BOOL)prefersStatusBarHidden {
    return self.isStatusBarHidden;
}

- (void)showStatusBar {
    self.isStatusBarHidden = NO;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)hideStatusBar {
    self.isStatusBarHidden = YES;
    [self setNeedsStatusBarAppearanceUpdate];
}


#pragma mark - Extra

- (void)addNavigationItemLogo {
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo20h"]];
}

@end
