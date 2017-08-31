//
//  ProductsPageHelperViewController.m
//  screenshot
//
//  Created by Corey Werner on 8/31/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "ProductsPageHelperViewController.h"

@interface ProductsPageHelperView : UIView

@end

@interface ProductsPageHelperViewController ()

@end

@implementation ProductsPageHelperView

//- (CGSize)intrinsicContentSize {
//    return CGSizeMake(UIViewNoIntrinsicMetric, 300);
//}

@end

@implementation ProductsPageHelperViewController

- (void)loadView {
    self.view = [[ProductsPageHelperView alloc] init];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor redColor];
    
    UIView *v = [[UIView alloc] init];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    v.backgroundColor = [UIColor greenColor];
    [self.view addSubview:v];
    [v.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:10].active = YES;
    [v.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:10].active = YES;
    [v.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-10].active = YES;
    [v.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-10].active = YES;
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(d)]];
}

- (void)d {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
