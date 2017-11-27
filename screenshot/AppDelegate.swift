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
import FBSDKLoginKit
import Branch
import Firebase
import GoogleSignIn
import PromiseKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var bgTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    var settings: AppSettings?
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        ClarifaiModel.setup() // Takes a long time to intialize; start early.
        DataModel.setup() // Sets up Core Data stack on a background queue.
        return true
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        ApplicationStateModel.sharedInstance.applicationState = application.applicationState
        application.applicationIconBadgeNumber = 0

        prepareDataStackCompletionIfNeeded()
        PermissionsManager.shared().fetchPushPermissionStatus()
        
        setupThirdPartyLibraries(application, launchOptions: launchOptions)
        
        UIApplication.migrateUserDefaultsKeys()
        UIApplication.appearanceSetup()
        
        fetchAppSettings()
        
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
        ApplicationStateModel.sharedInstance.applicationState = .background
        track("sessionEnded")
        bgTask = application.beginBackgroundTask(withName: "liveAsLongAsCan") { // TODO: Die before killed by system?
            application.endBackgroundTask(self.bgTask)
            self.bgTask = UIBackgroundTaskInvalid
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        ApplicationStateModel.sharedInstance.applicationState = .active
        track("sessionStarted")
        AssetSyncModel.sharedInstance.syncPhotosUponForeground()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        ApplicationStateModel.sharedInstance.applicationState = .active
        FBSDKAppEvents.activateApp()
    }
    
//    func applicationWillTerminate(_ application: UIApplication) {
//        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
//    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        completionHandler(.noData)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        let sourceApplication = options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String
        let annotation = options[UIApplicationOpenURLOptionsKey.annotation]
        
        var handled = Branch.getInstance().application(app, open: url, options:options)
        
        if !handled {
            handled = FBSDKApplicationDelegate.sharedInstance().application(app, open: url, options: options)
        }
        
        if !handled {
            handled = GIDSignIn.sharedInstance().handle(url, sourceApplication: sourceApplication, annotation: annotation)
        }
        
        if !handled {
            // Facebook
//            let parsedURL = BFURL(inboundURL: url, sourceApplication: sourceApplication)
//
//            if parsedURL?.appLinkData != nil {
//                // this is an applink url, handle it here
//                let alert = UIAlertController(title: "Received link:", message: parsedURL?.targetURL.absoluteString, preferredStyle: .alert)
//                window?.rootViewController?.present(alert, animated: true, completion: nil)
//
//                return true
//            }
            
            // Google
//            if let invite = Invites.handle(url, sourceApplication: sourceApplication, annotation: annotation) as? ReceivedInvite {
//                let matchType = (invite.matchType == .weak) ? "Weak" : "Strong"
//
//                print("||| Invite received from: \(sourceApplication ?? "") Deeplink: \(invite.deepLink), Id: \(invite.inviteId), Type: \(matchType)")
//
//                return true
//            }
        }
        
        return handled
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        // pass the url to the handle deep link call
        Branch.getInstance().continue(userActivity)
        return true
    }
}

extension AppDelegate {
    
    // MARK: - Helper
    
    func showScreenshotListTop() {
        if let mainTabBarController = self.window?.rootViewController as? MainTabBarController {
            mainTabBarController.screenshotsNavigationController.popToRootViewController(animated: false)
            mainTabBarController.screenshotsNavigationController.screenshotsViewController.scrollToTop()
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
        Appsee.addEvent("App Launched", withProperties: ["version" : Bundle.displayVersionBuild])
        
        if UIApplication.isDev {
            Branch.setUseTestBranchKey(true)
        }
        
        let branch = Branch.getInstance()
        branch?.initSession(launchOptions: launchOptions) { params, error in
            // params are the deep linked params associated with the link that the user clicked -> was re-directed to this app
            // params will be empty if no data found
            guard error == nil else {
                print("Branch initSession error:\(error!)")
                return
            }
            guard let params = params as? [String : AnyObject] else {
                print("Branch initSession no params")
                return
            }
            print("Branch params:\(params)")
            if let shareId = params["shareId"] as? String {
                AssetSyncModel.sharedInstance.handleDynamicLink(shareId: shareId)
                self.showScreenshotListTop()
            }
            
            // "channel" will be the Instagram username of the ambassador who shared this link.
            if let channel = params["channel"] as? String {
                UserDefaults.standard.set(channel, forKey: UserDefaultsKeys.ambasssadorUsername)
                
                if let tutorialVC = self.window?.rootViewController as? TutorialViewController {
                    tutorialVC.video = .Ambassador(username: channel)
                }
            }
        }
        
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        RatingFlow.sharedInstance.start()
        
        IntercomHelper.sharedInstance.start(withLaunchOptions: launchOptions ?? [:])
        
        FirebaseApp.configure()
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
    }
    
    // MARK: - View Controllers
    
    func nextViewController() -> UIViewController {
        var viewController: UIViewController
        
        if UserDefaults.standard.bool(forKey: UserDefaultsKeys.onboardingCompleted) {
            if DataModel.sharedInstance.isCoreDataStackReady {
                viewController = MainTabBarController()
            } else {
                viewController = LoadingViewController()
            }
        } else {
            let tutorialViewController = TutorialViewController()
            tutorialViewController.delegate = self
            viewController = tutorialViewController
        }
        
        return viewController
    }
    
    func prepareDataStackCompletionIfNeeded() {
        func syncPhotos() {
            if ApplicationStateModel.sharedInstance.isBackground() {
                AssetSyncModel.sharedInstance.syncPhotos()
            } else {
                AssetSyncModel.sharedInstance.syncPhotosUponForeground()
            }
        }
        
        if UserDefaults.standard.bool(forKey: UserDefaultsKeys.onboardingCompleted) {
            if DataModel.sharedInstance.isCoreDataStackReady {
                syncPhotos()
            } else {
                DataModel.sharedInstance.coreDataStackCompletionHandler = {
                    syncPhotos()
                    
                    self.transitionTo(self.nextViewController())
                }
                
                DataModel.sharedInstance.coreDataStackFailureHandler = {
                    // TODO:
                }
            }
        }
    }
    
    func transitionTo(_ toViewController: UIViewController) {
        if let window = self.window {
            UIView.transition(with: window, duration: 0.5, options: .transitionFlipFromLeft, animations: {
                self.window?.rootViewController = toViewController
            })
        }
    }
}

// MARK: - Tutorial

extension AppDelegate: TutorialViewControllerDelegate {
    func tutoriaViewControllerDidComplete(_ viewController: TutorialViewController) {
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
        ApplicationStateModel.sharedInstance.applicationState = application.applicationState

        // Only spin up a background task if:
        // a) We are already in the background, and
        // b) We don't currently have a background task
        if application.applicationState == .background && self.bgTask == UIBackgroundTaskInvalid {
            self.bgTask = application.beginBackgroundTask(withName: "LongRunningSync", expirationHandler: {
                application.endBackgroundTask(self.bgTask)
                self.bgTask = UIBackgroundTaskInvalid
                
                // TODO: Call the completion handler when the sync is done.
                // TODO: Provide the correct background fetch result to the completionHandler.
                completionHandler(.newData)
            })
        }
        
        IntercomHelper.sharedInstance.handleRemoteNotification(userInfo, opened: false)
        Branch.getInstance().handlePushNotification(userInfo)
    }
}

// MARK: - Settings

extension AppDelegate {
    fileprivate func fetchAppSettings() {
        NetworkingPromise.appSettings().then(on: DispatchQueue.global(qos: .default)) { data -> Promise<AppSettings> in
            return Promise(value: AppSettings(data))
            
        }.then(on: .main) { appSettings -> Void in
            self.settings = appSettings
            
            let name = Notification.Name(NotificationCenterKeys.fetchedAppSettings)
            NotificationCenter.default.post(name: name, object: nil, userInfo: ["AppSettings": appSettings])
        }
    }
    
    func getAppSettings() -> _AppSettings? {
        if let settings = settings {
            return _AppSettings(settings)
            
        } else {
            return nil
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let userInfo = response.notification.request.content.userInfo as? [String : String],
          let openingScreen = userInfo[Constants.openingScreenKey],
          openingScreen == Constants.openingScreenValueScreenshot,
          let openingAssetId = userInfo[Constants.openingAssetIdKey] {
            AssetSyncModel.sharedInstance.refetchOpenedFromNotification(assetId: openingAssetId)
            showScreenshotListTop()
        }
        
        completionHandler()
        
        track("app opened from local notification")
    }
}
