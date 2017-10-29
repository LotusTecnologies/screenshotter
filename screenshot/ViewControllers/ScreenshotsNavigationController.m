//
//  ScreenshotsNavigationController.m
//  screenshot
//
//  Created by Corey Werner on 8/8/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "ScreenshotsNavigationController.h"
#import "ProductsViewController.h"
#import "WebViewController.h"
#import "screenshot-Swift.h"

@interface ScreenshotsNavigationController () <ViewControllerLifeCycle, ScreenshotsViewControllerDelegate, ProductsViewControllerDelegate, NetworkingIndicatorProtocol>

@property (nonatomic, strong) ScreenshotPickerNavigationController *pickerNavigationController;
@property (nonatomic, strong) WebViewController *webViewController;
@property (nonatomic, strong, nullable) Class previousViewControllerClass;

@end

@implementation ScreenshotsNavigationController
@dynamic delegate;


#pragma mark - Life Cycle

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
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
    if ([viewController isKindOfClass:[ScreenshotsViewController class]] && self.previousViewControllerClass == [ProductsViewController class]) {
        [self presentAppropriateModalViewControllerIfNecessary];
    }
    
    self.previousViewControllerClass = [viewController class];
}


#pragma mark - Screenshots View Controller

- (void)screenshotsViewController:(ScreenshotsViewController *)viewController didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    Screenshot *screenshot = [viewController screenshotAtIndex:indexPath.item];
    
    ProductsViewController *productsViewController = [[ProductsViewController alloc] init];
    productsViewController.delegate = self;
    productsViewController.lifeCycleDelegate = self;
    productsViewController.hidesBottomBarWhenPushed = YES;
    productsViewController.screenshot = screenshot;
    [self pushViewController:productsViewController animated:YES];
    
    [screenshot setViewed];
    [[RatingFlow sharedInstance] recordSignificantEvent];
}

- (void)screenshotsViewControllerDeletedLastScreenshot:(ScreenshotsViewController *)viewController {
    [self presentPickerViewControllerWithCompletion:nil];
}


#pragma mark - Products View Controller

- (void)productsViewController:(ProductsViewController *)viewController didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    Product *product = [viewController productAtIndex:indexPath.item];
    
    self.webViewController.url = [NSURL URLWithString:product.offer];
    [self pushViewController:self.webViewController animated:YES];
}

#pragma mark -

- (void)presentAppropriateModalViewControllerIfNecessary {
    if ([self canPresentPickerViewController]) {
        [self presentPickerViewController];
    } else if ([self canPresentPushPermissionsVC]) {
        [self presentPushPermissionsViewController];
    }
}

#pragma mark - Screenshots Picker

- (BOOL)canPresentPushPermissionsVC {
    return [[NSUserDefaults standardUserDefaults] boolForKey:UserDefaultsKeys.onboardingPresentedPushPermissionsPage] == NO;
}

- (BOOL)canPresentPickerViewController {
    return [[NSUserDefaults standardUserDefaults] boolForKey:UserDefaultsKeys.tutorialShouldPresentScreenshotPicker];
}

- (void)presentPushPermissionsViewController {
    UIViewController *controller = [[InvokeScreenshotViewController alloc] init];
    [self presentViewController:controller animated:YES completion:^{
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:UserDefaultsKeys.onboardingPresentedPushPermissionsPage];
    }];
}

- (void)presentPickerViewController {
    [self presentPickerViewControllerWithCompletion:^{
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:UserDefaultsKeys.tutorialShouldPresentScreenshotPicker];
    }];
}

- (void)presentPickerViewControllerWithCompletion:(dispatch_block_t)completion {
    ScreenshotPickerNavigationController *picker = [[ScreenshotPickerNavigationController alloc] init];
    picker.cancelButton.target = self;
    picker.cancelButton.action = @selector(pickerViewControllerDidCancel);
    picker.doneButton.target = self;
    picker.doneButton.action = @selector(pickerViewControllerDidFinish);
    self.pickerNavigationController = picker;
    
    [self presentViewController:self.pickerNavigationController animated:YES completion:completion];
    
    [AnalyticsTrackers.standard track:@"Opened Picker"];
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    [super dismissViewControllerAnimated:flag completion:completion];
}

- (void)pickerViewControllerDidCancel {
    [self dismissViewControllerAnimated:YES completion:^{
        [self presentAppropriateModalViewControllerIfNecessary];
    }];
}

- (void)pickerViewControllerDidFinish {
    // Remove picker to reset state
    self.pickerNavigationController = nil;
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Web View

- (WebViewController *)webViewController {
    if (!_webViewController) {
        WebViewController *webViewController = [[WebViewController alloc] init];
        [webViewController addNavigationItemLogo];
        webViewController.hidesBottomBarWhenPushed = YES;
        webViewController.loaderLabelText = @"Loading your store...";
        _webViewController = webViewController;
    }
    return _webViewController;
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

@end
