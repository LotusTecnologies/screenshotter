//
//  ScreenshotDisplayNavigationController.m
//  screenshot
//
//  Created by Corey Werner on 8/22/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "ScreenshotDisplayNavigationController.h"

@interface ScreenshotDisplayNavigationController ()

@end

@implementation ScreenshotDisplayNavigationController

#pragma mark - Life Cycle

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self.navigationBar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
        self.navigationBar.shadowImage = [[UIImage alloc] init];
        self.navigationBar.translucent = YES;
        self.navigationBar.tintColor = [UIColor whiteColor];
        
        _screenshotDisplayViewController = ({
            UIImage *image = [[UIImage imageNamed:@"LogoHollowC"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            
            UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
            imageView.tintColor = [UIColor whiteColor];
            
            ScreenshotDisplayViewController *viewController = [[ScreenshotDisplayViewController alloc] init];
            viewController.navigationItem.titleView = imageView;
            viewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ControlX"] style:UIBarButtonItemStylePlain target:self action:@selector(closeAction)];
            viewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareAction)];
            viewController;
        });
        
        self.viewControllers = @[self.screenshotDisplayViewController];
    }
    return self;
}


#pragma mark - Actions

- (void)closeAction {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)shareAction {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Screenshot Sharing" message:@"Coming soon." preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
