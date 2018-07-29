//
//  AppDelegate.swift
//  screenshot
//
//  Created by Gershon Kagan on 9/11/17.
//  Copyright (c) 2017 crazeapp. All rights reserved.
//

import UIKit
import UserNotifications
import Analytics
import Appsee
import FBSDKLoginKit
import Branch
import PromiseKit
import Amplitude_iOS
import AdSupport
import Pushwoosh
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    // We are purposely initalizing this immediately since it observes for app launch notifications.
    private let usageStreakManager = UsageStreakManager()
    
    var window: UIWindow?
    var bgTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    var shouldLoadDiscoverNextLoad = false
    let appSettings: AppSettings = AppSettings()
    var appLaunchedForFirstTime = false
    
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
        
        NetworkingPromise.sharedInstance.searchAmazon(keywords: "red dress")
        let _ = UserAccountManager.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        window = UIWindow(frame: UIScreen.main.bounds)
        if UserDefaults.standard.value(forKey: UserDefaultsKeys.lastDbVersionMigrated) == nil {
            appLaunchedForFirstTime = true
        }
        
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
        frameworkSetupMainViewDidLoad()
        
        UIApplication.migrateUserDefaultsKeys()
        UIApplication.appearanceSetup()
        UserFeedback.shared.applicationDidFinishLaunching() // only setups notificationCenter observing. does nothing now
        PWInAppManager.shared().setUserId(AnalyticsUser.current.identifier)
        return true
    }
    
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        Analytics.trackDevMemoryWarning()
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
        
        frameworkSetup(application, didFinishLaunchingWithOptions: launchOptions)
        
        SilentPushSubscriptionManager.sharedInstance.updateSubscriptionsIfNeeded()
        LocalNotificationModel.setup()

        NotificationCenter.default.addObserver(self, selector: #selector(badgeNumberDidChange(_:)), name: .ScreenshotUninformedAccumulatorModelDidChange, object: nil)
        
        if self.appLaunchedForFirstTime == true {
            Analytics.trackAppOpenedFirstTime()
        }
        
        if application.applicationState == .background,
            let remoteNotification = launchOptions?[.remoteNotification] as? [String: AnyObject],
            let aps = remoteNotification["aps"] as? [String : AnyObject],
            let contentAvailable = aps["content-available"] as? NSNumber,
            contentAvailable.intValue == 1 {
            Analytics.trackWokeFromSilentPush()
        } else {
            
            Analytics.trackSessionStarted() // Roi Tal from AppSee suggested
        }
        
        Analytics.trackDevLog(file:  NSString.init(string: #file).lastPathComponent, line: #line, message: "application didFinishLaunchingWithOptions")

        if let launchOptions = launchOptions, let url = launchOptions[UIApplicationLaunchOptionsKey.url] as? URL {
            Analytics.trackDevLog(file:  NSString.init(string: #file).lastPathComponent, line: #line, message: "application didFinishLaunchingWithOptions with url \(url)")

            if self.isSendToDebugURL(url) {
                self.sendDebugDataToDebugApp(url:url)
                return true
            }
            if UserAccountManager.shared.application(application, open: url, options: [:]) {
                return true
            }
        }
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)

        if PermissionsManager.shared.permissionStatus(for: .push) == .authorized {
            PermissionsManager.shared.requestPermission(for: .push)
        }
        
        return true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func isSendToDebugURL(_ url:URL) -> Bool{
        //we use this uuid so we will never accidentently detect a wrong openURL even from branch or other third parties
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
        if urlAbsoluteString.contains("watchedProductInfo") {
            var arrayOfDictionaries:[[String:Any]] = []
            let favoritesFRC = DataModel.sharedInstance.favoritedProductsFrc(delegate: nil)
            favoritesFRC.fetchedObjects.forEach { (p) in
                //                        if let partNumber = productInfo["partNumber"] as? String, let price = productInfo["price"] as? Double, let title = productInfo["title"] as? String, let inStock = productInfo["inStock"] as? Bool {

                if p.hasPriceAlerts, let partNumber = p.partNumber, let title = p.productTitle() {
                    let inStock = p.hasVariants
                    let price = p.fallbackPrice
                    
                    
                    arrayOfDictionaries.append(["partNumber":partNumber,
                                                "price":price,
                                                "title":title,
                                                "inStock":inStock])
                }
            }
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: arrayOfDictionaries, options: [])
                if let jsonString = String.init(data: jsonData, encoding: .utf8) {
                    paramsToSend["watchedProductInfo"] = jsonString
                }

            }catch{
                print("error making json - \(error)")
            }
        }
        if let url = URL.urlWith(string: "crazeDebugApp://sendDebugInfo", queryParameters: paramsToSend) {
        
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
    
    var lastPresentedLowDiskSpaceWarning:Date?
    
    func presentLowDiskSpaceWarning() {
        //don't change to guard - lead to large complie time
        if let lastPresentation = self.lastPresentedLowDiskSpaceWarning,
          -lastPresentation.timeIntervalSinceNow <= 60 * 5 { // Do nothing if presented warning within last 5 minutes.
            return
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
        Analytics.trackSessionEnded()
        bgTask = application.beginBackgroundTask(withName: "liveAsLongAsCan") { // TODO: Die before killed by system?
            application.endBackgroundTask(self.bgTask)
            self.bgTask = UIBackgroundTaskInvalid
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        ApplicationStateModel.sharedInstance.applicationState = .active
        PermissionsManager.shared.fetchPushPermissionStatus()
        Analytics.trackSessionStarted()
        AssetSyncModel.sharedInstance.scanPhotoGalleryForFashion()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        ApplicationStateModel.sharedInstance.applicationState = .active
        PermissionsManager.shared.fetchPushPermissionStatus()
        FBSDKAppEvents.activateApp()
        Analytics.trackUserProperties(analyticsUser: AnalyticsUser.current)
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
            handled = UserAccountManager.shared.application(app, open: url, options: options)
        }
        if !handled {
            handled = FBSDKApplicationDelegate.sharedInstance().application(app, open: url, options: options)
        }
        if !handled {
            handled = self.handleDeepLink(application: app, url: url, options: options)
        }
        print("open url: \(url.absoluteString)")
        return handled
    }
    
    func handleDeepLink(application:UIApplication, url:URL, options:[UIApplicationOpenURLOptionsKey : Any] ) -> Bool {
        let urlString = url.absoluteString
        if urlString.hasPrefix("screenshop://openTab/") {
            if let mainTabBarController = self.window?.rootViewController as? MainTabBarController {
                let page = urlString.components(separatedBy: "/").last?.lowercased()
                var tab: MainTabBarController.TabIndex? = nil
                switch page {
                case "favorites", "favorite":
                    tab = .favorites
                case "discover", "matchstick":
                    tab = .discover
                case "screenshots", "main":
                    tab = .screenshots
                case "profile":
                    tab = .profile
//                case "cart":
//                    tab = .cart
                default:
                    tab = nil
                }
                if let tab = tab {
                    mainTabBarController.goTo(tab: tab)
                    return true
                }
            }
        }
        else if urlString.hasPrefix("screenshop://openWebLink/") {
            let pathComponents = url.pathComponents
            if pathComponents.count >= 4 {
                let browser = pathComponents[1]
                let link = String(urlString.suffix(from: "screenshop://openWebLink/\(browser)/".endIndex))
                if browser == "default" {
                    if let vc = AppDelegate.shared.window?.rootViewController {
                        OpenWebPage.present(urlString: link, fromViewController: vc)
                        return true
                    }
                }
            }
        }
        else if urlString.hasPrefix("screenshop://addScreenshot/") {
            let prefix = "screenshop://addScreenshot/"
            
            if let prefixRange = urlString.range(of: prefix) {
                var screenshotUrlString = urlString
                screenshotUrlString.removeSubrange(prefixRange)
                AssetSyncModel.sharedInstance.uploadPhoto(imageUrlString: screenshotUrlString, source: .pushWoosh)
                
                if let mainTabBarController = self.window?.rootViewController as? MainTabBarController {
                    mainTabBarController.dismiss(animated: true)
                }
                
                PWInbox.loadMessages { (messages, error) in
                    let codes = messages?.compactMap({ message -> String? in
                        return message.isActionPerformed ? message.code : nil
                    })
                    
                    if let codes = codes {
                        PWInbox.deleteMessages(withCodes: codes)
                    }
                }
            }
        }
        return false
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        let handled = Branch.getInstance().continue(userActivity)
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
            
        case s(FavoriteProductsViewController.self):
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
            
        case s(ProfileNavigationController.self):
            guard let tabBarController = restorationViewControllers[s(MainTabBarController.self)] as? MainTabBarController else {
                return nil
            }
            
            viewController = tabBarController.profileNavigationController
            
        case s(ProfileViewController.self):
            guard let navigationController = restorationViewControllers[s(ProfileNavigationController.self)] as? ProfileNavigationController else {
                return nil
            }
            
            viewController = navigationController.profileViewController
            
        default:
            viewController = nil
        }
        
        if viewController != nil {
            restorationViewControllers[identifier] = viewController
        }
        
        return viewController
    }
    
    // MARK: Hidden Logo
    
    private let hiddenLogoController = HiddenLogoController()
    
    func syncHiddenLogo() {
        hiddenLogoController.syncView()
    }
}

extension AppDelegate : ViewControllerLifeCycle {
    func viewControllerDidLoad(_ viewController: UIViewController) {
    }
}

// MARK: - Framework Setup

extension AppDelegate : KochavaTrackerDelegate {
    func tracker(_ tracker: KochavaTracker, didRetrieveAttributionDictionary attributionDictionary: [AnyHashable : Any]) {
    }
    
    fileprivate func frameworkSetup(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) {
        frameworkSetupLaunchOptions = launchOptions
                
        Appsee.start(Constants.appSeeApiKey)
        Appsee.addEvent("App Launched", withProperties: ["version": Bundle.displayVersionBuild])
        
        Amplitude.instance().initializeApiKey(Constants.amplitudeApiKey)
        Amplitude.instance().trackingSessionEvents = true

        var trackerParametersDictionary: [AnyHashable: Any] = [:]
        trackerParametersDictionary[kKVAParamAppGUIDStringKey] = Constants.kocchavaGUIDKey
        trackerParametersDictionary[kKVAParamLogLevelEnumKey] = kKVALogLevelEnumInfo
        
        KochavaTracker.shared.configure(withParametersDictionary: trackerParametersDictionary, delegate: self)
                
        
        if UIApplication.isDev {
            Branch.setUseTestBranchKey(true)
        }
        
        if !ASIdentifierManager.shared().isAdvertisingTrackingEnabled {
            Branch.setTrackingDisabled(true)
        }
        Analytics.trackDevLog(file:  NSString.init(string: #file).lastPathComponent, line: #line, message: "framework setup: \(String(describing: launchOptions))")
        Branch.getInstance()?.initSession(launchOptions: launchOptions) { params, error in
            // params are the deep linked params associated with the link that the user clicked -> was re-directed to this app
            // params will be empty if no data found

            guard error == nil, let params = params as? [String : AnyObject] else {
                if let e = error as NSError? {
                    Analytics.trackDevLog(file:  NSString.init(string: #file).lastPathComponent, line: #line, message: "branch error: \(e)")
                    Analytics.trackError(type: nil, domain: e.domain, code: e.code, localizedDescription: e.localizedDescription)
                }
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
            
            Analytics.trackDevLog(file:  NSString.init(string: #file).lastPathComponent, line: #line, message: "branch params: \(params)")
            if let nonBranchLink = params["+non_branch_link"]  as? String {
                if nonBranchLink.contains("validate"), let url = URL.init(string: nonBranchLink) {
                    let _ = UserAccountManager.shared.application(application, open:url, options: [:])
                }
            }else if let referring_link = params["~referring_link"] as? String{
                if referring_link.contains("validate"), let url = URL.init(string: referring_link){
                    let _ = UserAccountManager.shared.application(application, open:url, options: [:])
                }
            }else if let mode = params["mode"] as? String, let oobCode = params["oobCode"] as? String {
                let _ = UserAccountManager.shared.applicationOpenLinkedWith(mode: mode, code: oobCode)
            }
        }
        
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        // Pushwoosh
        PushNotificationManager.push().delegate = self
        // UNUserNotificationCenter.current().delegate = PushNotificationManager.push().notificationCenterDelegate // Set to self in willFinishLaunching; forwards the calls to pushwoosh.
        PushNotificationManager.push().sendAppOpen()
        
    }
    
    fileprivate func frameworkSetupMainViewDidLoad() {
        RatingFlow.sharedInstance.start()
        
        
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
                    mainTabBarController.selectedViewController = mainTabBarController.discoverNavigationController
                }
            }
        }
        else {
            let tutorialNavigationController = TutorialNavigationController.init(nibName: nil, bundle: nil)
            tutorialNavigationController.tutorialDelegate = self
            viewController = tutorialNavigationController
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

extension AppDelegate : TutorialNavigationControllerDelegate {
    func tutorialNavigationControllerDidComplete(_ viewController: TutorialNavigationController) {
        viewController.delegate = nil
        
        // Create a delay for a more natural feel after taking the screenshot
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.transitionTo(self.nextViewController())
        }
    }
}

// MARK: - Push Notifications

extension AppDelegate: PushNotificationDelegate {
    
    //this event is fired when the push gets received
    func onPushReceived(_ pushManager: PushNotificationManager!, withNotification pushNotification: [AnyHashable : Any]!, onStart: Bool) {
        print("pushwoosh notification received: \(pushNotification)")
        // shows a push is received. Implement passive reaction to a push here, such as UI update or data download.
    }
    
    //this event is fired when user taps the notification
    func onPushAccepted(_ pushManager: PushNotificationManager!, withNotification pushNotification: [AnyHashable : Any]!, onStart: Bool) {
        print("pushwoosh notification accepted: \(pushNotification)")
        // shows a user tapped the notification. Implement user interaction, such as showing push details
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        PushNotificationManager.push().handlePushRegistration(deviceToken)
        
        UserDefaults.standard.set(deviceToken, forKey: UserDefaultsKeys.deviceToken)
        UserDefaults.standard.synchronize()
        Analytics.trackUserProperties(analyticsUser: AnalyticsUser.current)
        SilentPushSubscriptionManager.sharedInstance.updateSubscriptionsIfNeeded()
        
        NotificationCenter.default.post(name: .applicationDidRegisterForRemoteNotifications, object: deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        PushNotificationManager.push().handlePushRegistrationFailure(error)
        
        let e = error as NSError
        Analytics.trackError(type: nil, domain: e.domain, code: e.code, localizedDescription: e.localizedDescription)
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
                                screenshot.submittedFeedbackCountGoalDate =  Date.init(timeIntervalSinceNow: period)
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
                   completionHandler(.newData) // Rose explains .newData is really telling Apple it was worthwhile being woken
                }
            }
        } else if let aps = userInfo["aps"] as? [String : Any],
          let category = aps["category"] as? String,
          category == "PRICE_ALERT",
          let dataDict = userInfo["data"] as? [String : Any],
          let id = dataDict["variantId"] as? String,
          !id.isEmpty {
            LocalNotificationModel.shared.cancelPendingNotifications(within: Date(timeIntervalSinceNow: Constants.secondsInDay))
            let pushTypeString = dataDict["type"] as? String
            Analytics.trackAppReceivedPushNotification(source: pushTypeString)
            PushNotificationManager.push().handlePushReceived(userInfo)  // pushwoosh
            completionHandler(.newData)
        } else {
            // Only spin up a background task if we are already in the background
            if application.applicationState == .background {
                if bgTask != UIBackgroundTaskInvalid {
                    application.endBackgroundTask(self.bgTask)
                }
                bgTask = application.beginBackgroundTask(withName: "LongRunningSync", expirationHandler: {
                    application.endBackgroundTask(self.bgTask)
                    self.bgTask = UIBackgroundTaskInvalid
                })
            }

            if let aps = userInfo["aps"] as? [String : Any],
              aps.count <= 3,
              let contentAvailable = aps["content-available"] as? NSNumber,
              contentAvailable.intValue == 1 {
                Analytics.trackAppReceivedPushNotification(source: "silent")
                completionHandler(.newData)
            } else {
                Branch.getInstance().handlePushNotification(userInfo)
                completionHandler(.noData)
            }
        }
    }
    
    @objc fileprivate func badgeNumberDidChange(_ notification: Notification) {
        let count = AccumulatorModel.screenshotUninformed.uninformedCount
        UIApplication.shared.applicationIconBadgeNumber = count
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
        var isHandled = false
        if let userInfo = response.notification.request.content.userInfo as? [String : Any] {
            if let openingScreen = userInfo[Constants.openingScreenKey] as? String {
                isHandled = true
                if openingScreen == Constants.openingScreenValueScreenshot {
                    if let openingAssetId = userInfo[Constants.openingAssetIdKey] as? String {
                        if response.notification.request.identifier == LocalNotificationIdentifier.saleScreenshot.rawValue {
                            // Go into screenshot for saleScreenshot local notification.
                            showScreenshotListTop()
                            let dataModel = DataModel.sharedInstance
                            if let mainTabBarController = self.window?.rootViewController as? MainTabBarController,
                              let screenshot = dataModel.retrieveScreenshot(managedObjectContext: dataModel.mainMoc(), assetId: openingAssetId) {
                                mainTabBarController.screenshotsNavigationController.presentScreenshot(screenshot)
                            }
                        } else {
                            // Show screenshot as first in screenshots list for screenshotAdded local notification.
                            AssetSyncModel.sharedInstance.importPhotosToScreenshot(assetIds: [openingAssetId], source: .screenshot)
                            showScreenshotListTop()
                        }
                    } else {
                        showScreenshotListTop()
                    }
                } else if openingScreen == Constants.openingScreenValueDiscover {
                    if let mainTabBarController = self.window?.rootViewController as? MainTabBarController {
                        mainTabBarController.goTo(tab: .discover)
                    }
                }
            } else if let openingProductKey = userInfo[Constants.openingProductKey] as? String {
                isHandled = true
                ProductViewController.present(imageURL: openingProductKey)
            } else if let aps = userInfo["aps"] as? [String : Any],
              let category = aps["category"] as? String,
              category == "PRICE_ALERT",
              let dataDict = userInfo["data"] as? [String : Any],
              let id = dataDict["variantId"] as? String,
              !id.isEmpty {
                isHandled = true
                if let updatedPrice = dataDict["price"] as? Float {
                    let currency = dataDict["currency"] as? String ?? "USD"
                    DataModel.sharedInstance.updateProductPrice(id: id, updatedPrice: updatedPrice, updatedCurrency: currency).then(on: .main) {
                        ProductViewController.present(with: id)
                    }
                } else {
                    ProductViewController.present(with: id)
                }
                let pushTypeString = dataDict["type"] as? String
                Analytics.trackAppOpenedFromPushNotification(source: pushTypeString)
            }
        }
        
        guard isHandled else {
            PushNotificationManager.push().notificationCenterDelegate.userNotificationCenter?(center, didReceive: response, withCompletionHandler: completionHandler)
            return
        }
        
        completionHandler()
        switch response.notification.request.identifier {
        case LocalNotificationIdentifier.inactivityDiscover.rawValue:
            Analytics.trackAppOpenedFromTimedLocalNotification(source: .inactivityDiscover)
        case LocalNotificationIdentifier.favoritedItem.rawValue:
            Analytics.trackAppOpenedFromTimedLocalNotification(source: .favoritedItem)
        case LocalNotificationIdentifier.tappedProduct.rawValue:
            Analytics.trackAppOpenedFromTimedLocalNotification(source: .tappedProduct)
        case LocalNotificationIdentifier.saleScreenshot.rawValue:
            Analytics.trackAppOpenedFromTimedLocalNotification(source: .saleCount)
        case let x where x.hasPrefix(LocalNotificationIdentifier.screenshotAdded.rawValue):
            Analytics.trackAppOpenedFromLocalNotification()
        default:
            break
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if notification.request.content.categoryIdentifier == "PRICE_ALERT" {
            completionHandler([.alert, .badge, .sound])
        } else {
            completionHandler([])
        }
    }
    
}
