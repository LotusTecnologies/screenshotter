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
import PromiseKit
import Segment_Amplitude

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    // We are purposely initalizing this immediately since it observes for app launch notifications.
    private let usageStreakManager = UsageStreakManager()
    
    var window: UIWindow?
    var bgTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    var shouldLoadDiscoverNextLoad = false
    let appSettings: AppSettings = AppSettings()
    
    fileprivate var frameworkSetupLaunchOptions: [UIApplicationLaunchOptionsKey : Any]?
    
    fileprivate lazy var mainTabBarController: MainTabBarController = {
        let viewController = MainTabBarController(delegate:self)
        return viewController
    }()
    
    static var shared: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        // Needs to be called very early.
        PermissionsManager.shared.fetchPushPermissionStatus()
        
        UNUserNotificationCenter.current().delegate = self
        
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        if DataModel.sharedInstance.storeNeedsMigration() {
            window?.rootViewController = LoadingViewController()
            window?.makeKeyAndVisible()
            asyncLoadStore()
        }else{
            let promise = DataModel.sharedInstance.loadStore(sync:true)
            if promise.isRejected{
                window?.rootViewController = LoadingViewController()
                window?.makeKeyAndVisible()
                asyncLoadStore()
            }else{
                self.window?.rootViewController = self.nextViewController()
                window?.makeKeyAndVisible()
                AssetSyncModel.sharedInstance.scanPhotoGalleryForFashion()

            }
        }

        fetchAppSettings()
        
        UIApplication.migrateUserDefaultsKeys()
        UIApplication.appearanceSetup()
        UserFeedback.shared.applicationDidFinishLaunching() // only setups notificationCenter observing. does nothing now

        return true
    }
    
    func asyncLoadStore(){
        DataModel.sharedInstance.loadStore(multipleAttempts: 5).then(execute: { (success) -> Void in
            DispatchQueue.main.async {
                self.window?.rootViewController = self.nextViewController()
            }
            AssetSyncModel.sharedInstance.scanPhotoGalleryForFashion()
            
        }).catch(execute: { (error) in
            DispatchQueue.main.async {
                if let loadingView = self.window?.rootViewController as? LoadingViewController {
                    loadingView.storeLoadingFailed()
                }else{
                    fatalError("Unable to load store and application is in undefined state")
                }
            }
        })
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        ApplicationStateModel.sharedInstance.applicationState = application.applicationState
        application.applicationIconBadgeNumber = 0
        
        frameworkSetup(application, didFinishLaunchingWithOptions: launchOptions)
        
        SilentPushSubscriptionManager.sharedInstance.updateSubscriptionsIfNeeded()
        
        if application.applicationState == .background,
            let remoteNotification = launchOptions?[.remoteNotification] as? [String: AnyObject],
            let aps = remoteNotification["aps"] as? [String : AnyObject],
            let contentAvailable = aps["content-available"] as? NSNumber,
            contentAvailable.intValue == 1 {
            //TODO: why is this only segment
            AnalyticsTrackers.segment.track(.wokeFromSilentPush)
        } else {
            AnalyticsTrackers.standard.track(.sessionStarted) // Roi Tal from AppSee suggested
        }
        
        
        if let launchOptions = launchOptions, let url = launchOptions[UIApplicationLaunchOptionsKey.url] as? URL {
            
            if self.isSendToDebugURL(url) {
                self.sendDebugDataToDebugApp(url:url)
                return true
            }
        }

        
        return true
    }
    func isSendToDebugURL(_ url:URL) -> Bool{
        //we use this uuid so we will never accidentently detect a wrong openURL even from branch or other thrid parties
        return url.absoluteString.contains("sendDebugInfo-b32963e7-ad86-4f80-8f2a-131d76ece793")

    }
    func sendDebugDataToDebugApp(url:URL){
        let urlAbsoluteString = url.absoluteString

        var paramsToSend:[String:String] = [:]
        let pushTokenData = UserDefaults.standard.object(forKey: UserDefaultsKeys.deviceToken) as? NSData
        
        if urlAbsoluteString.contains("pushToken") {
            if let pushToken = pushTokenData?.description.addingPercentEncoding(withAllowedCharacters: .alphanumerics) {
                paramsToSend["pushToken"] = pushToken
            }
        }
        if urlAbsoluteString.contains("sharedScreenshots") {
            var screenshots:[String] = []
            let screenShotsFrc = DataModel.sharedInstance.screenshotFrc(delegate: nil)
            screenShotsFrc.fetchedObjects.forEach { (s) in
                if s.submittedDate != nil {
                    if let screenshotId = s.screenshotId {
                        screenshots.append("\(screenshotId)|\(s.submittedFeedbackCountGoal )")
                    }
                }
            }
            paramsToSend["sharedScreenshots"] = screenshots.joined(separator: ",")
        }
        if let url = URL.urlWith(string: "crazeDebugApp://sendDebugInfo", queryParameters: paramsToSend) {
        
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
    
    var lastPresentedLowDiskSpaceWarning:Date?
    func presentLowDiskSpaceWarning(){
        
        //don't change to guard - lead to large complie time
        if let lastTime = self.lastPresentedLowDiskSpaceWarning {
            let timeInterval = abs(lastTime.timeIntervalSinceNow)
            if timeInterval  < 60*5 {
                return
            }
        }
        
        
        self.lastPresentedLowDiskSpaceWarning = Date()
        let alert = UIAlertController.init(title: "application.error.no_disk_space.title".localized, message:"application.error.no_disk_space.message".localized, preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "generic.ok".localized, style: .default, handler:nil))
        self.window?.rootViewController?.present(alert, animated: true, completion: nil)
    }
    
//    func applicationWillResignActive(_ application: UIApplication) {
//        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
//        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
//    }
        
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        ApplicationStateModel.sharedInstance.applicationState = .background
        AnalyticsTrackers.standard.track(.sessionEnded)
        bgTask = application.beginBackgroundTask(withName: "liveAsLongAsCan") { // TODO: Die before killed by system?
            application.endBackgroundTask(self.bgTask)
            self.bgTask = UIBackgroundTaskInvalid
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        ApplicationStateModel.sharedInstance.applicationState = .active
        AnalyticsTrackers.standard.track(.sessionStarted)
        AssetSyncModel.sharedInstance.scanPhotoGalleryForFashion()
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
        
        if self.isSendToDebugURL(url) {
            self.sendDebugDataToDebugApp(url:url)
            return true
        }
        
        var handled = Branch.getInstance().application(app, open: url, options:options)
        
        if !handled {
            handled = FBSDKApplicationDelegate.sharedInstance().application(app, open: url, options: options)
        }
        
        return handled
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
            
            viewController = navigationController.createRestoredProductsViewController()
            
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
        
        case s(DiscoverNavigationController.self):
            guard let tabBarController = restorationViewControllers[s(MainTabBarController.self)] as? MainTabBarController else {
                return nil
            }
            
            viewController = tabBarController.discoverNavigationController
            
        case s(DiscoverScreenshotViewController.self):
            guard let navigationController = restorationViewControllers[s(DiscoverNavigationController.self)] as? DiscoverNavigationController else {
                return nil
            }
            
            viewController = navigationController.discoverScreenshotViewController
            
        case s(SettingsNavigationController.self):
            guard let tabBarController = restorationViewControllers[s(MainTabBarController.self)] as? MainTabBarController else {
                return nil
            }
            
            viewController = tabBarController.settingsNavigationController
            
        case s(SettingsViewController.self):
            guard let navigationController = restorationViewControllers[s(SettingsNavigationController.self)] as? SettingsNavigationController else {
                return nil
            }
            
            viewController = navigationController.settingsViewController
            
        default:
            viewController = nil
        }
        
        if viewController != nil {
            restorationViewControllers[identifier] = viewController
        }
        
        return viewController
    }
}

extension AppDelegate : ViewControllerLifeCycle {
    func viewControllerDidLoad(_ viewController: UIViewController) {
        frameworkSetupMainViewDidLoad()
    }
}

// MARK: - Framework Setup

extension AppDelegate {
    fileprivate func frameworkSetup(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) {
        frameworkSetupLaunchOptions = launchOptions
        
        Appsee.start(Constants.appSeeApiKey)
        Appsee.addEvent("App Launched", withProperties: ["version": Bundle.displayVersionBuild])
        
        let configuration = SEGAnalyticsConfiguration(writeKey: Constants.segmentWriteKey)
        configuration.trackApplicationLifecycleEvents = true
        configuration.recordScreenViews = true
        configuration.trackDeepLinks = true
        configuration.trackPushNotifications = true
        configuration.use(SEGAmplitudeIntegrationFactory.instance())
        SEGAnalytics.setup(with: configuration)
        
        if UIApplication.isDev {
            Branch.setUseTestBranchKey(true)
        }
        
        Branch.getInstance()?.initSession(launchOptions: launchOptions) { params, error in
            // params are the deep linked params associated with the link that the user clicked -> was re-directed to this app
            // params will be empty if no data found
            guard error == nil, let params = params as? [String : AnyObject] else {
                AnalyticsTrackers.segment.error(withDescription: error!.localizedDescription)
                return
            }
            
            if let shareId = params["shareId"] as? String {

                AssetSyncModel.sharedInstance.downloadScreenshot(shareId: shareId)
                self.showScreenshotListTop()
            }
            
            if let channel = params["~channel"] as? String {
                UserDefaults.standard.set(channel, forKey: UserDefaultsKeys.referralChannel)
            }
            
            if let campaign = params["~campaign"] as? String {
                UserDefaults.standard.set(campaign, forKey: UserDefaultsKeys.campaign)
            }
        }
        
    
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    fileprivate func frameworkSetupMainViewDidLoad() {
        RatingFlow.sharedInstance.start()
        
        IntercomHelper.sharedInstance.start(withLaunchOptions: frameworkSetupLaunchOptions ?? [:])
        
        frameworkSetupLaunchOptions = nil
    }
}

extension AppDelegate {
    
    // MARK: Helper
    
    func showScreenshotListTop() {
        if let mainTabBarController = self.window?.rootViewController as? MainTabBarController {
            if mainTabBarController.screenshotsNavigationController.topViewController?.presentedViewController != nil {
                mainTabBarController.screenshotsNavigationController.topViewController?.dismiss(animated: false, completion: nil)
            }
            
            mainTabBarController.screenshotsNavigationController.popToRootViewController(animated: false)
            mainTabBarController.screenshotsNavigationController.screenshotsViewController.scrollToTop()
            mainTabBarController.selectedViewController = mainTabBarController.screenshotsNavigationController
        }
    }
    
    // MARK: View Controllers
    
    func nextViewController() -> UIViewController {
        let viewController: UIViewController
        
        if UserDefaults.standard.bool(forKey: UserDefaultsKeys.onboardingCompleted) {
            
            viewController = mainTabBarController
            if self.shouldLoadDiscoverNextLoad {
                self.shouldLoadDiscoverNextLoad = false
                if let mainTabBarController = viewController as? MainTabBarController {
                    if let vc = mainTabBarController.viewControllers?.first(where: {($0 as? DiscoverNavigationController) != nil}) {
                        mainTabBarController.selectedViewController = vc
                    }
                }
            }
        }
        else {
            let tutorialViewController = TutorialViewController()
            tutorialViewController.delegate = self
            tutorialViewController.lifeCycleDelegate = self
            viewController = tutorialViewController
        }
        
        return viewController
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

extension AppDelegate : TutorialViewControllerDelegate {
    func tutoriaViewControllerDidComplete(_ viewController: TutorialViewController) {
        viewController.delegate = nil
        
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

        if let aps = userInfo["aps"] as? NSDictionary, let category = aps["category"] as? String, category == "MATCHSTICK_LIKES", let likeUpdates = userInfo["likeUpdates"] as? [[String:Any]]{
            DataModel.sharedInstance.performBackgroundTask { (context) in
            
                likeUpdates.forEach({ (dict) in
                    let period:TimeInterval? = {
                        if let p = dict["periodS"] as? Double {
                            return TimeInterval(p)
                        }else if let p = dict["periodS"] as? Int {
                            return TimeInterval(p)
                        }else if let p = dict["periodS"] as? String {
                            return TimeInterval(p)
                        }
                        return nil
                    }()
                    let likes:Int64? = {
                        if let l = dict["likes"] as? Double {
                            return Int64(l)
                        }else if let l = dict["likes"] as? Int {
                            return Int64(l)
                        }else if let l = dict["likes"] as? String {
                            return Int64(l)
                        }
                        return nil
                    }()
                    if let period = period,
                        let screenshotId = dict["screenshotId"] as? String,
                        let likes = likes {
                        
                        if let screenshot = context.screenshotWith(screenshotId: screenshotId){
                            if screenshot.submittedDate != nil {
                                screenshot.submittedFeedbackCountGoal = max(screenshot.submittedFeedbackCountGoal, likes)
                                screenshot.submittedFeedbackCountGoalDate =  NSDate.init(timeIntervalSinceNow: period)
                            }
                        }
                    }
                })
                
                context.saveIfNeeded()
                DispatchQueue.main.async {
                    if UIApplication.shared.applicationState == .active {
                        UserFeedback.shared.cancelNotifications()
                        UserFeedback.shared.scheduleNotifications()
                    }
                   completionHandler(.newData)
                }
            }
        }else{
            
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
}

// MARK: - Settings

extension AppDelegate {
    fileprivate func fetchAppSettings() {
        NetworkingPromise.sharedInstance.appSettings().then(on:.main) { data -> Void in
            self.appSettings.appSettingsDict = data
            NotificationCenter.default.post(name: .fetchedAppSettings, object: nil, userInfo:nil)  //this can cause UI changes and must be on main
        }
    }
}

extension AppDelegate : UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let userInfo = response.notification.request.content.userInfo as? [String : String],
          let openingScreen = userInfo[Constants.openingScreenKey],
          openingScreen == Constants.openingScreenValueScreenshot,
          let openingAssetId = userInfo[Constants.openingAssetIdKey] {
            AssetSyncModel.sharedInstance.importPhotosToScreenshot(assetIds: [openingAssetId])
            showScreenshotListTop()
        }
        
        completionHandler()
        
        AnalyticsTrackers.standard.track(.appOpenedFromLocalNotification)
    }
}
