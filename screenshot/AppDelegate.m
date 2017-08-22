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
    [ClarifaiModel setup]; // Takes a long time to intialize; start early. Also uses its own queue.
    [SEGAnalytics setupWithConfiguration:({
        SEGAnalyticsConfiguration *configuration = [SEGAnalyticsConfiguration configurationWithWriteKey:@"RWoeJieRzzEBZ4GYG3bflJdTMyXHs5Fn"];
        configuration.trackApplicationLifecycleEvents = YES;
        configuration.recordScreenViews = YES;
        configuration.trackDeepLinks = YES;
        configuration.trackPushNotifications = YES;
        configuration;
    })];
    
    [Appsee start:@"7fb11213125444f9bd1b18140c5dd782"];
    
    [[FBSDKApplicationDelegate sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];
    
    NSLog(@"didFinishLaunchingWithOptions starting syncPhotos");
    [AssetSyncModel.sharedInstance syncPhotos];
    NSLog(@"didFinishLaunchingWithOptions completed syncPhotos");
    
    [[PermissionsManager sharedPermissionsManager] fetchPushPermissionStatus];
    
    [self setupApplicationAppearance];
    
    self.window = ({
        UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"Tutorial"]) {
            window.rootViewController = [[MainTabBarController alloc] init];
            
        } else {
            TutorialViewController *viewController = [[TutorialViewController alloc] init];
            viewController.delegate = self;
            window.rootViewController = viewController;
        }
        
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


#pragma mark - Appearance

- (void)setupApplicationAppearance {
    UIColor *crazeRedColor = [UIColor crazeRedColor];
    
    [[UITabBar appearance] setTintColor:crazeRedColor];
    [[UIToolbar appearance] setTintColor:crazeRedColor];
    [[UIActivityIndicatorView appearanceWhenContainedInInstancesOfClasses:@[[UIToolbar class]]] setColor:crazeRedColor];
}


#pragma mark - Tutorial

- (void)tutorialViewControllerDidComplete:(TutorialViewController *)viewController {
    viewController.delegate = nil;
    
    UIViewController *oldViewController = self.window.rootViewController;
    UIViewController *newViewController = [[MainTabBarController alloc] init];
    UIViewAnimationOptions options = UIViewAnimationOptionTransitionFlipFromLeft | UIViewAnimationOptionAllowAnimatedContent | UIViewAnimationOptionLayoutSubviews;
    
    [UIView transitionFromView:oldViewController.view toView:newViewController.view duration:0.5f options:options completion:^(BOOL finished) {
        self.window.rootViewController = newViewController;
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"Tutorial"];
    }];
}

@end
