//
//  ScreenshotsNavigationController.m
//  screenshot
//
//  Created by Corey Werner on 8/8/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "ScreenshotsNavigationController.h"
#import "ScreenshotsViewController.h"
#import "ProductsViewController.h"
#import "WebViewController.h"
#import "UIColor+Appearance.h"

@interface ScreenshotsNavigationController () <ScreenshotsViewControllerDelegate, ProductsViewControllerDelegate>

@property (nonatomic, strong) ScreenshotsViewController *screenshotsViewController;

@end

@implementation ScreenshotsNavigationController

#pragma mark - Life Cycle

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.screenshotsViewController = ({
            ScreenshotsViewController *viewController = [[ScreenshotsViewController alloc] init];
            viewController.delegate = self;
            viewController;
        });
        
        self.viewControllers = @[self.screenshotsViewController];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor backgroundColor];
}


#pragma mark - Screenshots View Controller

- (void)screenshotsViewController:(ScreenshotsViewController *)viewController didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    ProductsViewController *productsViewController = [[ProductsViewController alloc] init];
    productsViewController.delegate = self;
    productsViewController.screenshot = [viewController screenshotAtIndexPath:indexPath];
    
    [self pushViewController:productsViewController animated:YES];
}


#pragma mark - Products View Controller

- (void)productsViewController:(ProductsViewController *)viewController didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    WebViewController *webViewController = [[WebViewController alloc] init];
    [webViewController addNavigationItemLogo];
    webViewController.hidesBottomBarWhenPushed = YES;
    webViewController.url = [NSURL URLWithString:[viewController productAtIndexPath:indexPath].offer];
    
    [self pushViewController:webViewController animated:YES];
}

@end
