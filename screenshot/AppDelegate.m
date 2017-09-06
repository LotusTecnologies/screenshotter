//
//  AppDelegate.m
//  screenshot
//
//  Created by Gershon Kagan on 6/29/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

#import "AppDelegate.h"
#import "MainTabBarController.h"
#import "TutorialViewController.h"
#import "PermissionsManager.h"
#import "UIDevice+Model.h"
#import "screenshot-Swift.h"
#import "LoadingViewController.h"
#import "UserDefaultsConstants.h"
#import "ScreenshotsNavigationController.h"
#import "AnalyticsManager.h"
#import "UIApplication+Version.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
@import Analytics;
@import Appsee;
@import UserNotifications;

@interface AppDelegate () <UNUserNotificationCenterDelegate, TutorialViewControllerDelegate>

@property (assign, nonatomic) UIBackgroundTaskIdentifier bgTask;

@end

@implementation AppDelegate

#pragma mark - Life Cycle

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    UNUserNotificationCenter.currentNotificationCenter.delegate = self;
    [ClarifaiModel setup]; // Takes a long time to intialize; start early.
    [DataModel setup]; // Sets up Core Data stack on a background queue.
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[PermissionsManager sharedPermissionsManager] fetchPushPermissionStatus];
    
    [self setupThirdPartyLibrariesWithApplication:application didFinishLaunchingWithOptions:launchOptions];
    [self setupApplicationAppearance];
    
    [self prepareDataStackCompletionIfNeeded];
    
    self.window = ({
        UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        window.rootViewController = [self nextViewController];
        [window makeKeyAndVisible];
        window;
    });
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    self.bgTask = [application beginBackgroundTaskWithName:@"stallBaby" expirationHandler:^{
        // Clean up any unfinished task business by marking where you
        // stopped or ending the task outright.
        [application endBackgroundTask:self.bgTask];
        self.bgTask = UIBackgroundTaskInvalid;
    }];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    [FBSDKAppEvents activateApp];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {    
    if (completionHandler) {
        completionHandler(UIBackgroundFetchResultNoData);
    }
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    BOOL handled = [[FBSDKApplicationDelegate sharedInstance] application:application openURL:url sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey] annotation:options[UIApplicationOpenURLOptionsAnnotationKey]
                    ];
    // Add any custom logic here.
    return handled;
}


#pragma mark - Third Party

- (void)setupThirdPartyLibrariesWithApplication:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [SEGAnalytics setupWithConfiguration:({
        SEGAnalyticsConfiguration *configuration = [SEGAnalyticsConfiguration configurationWithWriteKey:@"RWoeJieRzzEBZ4GYG3bflJdTMyXHs5Fn"];
        configuration.trackApplicationLifecycleEvents = YES;
        configuration.recordScreenViews = YES;
        configuration.trackDeepLinks = YES;
        configuration.trackPushNotifications = YES;
        configuration;
    })];
    
#ifdef DEBUG
    [Appsee start:@"d9010050cea04490b6b9cdd795849dd4"];
#else
    [Appsee start:@"0ece18b50f7d4ef9aae3e473c28030bc"];
#endif
    
    [Appsee addEvent:@"App Launched" withProperties:@{@"version": [UIApplication versionBuild]}];
    
    [[FBSDKApplicationDelegate sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];
}


#pragma mark - Appearance

- (void)setupApplicationAppearance {
    UIColor *crazeRedColor = [UIColor crazeRed];
    
    [[UINavigationBar appearance] setTintColor:[UIColor gray6]];
    [[UINavigationBar appearance] setTitleTextAttributes:({
        @{NSFontAttributeName: [UIFont fontWithName:@"Futura-Medium" size:20.0],
          NSForegroundColorAttributeName: [UIColor gray3]
          };
    })];
    
    [[UIBarButtonItem appearance] setTitleTextAttributes:({
        @{NSFontAttributeName: [UIFont fontWithName:@"Futura" size:16.0],
          };
    }) forState:UIControlStateNormal];
    
    [[UITabBar appearance] setTintColor:crazeRedColor];
    
    [[UIToolbar appearance] setTintColor:crazeRedColor];
    
    [[UIActivityIndicatorView appearanceWhenContainedInInstancesOfClasses:@[[UIToolbar class]]] setColor:crazeRedColor];
}


#pragma mark - View Controllers

- (UIViewController *)nextViewController {
    UIViewController *viewController;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:UserDefaultsTutorialCompleted]) {
        if ([DataModel sharedInstance].isCoreDataStackReady) {
            viewController = [[MainTabBarController alloc] init];
            
        } else {
            viewController = [[LoadingViewController alloc] init];
        }
        
    } else {
        UIEdgeInsets insets = UIEdgeInsetsZero;
        insets.top = [UIDevice is568h] ? 0.f : 30.f;
        
        TutorialViewController *tutorialViewController = [[TutorialViewController alloc] init];
        tutorialViewController.delegate = self;
        tutorialViewController.contentLayoutMargins = insets;
        viewController = tutorialViewController;
    }
    
    return viewController;
}

- (void)prepareDataStackCompletionIfNeeded {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:UserDefaultsTutorialCompleted]) {
        if ([DataModel sharedInstance].isCoreDataStackReady) {
            [[AssetSyncModel sharedInstance] syncPhotos];
            
        } else {
            [DataModel sharedInstance].coreDataStackCompletionHandler = ^{
                [[AssetSyncModel sharedInstance] syncPhotos];
                [self transitionToViewController:[self nextViewController]];
            };
            
            [DataModel sharedInstance].coreDataStackFailureHandler = ^{
                // TODO:
            };
        }
    }
}

- (void)transitionToViewController:(UIViewController *)toViewController {
    UIViewAnimationOptions options = UIViewAnimationOptionTransitionFlipFromLeft | UIViewAnimationOptionAllowAnimatedContent | UIViewAnimationOptionLayoutSubviews;
    
    [UIView transitionFromView:self.window.rootViewController.view toView:toViewController.view duration:0.5f options:options completion:^(BOOL finished) {
        self.window.rootViewController = toViewController;
    }];
}


#pragma mark - Tutorial

- (void)tutorialViewControllerDidComplete:(TutorialViewController *)viewController {
    viewController.delegate = nil;
    
    [self prepareDataStackCompletionIfNeeded];
    
    // Create a delay for a more natural feel after taking the screentshot
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self transitionToViewController:[self nextViewController]];
    });
}


#pragma mark - UNUserNotificationCenterDelegate

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler {
    NSDictionary *userInfo = response.notification.request.content.userInfo;
    
    if (userInfo) {
        NSString *openingScreen = userInfo[Constants.openingScreenKey];
        
        if ([openingScreen isEqualToString:Constants.openingScreenValueScreenshot]) {
            MainTabBarController *mainTabBarController = (MainTabBarController *)self.window.rootViewController;
            
            if ([mainTabBarController isKindOfClass:[MainTabBarController class]]) {
                [mainTabBarController.screenshotsNavigationController popToRootViewControllerAnimated:NO];
                [mainTabBarController.screenshotsNavigationController.screenshotsViewController scrollTopTop];
                mainTabBarController.selectedViewController = mainTabBarController.screenshotsNavigationController;
            }
        }
    }
    
    if (completionHandler) {
        completionHandler();
    }
    
    [AnalyticsManager track:@"app opened from local notification"];
}

@end
