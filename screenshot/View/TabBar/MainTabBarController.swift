//
//  MainTabBarController.swift
//  screenshot
//
//  Created by Gershon Kagan on 2/12/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import Intercom

class MainTabBarController: UITabBarController, UITabBarControllerDelegate, ScreenshotsNavigationControllerDelegate, SettingsViewControllerDelegate, ScreenshotDetectionProtocol, ViewControllerLifeCycle {
    enum TabIndex: Int {
        case favorites   = 0
        case discover    = 1
        case screenshots = 2
        case settings    = 3
        case cart        = 4
    }
    
    weak var lifeCycleDelegate: ViewControllerLifeCycle?
    
    let favoritesNavigationController = FavoritesNavigationController()
    let screenshotsNavigationController = ScreenshotsNavigationController()
    let discoverNavigationController = DiscoverNavigationController()
    let settingsNavigationController = SettingsNavigationController()
    let cartNavigationController = CartNavigationController()
    
    fileprivate var settingsTabBarItem: UITabBarItem?
    var updatePromptHandler: UpdatePromptHandler?
    
    fileprivate var cartItemFrc: FetchedResultsControllerManager<CartItem>?
    
    fileprivate var isObservingSettingsBadgeFont = false
    fileprivate let TabBarBadgeFontKey = "view.badge.label.font"
    
    // MARK: - Lifecycle
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(delegate: ViewControllerLifeCycle) {
        lifeCycleDelegate = delegate
        
        // Important to note that super.init will call viewDidLoad before completing the init
        super.init(nibName: nil, bundle: nil)
        
        favoritesNavigationController.title = favoritesNavigationController.favoritesViewController.title
        favoritesNavigationController.tabBarItem = tabBarItem(title: favoritesNavigationController.title, image: UIImage(named: "TabBarHeart"), tag: TabIndex.favorites.rawValue)
        
        discoverNavigationController.title = discoverNavigationController.discoverScreenshotViewController.title
        discoverNavigationController.tabBarItem = tabBarItem(title: discoverNavigationController.title, image: UIImage(named: "TabBarGlobe"), tag: TabIndex.discover.rawValue)
        
        screenshotsNavigationController.screenshotsNavigationControllerDelegate = self
        screenshotsNavigationController.title = screenshotsNavigationController.screenshotsViewController.title
        screenshotsNavigationController.tabBarItem = tabBarItem(title: screenshotsNavigationController.title, image: UIImage(named: "TabBarScreenshot"), tag: TabIndex.screenshots.rawValue)
        
        settingsNavigationController.settingsViewController.delegate = self
        settingsNavigationController.title = settingsNavigationController.settingsViewController.title
        settingsNavigationController.tabBarItem = tabBarItem(title: settingsNavigationController.title, image: UIImage(named: "TabBarUser"), tag: TabIndex.settings.rawValue)
        settingsNavigationController.tabBarItem.badgeColor = .crazeRed
        settingsTabBarItem = settingsNavigationController.tabBarItem
        
        cartNavigationController.title = cartNavigationController.cartViewController.title
        cartNavigationController.tabBarItem = tabBarItem(title: cartNavigationController.title, image: UIImage(named: "TabBarCart"), tag: TabIndex.cart.rawValue)
        cartNavigationController.tabBarItem.badgeColor = .crazeRed
        
        self.delegate = self
        self.restorationIdentifier = String(describing: type(of: self))
    
        viewControllers = [
            favoritesNavigationController,
            discoverNavigationController,
            screenshotsNavigationController,
            settingsNavigationController,
            cartNavigationController
        ]
        selectedIndex = viewControllers?.index(of: screenshotsNavigationController) ?? 0
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: .UIApplicationDidBecomeActive, object: nil)
        notificationCenter.addObserver(self, selector: #selector(applicationUserDidTakeScreenshot(_:)), name: .UIApplicationUserDidTakeScreenshot, object: nil)
        notificationCenter.addObserver(self, selector: #selector(applicationFetchedAppSettings(_:)), name:.fetchedAppSettings, object: nil)
        
        AssetSyncModel.sharedInstance.screenshotDetectionDelegate = self
        
        cartItemFrc = DataModel.sharedInstance.cartItemFrc(delegate: self)
        syncCartTabItemCount()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        lifeCycleDelegate?.viewControllerDidLoad(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.lifeCycleDelegate?.viewController(self, willAppear: animated)
        
        self.refreshTabBarSettingsBadge()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.lifeCycleDelegate?.viewController(self, didAppear: animated)
        
        self.presentUpdatePromptIfNeeded()
        self.presentChangelogAlertIfNeeded()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.lifeCycleDelegate?.viewController(self, willDisappear: animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.lifeCycleDelegate?.viewController(self, didDisappear: animated)
    }

    @available(iOS, introduced: 11.0)
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        
        let offset: CGFloat = 16
        if let safeAreaInsetsBottom = self.view.window?.safeAreaInsets.bottom,
          safeAreaInsetsBottom > 0 {
            viewControllers?.forEach { viewController in
                viewController.tabBarItem.imageInsets = UIEdgeInsetsMake(offset, 0, -offset, 0)
            }
        }
    }
    
    @objc private func applicationDidBecomeActive(_ notification: Notification) {
        if self.view.window != nil {
            self.refreshTabBarSettingsBadge()
        }
    }
    
    @objc private func applicationUserDidTakeScreenshot(_ notification: Notification) {
        if self.view.window != nil {
            var foundIntercomWindow = false
            
            findWindowLoop: for window in UIApplication.shared.windows {
                if String(describing: type(of: window)).hasPrefix("ICMWindow") {
                    foundIntercomWindow = true
                    break findWindowLoop
                }
            }
            
            if foundIntercomWindow {
                AnalyticsTrackers.standard.track(.tookScreenshotWhileShowingIntercomWindow, properties: nil)
            } else {
                AnalyticsTrackers.standard.track(.tookScreenshot, properties: nil)
            }
        }
    }
    
    @objc private func applicationFetchedAppSettings(_ notification: Notification) {
        if self.isViewLoaded && self.view.window != nil {
            self.presentUpdatePromptIfNeeded()
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == TabBarBadgeFontKey {
            if let badgeFont = UIFont(name: "Optima-ExtraBlack", size: 14) {
                // Remove the previous value so UIKit recognizes the update.
                settingsTabBarItem?.setBadgeTextAttributes(nil, for: .normal)
                settingsTabBarItem?.setBadgeTextAttributes([NSFontAttributeName : badgeFont], for: .normal)
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    deinit {
        self.dismissTabBarSettingsBadge()
        AssetSyncModel.sharedInstance.screenshotDetectionDelegate = nil
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Tab Bar
    
    func tabBarItem(title: String?, image: UIImage?, tag: Int) -> UITabBarItem {
        let offset: CGFloat = 6
        let tabBarItem = UITabBarItem(title: title, image: image, tag: tag)
        tabBarItem.imageInsets = UIEdgeInsetsMake(offset, 0, -offset, 0)
        tabBarItem.titlePositionAdjustment = UIOffsetMake(0, self.tabBar.intrinsicContentSize.height * 2)
        return tabBarItem
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if self.selectedViewController == self.settingsNavigationController {
            self.settingsNavigationController.popToRootViewController(animated: false)
        }
        return true
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        var tabTitle = self.selectedViewController?.title
        
        if item.tag == TabIndex.discover.rawValue {
            tabTitle = "Matchsticks"
        }
        
        if let tabTitle = tabTitle {
            AnalyticsTrackers.standard.track(.tabBarTapped, properties:["tab": tabTitle])
        }
    }
    
    func presentTabBarSettingsBadge() {
        settingsTabBarItem?.badgeValue = "!"
        
        if !isObservingSettingsBadgeFont {
            isObservingSettingsBadgeFont = true
            settingsTabBarItem?.addObserver(self, forKeyPath: TabBarBadgeFontKey, options: .new, context: nil)
        }
    }
    
    func dismissTabBarSettingsBadge() {
        if isObservingSettingsBadgeFont {
            isObservingSettingsBadgeFont = false
            settingsTabBarItem?.removeObserver(self, forKeyPath: TabBarBadgeFontKey)
        }
        
        settingsTabBarItem?.badgeValue = nil
    }
    
    func refreshTabBarSettingsBadge() {
        let hasPhotoPermissions = PermissionsManager.shared.hasPermission(for: .photo)
        let hasPushPermissions = PermissionsManager.shared.hasPermission(for: .push)
        
        if !hasPhotoPermissions || !hasPushPermissions {
            self.presentTabBarSettingsBadge()
        } else {
            self.dismissTabBarSettingsBadge()
        }
    }
    
    func screenshotsTabPulseAnimation() {
        guard let tabView = screenshotsNavigationController.tabBarItem.targetView else {
            return
        }
        
        UIView.animateKeyframes(withDuration: 0.8, delay: 0, options: .allowUserInteraction, animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.2, animations: {
                tabView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            })
            UIView.addKeyframe(withRelativeStartTime: 0.2, relativeDuration: 0.4, animations: {
                tabView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            })
            UIView.addKeyframe(withRelativeStartTime: 0.4, relativeDuration: 0.6, animations: {
                tabView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            })
            UIView.addKeyframe(withRelativeStartTime: 0.6, relativeDuration: 0.8, animations: {
                tabView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            })
            UIView.addKeyframe(withRelativeStartTime: 0.8, relativeDuration: 1, animations: {
                tabView.transform = CGAffineTransform.identity
            })
        })
    }
    
    // MARK: View Controllers
    
    static func resetViewControllerHierarchy(_ viewController: UIViewController, select tabIndex: MainTabBarController.TabIndex) {
        func popToRoot(_ tabBarController: MainTabBarController) {
            if let navigationController = tabBarController.selectedViewController as? UINavigationController {
                navigationController.popToRootViewController(animated: false)
            }
        }
        
        func select(_ tabBarController: MainTabBarController) {
            tabBarController.selectedIndex = tabIndex.rawValue
        }
        
        func dismiss(_ tabBarController: MainTabBarController) {
            tabBarController.dismiss(animated: true, completion: nil)
        }
        
        if let mainTabBarController = viewController.presentingViewController as? MainTabBarController {
            popToRoot(mainTabBarController)
            select(mainTabBarController)
            dismiss(mainTabBarController)
        }
        else if let mainTabBarController = viewController.presentingViewController?.tabBarController as? MainTabBarController {
            popToRoot(mainTabBarController)
            select(mainTabBarController)
            dismiss(mainTabBarController)
        }
        else if let mainTabBarController = viewController.tabBarController as? MainTabBarController {
            popToRoot(mainTabBarController)
            select(mainTabBarController)
        }
    }
    
    // MARK: - Screenshots
    
    func screenshotsNavigationControllerDidGrantPushPermissions(_ navigationController: ScreenshotsNavigationController) {
        self.refreshTabBarSettingsBadge()
    }
    
    // MARK: - Settings View Controller
    
    func settingsViewControllerDidGrantPermission(_ viewController: SettingsViewController) {
        self.refreshTabBarSettingsBadge()
    }
    
    // MARK: - Foreground Screenshots
    
    func foregroundScreenshotTaken(assetId: String) {
        if self.selectedViewController != self.screenshotsNavigationController {
            NotificationManager.shared.presentForegroundScreenshot(withAssetId: assetId) {
                self.selectedViewController = self.screenshotsNavigationController
            }
        }
    }
    
    
    // MARK: - Update Prompt
    
    @objc func presentUpdatePromptIfNeeded() {
        if self.updatePromptHandler == nil {
            self.updatePromptHandler = UpdatePromptHandler()
            self.updatePromptHandler?.presentUpdatePromptIfNeeded()
        }
    }

    // MARK: - Changelog Alerts
    
    @objc func presentChangelogAlertIfNeeded() {
        ChangelogAlertController.presentIfNeeded(inViewController: self)
    }
    
    // MARK: - Cart
    
    fileprivate func syncCartTabItemCount() {
        let count = cartItemFrc?.fetchedObjectsCount ?? 0
        cartNavigationController.tabBarItem.badgeValue = count > 0 ? "\(count)" : nil
    }
}

extension MainTabBarController: FetchedResultsControllerManagerDelegate {
    func managerDidChangeContent(_ controller: NSObject, change: FetchedResultsControllerManagerChange) {
        syncCartTabItemCount()
    }
}
