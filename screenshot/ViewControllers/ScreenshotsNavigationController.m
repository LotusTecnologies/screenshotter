//
//  ScreenshotsNavigationController.m
//  screenshot
//
//  Created by Corey Werner on 8/8/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "ScreenshotsNavigationController.h"
#import "ProductsViewController.h"
#import "screenshot-Swift.h"

@interface ScreenshotsNavigationController () <ViewControllerLifeCycle, ScreenshotsViewControllerDelegate>

@property (nonatomic, strong) ScreenshotPickerNavigationController *pickerNavigationController;

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
    
    self.view.backgroundColor = [UIColor background];
}


#pragma mark - View Controller Life Cycle

- (void)viewController:(UIViewController *)viewController didDisappear:(BOOL)animated {
    if ([viewController isKindOfClass:[ProductsViewController class]]) {
        [self presentPickerViewControllerIfNeeded];
    }
}


#pragma mark - Screenshots View Controller

- (void)screenshotsViewController:(ScreenshotsViewController *)viewController didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    ProductsViewController *productsViewController = [[ProductsViewController alloc] init];
    productsViewController.lifeCycleDelegate = self;
    productsViewController.hidesBottomBarWhenPushed = YES;
    Screenshot *screenshot = [viewController screenshotAtIndexPath:indexPath];
    productsViewController.screenshot = screenshot;
    
    if ([productsViewController hasShoppables]) {
        [self pushViewController:productsViewController animated:YES];
        [screenshot setViewed];
        [[RatingFlow sharedInstance] recordSignificantEvent];
        
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Sorry"
                                                                      message:@"We had a problem with this screenshot."
                                                               preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK"
                                                                style:UIAlertActionStyleDefault
                                                              handler:nil];
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)screenshotsViewControllerDeletedLastScreenshot:(ScreenshotsViewController *)viewController {
    [self presentPickerViewControllerIfNeeded];
}


#pragma mark - Screenshots Picker

- (ScreenshotPickerNavigationController *)pickerNavigationController {
    if (!_pickerNavigationController) {
        _pickerNavigationController = [[ScreenshotPickerNavigationController alloc] init];
        _pickerNavigationController.cancelButton.target = self;
        _pickerNavigationController.cancelButton.action = @selector(pickerViewControllerDidCancel);
        _pickerNavigationController.doneButton.target = self;
        _pickerNavigationController.doneButton.action = @selector(pickerViewControllerDidFinish);
    }
    return _pickerNavigationController;
}

- (void)presentPickerViewControllerIfNeeded {
    BOOL didPresent = [[NSUserDefaults standardUserDefaults] boolForKey:UserDefaultsKeys.tutorialPresentedScreenshotPicker];
    
    if (!didPresent) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:UserDefaultsKeys.tutorialPresentedScreenshotPicker];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self presentViewController:self.pickerNavigationController animated:YES completion:nil];
    }
}

- (void)pickerViewControllerDidCancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)pickerViewControllerDidFinish {
    NSArray<PHAsset *> *assets = [self.pickerNavigationController.screenshotPickerViewController selectedAssets];
    [[AssetSyncModel sharedInstance] syncSelectedPhotosWithAssets:assets];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
