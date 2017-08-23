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
#import "UIColor+Appearance.h"
#import "screenshot-Swift.h"
#import "LoadingViewController.h"
#import "UserDefaultsConstants.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
@import Analytics;
@import Appsee;

@interface AppDelegate () <TutorialViewControllerDelegate>

@property (assign, nonatomic) UIBackgroundTaskIdentifier bgTask;

@end

@implementation AppDelegate

#pragma mark - Life Cycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [DataModel setup]; // Sets up Core Data stack on a background queue.
    [ClarifaiModel setup]; // Takes a long time to intialize; start early.
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
    NSLog(@"application performFetchWithCompletionHandler");
    
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
    
    [[FBSDKApplicationDelegate sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];
}


#pragma mark - Appearance

- (void)setupApplicationAppearance {
    UIColor *crazeRedColor = [UIColor crazeRedColor];
    
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
        TutorialViewController *tutorialViewController = [[TutorialViewController alloc] init];
        tutorialViewController.delegate = self;
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
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:UserDefaultsTutorialCompleted];
    
    [self prepareDataStackCompletionIfNeeded];
    [self transitionToViewController:[self nextViewController]];
}

@end
