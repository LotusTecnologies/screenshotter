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
#import "UIColor+Appearance.h"

@interface ScreenshotsNavigationController () <ScreenshotsViewControllerDelegate>

@property (nonatomic, strong) ScreenshotsViewController *screenshotsViewController;

@end

@implementation ScreenshotsNavigationController

#pragma mark - Life Cycle

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _screenshotsViewController = ({
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
    productsViewController.screenshot = [viewController screenshotAtIndexPath:indexPath];
    
    if (productsViewController.hasShoppables) {
        [self pushViewController:productsViewController animated:YES];
    } else {
        UIAlertController *alert =[UIAlertController alertControllerWithTitle:@"Sorry"
                                                                      message:@"We had a problem with this screenshot."
                                                               preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK"
                                                                style:UIAlertActionStyleDefault
                                                              handler:nil];
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

@end
