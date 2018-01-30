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
import DeepLinkKit
import Segment_Amplitude

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    // We are purposely iniitalizing this immediately since it observes for app launch notifications.
    private let usageStreakManager = UsageStreakManager()
    
    var router: DPLDeepLinkRouter?
    var window: UIWindow?
    var bgTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    
    let settings: AppSettings
    fileprivate let settingsSetter = AppSettingsSetter()
    
    fileprivate lazy var mainTabBarController: MainTabBarController = {
        return MainTabBarController()
    }()
    
    static var shared: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    override init() {
        settings = AppSettings(withSetter: self.settingsSetter)
        super.init()
    }
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        ClarifaiModel.setup() // Takes a long time to intialize; start early.
        DataModel.setup() // Sets up Core Data stack on a background queue.
        
        
        // TODO: the code below used to be in the did finish launching.
        // it needs to be here for state restoration. verify everything works!
        
        setupThirdPartyLibraries(application, launchOptions: launchOptions)
        
        ApplicationStateModel.sharedInstance.applicationState = application.applicationState
        application.applicationIconBadgeNumber = 0
        
        prepareDataStackCompletionIfNeeded()
        PermissionsManager.shared.fetchPushPermissionStatus()
        
        UIApplication.migrateUserDefaultsKeys()
        UIApplication.appearanceSetup()
        
        SilentPushSubscriptionManager.sharedInstance.updateSubscriptionsIfNeeded()
        
        fetchAppSettings()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = nextViewController()
        window?.makeKeyAndVisible()
        
        return true
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        if application.applicationState == .background,
            let remoteNotification = launchOptions?[.remoteNotification] as? [String: AnyObject],
            let aps = remoteNotification["aps"] as? [String : AnyObject],
            let contentAvailable = aps["content-available"] as? NSNumber,
            contentAvailable.intValue == 1 {
            AnalyticsTrackers.segment.track("Woke From Silent Push")
        }
        
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
        AnalyticsTrackers.standard.track("sessionEnded")
        bgTask = application.beginBackgroundTask(withName: "liveAsLongAsCan") { // TODO: Die before killed by system?
            application.endBackgroundTask(self.bgTask)
            self.bgTask = UIBackgroundTaskInvalid
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        ApplicationStateModel.sharedInstance.applicationState = .active
        AnalyticsTrackers.standard.track("sessionStarted")
        AssetSyncModel.sharedInstance.syncPhotosUponForeground()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        ApplicationStateModel.sharedInstance.applicationState = .active
        FBSDKAppEvents.activateApp()
        AnalyticsTrackers.standard.trackUserAge()
    }
    
//    func applicationWillTerminate(_ application: UIApplication) {
//        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
//    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        completionHandler(.noData)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        var handled = router?.handle(url) { (handled, error) in
            if let error = error {
                AnalyticsTrackers.segment.error(withDescription: error.localizedDescription)
            }
        } ?? false
        
        if !handled {
            handled = Branch.getInstance().application(app, open: url, options:options)
        }
        
        if !handled {
            handled = FBSDKApplicationDelegate.sharedInstance().application(app, open: url, options: options)
        }
        
        if !handled {
            let sourceApplication = options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String
            let annotation = options[UIApplicationOpenURLOptionsKey.annotation]
            
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
        if Branch.getInstance().continue(userActivity) == false {
            return router?.handle(userActivity) { (handled, error) in
                if let error = error {
                    AnalyticsTrackers.segment.error(withDescription: error.localizedDescription)
                }
            } ?? false
        }
        
        return true
    }
    
    // MARK: State Restoration
    
    fileprivate var restorationViewControllers: [String : UIViewController] = [:]
    
    func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        return true
    }
    
    func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        return true
    }
    
    func application(_ application: UIApplication, viewControllerWithRestorationIdentifierPath identifierComponents: [Any], coder: NSCoder) -> UIViewController? {
        guard let identifier = identifierComponents.last as? String else {
            return nil
        }
        
        // Shorter convenience function
        func s(_ class: AnyClass) -> String {
            return String(describing: `class`)
        }
        
        let viewController: UIViewController?
        
        switch identifier {
        case s(MainTabBarController.self):
            viewController = mainTabBarController
            
        case s(ScreenshotsNavigationController.self):
            guard let tabBarController = restorationViewControllers[s(MainTabBarController.self)] as? MainTabBarController else {
                return nil
            }
            
            viewController = tabBarController.screenshotsNavigationController
            
        case s(ScreenshotsViewController.self):
            guard let navigationController = restorationViewControllers[s(ScreenshotsNavigationController.self)] as? ScreenshotsNavigationController else {
                return nil
            }
            
            viewController = navigationController.screenshotsViewController
            
        case s(ProductsViewController.self):
            guard let navigationController = restorationViewControllers[s(ScreenshotsNavigationController.self)] as? ScreenshotsNavigationController else {
                return nil
            }
            
            viewController = navigationController.createProductsViewController()
            
        case s(FavoritesNavigationController.self):
            guard let tabBarController = restorationViewControllers[s(MainTabBarController.self)] as? MainTabBarController else {
                return nil
            }
            
            viewController = tabBarController.favoritesNavigationController
            
        case s(FavoritesViewController.self):
            guard let navigationController = restorationViewControllers[s(FavoritesNavigationController.self)] as? FavoritesNavigationController else {
                return nil
            }
            
            viewController = navigationController.favoritesViewController
            
        case s(ScreenshotPickerNavigationController.self):
            guard let navigationController = restorationViewControllers[s(ScreenshotsNavigationController.self)] as? ScreenshotsNavigationController else {
                return nil
            }
            
            viewController = navigationController.createScreenshotPickerNavigationController()
            
        case s(ScreenshotPickerViewController.self):
            guard let navigationController = restorationViewControllers[s(ScreenshotPickerNavigationController.self)] as? ScreenshotPickerNavigationController else {
                return nil
            }
            
            viewController = navigationController.screenshotPickerViewController
            
        default:
            viewController = nil
        }
        
        if viewController != nil {
            restorationViewControllers[identifier] = viewController
        }
        
        return viewController
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
        setupRouter()
        
        let configuration = SEGAnalyticsConfiguration(writeKey: Constants.segmentWriteKey)
        configuration.trackApplicationLifecycleEvents = true
        configuration.recordScreenViews = true
        configuration.trackDeepLinks = true
        configuration.trackPushNotifications = true
        configuration.use(SEGAmplitudeIntegrationFactory.instance())
        
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
            guard error == nil, let params = params as? [String : AnyObject] else {
                AnalyticsTrackers.segment.error(withDescription: error!.localizedDescription)
                return
            }
            
            if let shareId = params["shareId"] as? String {
                AssetSyncModel.sharedInstance.handleDynamicLink(shareId: shareId)
                self.showScreenshotListTop()
            }
            
            if let channel = params["channel"] as? String {
                UserDefaults.standard.set(channel, forKey: UserDefaultsKeys.referralChannel)
            }
            
            // "discoverURL" will be the discover URL that should be used during this session.
            if let discoverURLString = params["discoverURL"] as? String {
                self.settingsSetter.setForcedDiscoverURL(withURLPath: discoverURLString)
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
            viewController = mainTabBarController
            
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
                    
//                    let name = Notification.Name(NotificationCenterKeys.coreDataStackCompleted)
//                    NotificationCenter.default.post(name: name, object: nil, userInfo: nil)
                    
                    // !!!: DEBUG
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                        let name = Notification.Name(NotificationCenterKeys.coreDataStackCompleted)
                        NotificationCenter.default.post(name: name, object: nil, userInfo: nil)
                    })
                }
                
                DataModel.sharedInstance.coreDataStackFailureHandler = {
                    print("Core Data stack failed")
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

// MARK: - Deep Link Router

extension AppDelegate {
    func setupRouter() {
        router = DPLDeepLinkRouter()
        router?.registerHandlerClass(DiscoverDeepLinkHandler.self, forRoute: "discover")
    }
}

// MARK: - Tutorial

extension AppDelegate: TutorialViewControllerDelegate {
    func tutoriaViewControllerDidComplete(_ viewController: TutorialViewController) {
        viewController.delegate = nil
        
        prepareDataStackCompletionIfNeeded()
        
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
        SilentPushSubscriptionManager.sharedInstance.updateSubscriptionsIfNeeded()
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        AnalyticsTrackers.segment.error(withDescription: "Failed to register for remote notifications! (\(error))")
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        ApplicationStateModel.sharedInstance.applicationState = application.applicationState

        // Only spin up a background task if we are already in the background
        if application.applicationState == .background {
            if bgTask != UIBackgroundTaskInvalid {
                application.endBackgroundTask(self.bgTask)
            }
            
            bgTask = application.beginBackgroundTask(withName: "LongRunningSync", expirationHandler: {
                // TODO: Call the completion handler when the sync is done.
                // TODO: Provide the correct background fetch result to the completionHandler.
                application.endBackgroundTask(self.bgTask)
                self.bgTask = UIBackgroundTaskInvalid
                
                completionHandler(.newData)
            })
        } else {
            completionHandler(.noData)
        }
        
        IntercomHelper.sharedInstance.handleRemoteNotification(userInfo, opened: false)
        Branch.getInstance().handlePushNotification(userInfo)
    }
}

// MARK: - Settings

extension AppDelegate {
    fileprivate func fetchAppSettings() {
        NetworkingPromise.appSettings().then(on: DispatchQueue.global(qos: .default)) { data -> Promise<FetchedAppSettings> in
            return Promise(value: FetchedAppSettings(data))
            
        }.then(on: .main) { fetchedAppSettings -> Void in
            self.settingsSetter.setDiscoverURLs(withURLPaths: fetchedAppSettings.discoverURLPaths)
            self.settingsSetter.setUpdateVersion(fetchedAppSettings.updateVersion)
            self.settingsSetter.setForcedUpdateVersion(fetchedAppSettings.forcedUpdateVersion)
            
            let name = Notification.Name(NotificationCenterKeys.fetchedAppSettings)
            NotificationCenter.default.post(name: name, object: nil, userInfo: ["AppSettings": fetchedAppSettings])
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
        
        AnalyticsTrackers.standard.track("app opened from local notification")
    }
}
