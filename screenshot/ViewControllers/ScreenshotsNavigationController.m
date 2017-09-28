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
            viewController.lifeCycleDelegate = self;
            viewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(presentPickerViewController)];
            viewController.navigationItem.rightBarButtonItem.tintColor = [UIColor crazeRed];
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

- (void)viewController:(UIViewController *)viewController didAppear:(BOOL)animated {
    if (viewController == self.screenshotsViewController) {
        if (![[NSUserDefaults standardUserDefaults] boolForKey:UserDefaultsKeys.onboardingPresentedPushAlert] &&
            ![[NSUserDefaults standardUserDefaults] boolForKey:UserDefaultsKeys.tutorialShouldPresentScreenshotPicker] &&
            [[PermissionsManager sharedPermissionsManager] hasPermissionForType:PermissionTypePhoto])
        {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:UserDefaultsKeys.onboardingPresentedPushAlert];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Start Screenshotting" message:@"Open your favorite apps and take screenshots of photos with clothes, then come back here to shop them!" preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [[PermissionsManager sharedPermissionsManager] requestPermissionForType:PermissionTypePush response:^(BOOL granted) {
                    if (granted) {
                        [AnalyticsTrackers.standard track:@"Accepted Push Permissions"];
                        
                    } else {
                        [AnalyticsTrackers.standard track:@"Denied Push Permissions"];
                    }
                }];
            }]];
            [self presentViewController:alertController animated:YES completion:nil];
        }
    }
}

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
    Screenshot *screenshot = [viewController screenshotAtIndex:indexPath.item];
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

- (void)presentPickerViewController {
    [self presentPickerViewControllerWithCompletion:nil];
}

- (void)presentPickerViewControllerWithCompletion:(dispatch_block_t)completion {
    ScreenshotPickerNavigationController *picker = [[ScreenshotPickerNavigationController alloc] init];
    picker.cancelButton.target = self;
    picker.cancelButton.action = @selector(pickerViewControllerDidCancel);
    picker.doneButton.target = self;
    picker.doneButton.action = @selector(pickerViewControllerDidFinish);
    self.pickerNavigationController = picker;
    
    [self presentViewController:self.pickerNavigationController animated:YES completion:completion];
}

- (void)presentPickerViewControllerIfNeeded {
    BOOL shouldPresent = [[NSUserDefaults standardUserDefaults] boolForKey:UserDefaultsKeys.tutorialShouldPresentScreenshotPicker];
    
    if (shouldPresent) {
        [self presentPickerViewControllerWithCompletion:^{
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:UserDefaultsKeys.tutorialShouldPresentScreenshotPicker];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }];
    }
}

- (void)pickerViewControllerDidCancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)pickerViewControllerDidFinish {
    NSArray<PHAsset *> *assets = [self.pickerNavigationController.screenshotPickerViewController selectedAssets];
    [[AssetSyncModel sharedInstance] syncSelectedPhotosWithAssets:assets];
    
    // Remove picker to reset state
    self.pickerNavigationController = nil;
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
