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

#import <FBSDKCoreKit/FBSDKCoreKit.h>

@interface ScreenshotsNavigationController () <ViewControllerLifeCycle, ScreenshotsViewControllerDelegate, NetworkingIndicatorProtocol>

@property (nonatomic, strong) ScreenshotPickerNavigationController *pickerNavigationController;
@property (nonatomic, strong) ClipView *clipView;

@property (nonatomic, strong, nullable) Class previousDidAppearViewControllerClass;

@end

@implementation ScreenshotsNavigationController

#pragma mark - Life Cycle

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.restorationIdentifier = NSStringFromClass([self class]);
        
        _screenshotsViewController = ({
            ScreenshotsViewController *viewController = [[ScreenshotsViewController alloc] init];
            viewController.delegate = self;
            viewController.lifeCycleDelegate = self;
            viewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"NavigationBarAddPhotos"] style:UIBarButtonItemStylePlain target:self action:@selector(presentPickerViewController)];
            viewController.navigationItem.rightBarButtonItem.tintColor = [UIColor crazeRed];
            viewController;
        });
        
        self.viewControllers = @[self.screenshotsViewController];
        
        [AssetSyncModel sharedInstance].networkingIndicatorDelegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor background];
}

- (void)dealloc {
    [AssetSyncModel sharedInstance].networkingIndicatorDelegate = nil;
}


#pragma mark - View Controller Life Cycle

- (void)viewController:(UIViewController *)viewController didAppear:(BOOL)animated {
    if (viewController == self.screenshotsViewController &&
        self.previousDidAppearViewControllerClass == [ProductsViewController class])
    {
        if ([self needsToPresentPickerViewController]) {
            // Allow the view controller transition view to cleanup
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentPickerClipView];
            });

            // Go back into Products before presenting the next view
            self.previousDidAppearViewControllerClass = nil;

        } else if ([self needsToPresentPushAlert]) {
            [self presentPushAlert];
        }
    }
    
    self.previousDidAppearViewControllerClass = [viewController class];
}


#pragma mark - Screenshots

- (void)screenshotsViewController:(ScreenshotsViewController *)viewController didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    Screenshot *screenshot = [viewController screenshotAtIndex:indexPath.item];
    
    ProductsViewController *productsViewController = [[ProductsViewController alloc] init];
    productsViewController.lifeCycleDelegate = self;
    productsViewController.hidesBottomBarWhenPushed = YES;
    productsViewController.screenshot = screenshot;
    [self pushViewController:productsViewController animated:YES];
    
    if (screenshot.isNew) {
        [screenshot setViewed];
    }
    
    [[RatingFlow sharedInstance] recordSignificantEvent];
}

- (void)screenshotsViewControllerDeletedLastScreenshot:(ScreenshotsViewController *)viewController {
    if ([self needsToPresentPickerViewController]) {
        [self presentPickerClipView];
    }
}

- (void)screenshotsViewControllerWantsToPresentPicker:(ScreenshotsViewController *)viewController {
    [self presentPickerViewController];
}


#pragma mark - Screenshot Picker

- (BOOL)needsToPresentPickerViewController {
    return ![[NSUserDefaults standardUserDefaults] boolForKey:UserDefaultsKeys.onboardingPresentedScreenshotPicker];
}

- (void)presentPickerViewController {
    [self dismissPickerClipView];
    
    ScreenshotPickerNavigationController *picker = [[ScreenshotPickerNavigationController alloc] init];
    picker.cancelButton.target = self;
    picker.cancelButton.action = @selector(pickerViewControllerDidCancel);
    picker.doneButton.target = self;
    picker.doneButton.action = @selector(pickerViewControllerDidFinish);
    self.pickerNavigationController = picker;
    
    [self presentViewController:self.pickerNavigationController animated:YES completion:nil];
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:UserDefaultsKeys.onboardingPresentedScreenshotPicker];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [AnalyticsTrackers.standard track:@"Opened Picker" properties:nil];
}

- (void)pickerViewControllerDidCancel {
    [self dismissViewControllerAnimated:YES completion:^{
        if ([self needsToPresentPushAlert]) {
            [self presentPushAlert];
        }
    }];
}

- (void)pickerViewControllerDidFinish {
    // Remove picker to reset state
    self.pickerNavigationController = nil;
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Push Permission

- (BOOL)needsToPresentPushAlert {
    return ![[NSUserDefaults standardUserDefaults] boolForKey:UserDefaultsKeys.onboardingPresentedPushAlert] && [[PermissionsManager shared] _hasPhotoPermission];
}

- (void)presentPushAlert {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Start Screenshotting" message:@"Open your favorite apps and take screenshots of photos with clothes, then come back here to shop them!" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[PermissionsManager shared] _requestPushPermissionWithResponse:^(BOOL granted) {
            if (granted) {
                [self.screenshotsNavigationControllerDelegate screenshotsNavigationControllerDidGrantPushPermissions:self];
                
                [AnalyticsTrackers.standard track:@"Accepted Push Permissions" properties:nil];
                
            } else {
                [AnalyticsTrackers.standard track:@"Denied Push Permissions" properties:nil];
            }
        }];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:UserDefaultsKeys.onboardingPresentedPushAlert];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


#pragma mark - Networking Indicator

- (void)networkingIndicatorDidStartWithType:(enum NetworkingIndicatorType)type {
    if (!self.screenshotsViewController.navigationItem.leftBarButtonItem) {
        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        activityView.color = [UIColor crazeRed];
        [activityView startAnimating];
        
        self.screenshotsViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityView];
    }
    
    self.screenshotsViewController.navigationItem.leftBarButtonItem.tag += 1;
}

- (void)networkingIndicatorDidCompleteWithType:(enum NetworkingIndicatorType)type {
    self.screenshotsViewController.navigationItem.leftBarButtonItem.tag -= 1;
    
    if (self.screenshotsViewController.navigationItem.leftBarButtonItem.tag == 0) {
        self.screenshotsViewController.navigationItem.leftBarButtonItem = nil;
    }
}


#pragma mark - Clip View

- (void)presentPickerClipView {
    if (!self.clipView) {
        UIView *rightBarButtonView = self.screenshotsViewController.navigationItem.rightBarButtonItem.targetView;
        CGRect rect = [rightBarButtonView.superview convertRect:rightBarButtonView.frame toView:self.view];
        CGFloat radius = MIN(rect.size.height / 2.f, rect.size.width / 2.f);
        UIBezierPath *croppedPath = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:radius];
        
        UIView *tabBarView = self.tabBarController.view;
        
        ClipView *clipView = [[ClipView alloc] init];
        clipView.translatesAutoresizingMaskIntoConstraints = NO;
        clipView.clippings = @[croppedPath];
        clipView.alpha = 0.f;
        [tabBarView addSubview:clipView];
        [clipView.topAnchor constraintEqualToAnchor:tabBarView.topAnchor].active = YES;
        [clipView.leadingAnchor constraintEqualToAnchor:tabBarView.leadingAnchor].active = YES;
        [clipView.bottomAnchor constraintEqualToAnchor:tabBarView.bottomAnchor].active = YES;
        [clipView.trailingAnchor constraintEqualToAnchor:tabBarView.trailingAnchor].active = YES;
        self.clipView = clipView;
        
        [UIView animateWithDuration:Constants.defaultAnimationDuration animations:^{
            self.clipView.alpha = 1.f;
        }];
    }
}

- (void)dismissPickerClipView {
    if (self.clipView) {
        [UIView animateWithDuration:Constants.defaultAnimationDuration animations:^{
            self.clipView.alpha = 0.f;
            
        } completion:^(BOOL finished) {
            [self.clipView removeFromSuperview];
            self.clipView = nil;
        }];
    }
}


#pragma mark - Restoration

- (void)restoreScreenshotPickerNavigationController:(ScreenshotPickerNavigationController *)controller {
    controller.cancelButton.target = self;
    controller.cancelButton.action = @selector(pickerViewControllerDidCancel);
    controller.doneButton.target = self;
    controller.doneButton.action = @selector(pickerViewControllerDidFinish);
}

@end
