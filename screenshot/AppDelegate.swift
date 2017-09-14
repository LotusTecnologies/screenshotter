//
//  AppDelegate.swift
//  screenshot
//
//  Created by Gershon Kagan on 9/11/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit
import UserNotifications
import Analytics
import Appsee
import Firebase
import FBSDKLoginKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var bgTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        ClarifaiModel.setup() // Takes a long time to intialize; start early.
        DataModel.setup() // Sets up Core Data stack on a background queue.
        return true
    }

    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        PermissionsManager.shared().fetchPushPermissionStatus()
        
        setupThirdPartyLibraries(application, launchOptions: launchOptions)
        setupApplicationAppearance()
        
        prepareDataStackCompletionIfNeeded()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = nextViewController()
        window?.makeKeyAndVisible()
        
        return true
    }

//    func applicationWillResignActive(_ application: UIApplication) {
//        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
//        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
//    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        bgTask = application.beginBackgroundTask(withName: "liveAsLongAsCan") { // TODO: Die before killed by system?
            application.endBackgroundTask(self.bgTask)
            self.bgTask = UIBackgroundTaskInvalid;
        }
    }

//    func applicationWillEnterForeground(_ application: UIApplication) {
//        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
//    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        FBSDKAppEvents.activateApp()
    }

//    func applicationWillTerminate(_ application: UIApplication) {
//        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
//    }

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        completionHandler(.noData)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        if let dynamicLink = DynamicLinks.dynamicLinks()?.dynamicLink(fromCustomSchemeURL: url),
          let link = dynamicLink.url,
          dynamicLink.matchConfidence == .strong {
            AssetSyncModel.sharedInstance.handleDynamicLink(dynamicLink: link)
            showScreenshotListTop()
            return true
        }
        if let scheme = url.scheme,
          let mainBundleIdentifier = Bundle.main.bundleIdentifier,
          scheme == mainBundleIdentifier,
          let host = url.host,
          host == "s" {
            AssetSyncModel.sharedInstance.handleDynamicLink(dynamicLink: url)
            showScreenshotListTop()
            return true
        }
        let isHandled = FBSDKApplicationDelegate.sharedInstance().application(app, open: url, options: options)
        return isHandled;
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        if let webpageURL = userActivity.webpageURL,
            let isHandled = DynamicLinks.dynamicLinks()?.handleUniversalLink(webpageURL, completion: { (dynamicLink: DynamicLink?, error: Error?) in
                if let dynamicLink = dynamicLink,
                    let link = dynamicLink.url,
                    dynamicLink.matchConfidence == .strong,
                    error == nil {
                    AssetSyncModel.sharedInstance.handleDynamicLink(dynamicLink: link)
                    self.showScreenshotListTop()
                }
            }) {
            return isHandled
        }
        return false
    }
}

extension AppDelegate {
    
    // MARK: - Helper
    
    func showScreenshotListTop() {
        if let mainTabBarController = self.window?.rootViewController as? MainTabBarController {
            mainTabBarController.screenshotsNavigationController.popToRootViewController(animated: false)
            mainTabBarController.screenshotsNavigationController.screenshotsViewController.scrollTopTop()
            mainTabBarController.selectedViewController = mainTabBarController.screenshotsNavigationController
        }
    }
    
    // MARK: - Third Party

    func setupThirdPartyLibraries(_ application: UIApplication, launchOptions: [UIApplicationLaunchOptionsKey: Any]?) {
        let configuration = SEGAnalyticsConfiguration(writeKey: Constants.segmentWriteKey)
        configuration.trackApplicationLifecycleEvents = true
        configuration.recordScreenViews = true
        configuration.trackDeepLinks = true
        configuration.trackPushNotifications = true
        SEGAnalytics.setup(with: configuration)
        
        Appsee.start(Constants.appSeeApiKey)
        Appsee.addEvent("App Launched", withProperties: ["version" : UIApplication.versionBuild()])
        
        FirebaseApp.configure()
        
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        RatingFlow.sharedInstance.start()
        
        IntercomHelper.sharedInstance.start(withLaunchOptions: launchOptions ?? [:])
    }

    // MARK: - Appearance
    
    func setupApplicationAppearance() {
        let crazeRedColor = UIColor.crazeRed
        
        UINavigationBar.appearance().tintColor = UIColor.gray6
        
        UINavigationBar.appearance().titleTextAttributes = [NSFontAttributeName : UIFont(name: "Futura-Medium", size: 20) ?? UIFont.systemFont(ofSize: 20), NSForegroundColorAttributeName : UIColor.gray3]

        UIBarButtonItem.appearance().setTitleTextAttributes([NSFontAttributeName : UIFont(name: "Futura", size: 16) ?? UIFont.systemFont(ofSize: 16)], for: .normal)

        UITabBar.appearance().tintColor = crazeRedColor
        
        UIToolbar.appearance().tintColor = crazeRedColor
    
        UIActivityIndicatorView.appearance(whenContainedInInstancesOf: [UIToolbar.self]).color = crazeRedColor
    }
    
    // MARK: - View Controllers
    
    func nextViewController() -> UIViewController {
        var viewController: UIViewController
        
        if UserDefaults.standard.bool(forKey: UserDefaultsKeys.tutorialCompleted) {
            if DataModel.sharedInstance.isCoreDataStackReady {
                viewController = MainTabBarController()
            } else {
                viewController = LoadingViewController()
            }
        } else {
            var insets = UIEdgeInsets.zero
            insets.top = UIDevice.is568h() ? 0 : 30
            
            let tutorialViewController = TutorialViewController()
            tutorialViewController.delegate = self;
            tutorialViewController.contentLayoutMargins = insets;
            viewController = tutorialViewController;
        }
        
        return viewController;
    }
    
    func prepareDataStackCompletionIfNeeded() {
        if UserDefaults.standard.bool(forKey: UserDefaultsKeys.tutorialCompleted) {
            if DataModel.sharedInstance.isCoreDataStackReady {
                AssetSyncModel.sharedInstance.syncPhotos()
            } else {
                DataModel.sharedInstance.coreDataStackCompletionHandler = {
                    AssetSyncModel.sharedInstance.syncPhotos()
                    self.transitionTo(self.nextViewController())
                }
                
                DataModel.sharedInstance.coreDataStackFailureHandler = {
                    // TODO
                }
            }
        }
    }
    
    func transitionTo(_ toViewController: UIViewController) {
        let options: UIViewAnimationOptions = [.transitionFlipFromLeft, .allowAnimatedContent, .layoutSubviews]
        if let fromView = self.window?.rootViewController?.view {
            UIView.transition(from: fromView, to: toViewController.view, duration: 0.5, options: options) { (finished) in
                self.window?.rootViewController = toViewController
            }
        }
    }
    
}

// MARK: - Tutorial

extension AppDelegate: TutorialViewControllerDelegate {
    
    func tutorialViewControllerDidComplete(_ viewController: TutorialViewController) {
        viewController.delegate = nil
        
        self.prepareDataStackCompletionIfNeeded()
        
        // Create a delay for a more natural feel after taking the screenshot
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.transitionTo(self.nextViewController())
        }
    }

}

// MARK: - Push Notifications

extension AppDelegate {
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        IntercomHelper.sharedInstance.deviceToken = deviceToken
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("[ERROR] FAILED TO REGISTER FOR REMOTE NOTIFICATIONS!")
        print("\(error)")
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        IntercomHelper.sharedInstance.handleRemoteNotification(userInfo, opened: false)
        completionHandler(.noData)
    }

}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let userInfo = response.notification.request.content.userInfo as? [String : String],
          let openingScreen = userInfo[Constants.openingScreenKey],
          openingScreen == Constants.openingScreenValueScreenshot {
            showScreenshotListTop()
        }
        
        completionHandler()
        
        AnalyticsManager.track("app opened from local notification")
    }
    
}
