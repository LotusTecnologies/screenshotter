//
//  LoadingViewController.m
//  screenshot
//
//  Created by Corey Werner on 8/23/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "LoadingViewController.h"
#import "Loader.h"

@interface LoadingViewController ()

@property (nonatomic, strong) Loader *loader;

@end

@implementation LoadingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    Loader *loader = [[Loader alloc] init];
    loader.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:loader];
    [loader.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    [loader.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor].active = YES;
    self.loader = loader;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.loader startAnimation:LoaderAnimationSpin];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self.loader stopAnimation];
}

@end
