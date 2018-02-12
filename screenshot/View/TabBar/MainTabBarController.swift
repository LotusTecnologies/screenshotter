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

    weak var lifeCycleDelegate: ViewControllerLifeCycle?

    var isObservingSettingsBadgeFont = false

    let favoritesNavigationController: FavoritesNavigationController
    let screenshotsNavigationController: ScreenshotsNavigationController
    let discoverNavigationController: DiscoverNavigationController
    let settingsNavigationController: SettingsNavigationController
    var settingsTabBarItem: UITabBarItem
    var updatePromptHandler: UpdatePromptHandler?
    let discoverTabTag = 2

    let TabBarBadgeFontKey = "view.badge.label.font"

    // MARK: - Lifecycle
    
    init() {
        screenshotsNavigationController = ScreenshotsNavigationController()
        favoritesNavigationController = FavoritesNavigationController(nibName: nil, bundle: nil)
        discoverNavigationController = DiscoverNavigationController(nibName: nil, bundle: nil)
        settingsNavigationController = SettingsNavigationController(nibName: nil, bundle: nil)
        settingsTabBarItem = settingsNavigationController.tabBarItem

        super.init(nibName: nil, bundle: nil)
        
        screenshotsNavigationController.screenshotsNavigationControllerDelegate = self
        screenshotsNavigationController.title = screenshotsNavigationController.screenshotsViewController.title
        screenshotsNavigationController.tabBarItem = self.tabBarItem(title: screenshotsNavigationController.title, image: UIImage(named: "TabBarScreenshot"), tag: 0)
        
        favoritesNavigationController.title = favoritesNavigationController.favoritesViewController.title
        favoritesNavigationController.tabBarItem = self.tabBarItem(title: favoritesNavigationController.title, image: UIImage(named: "TabBarHeart"), tag: 1)
        
        discoverNavigationController.title = discoverNavigationController.discoverScreenshotViewController.title
        discoverNavigationController.tabBarItem = self.tabBarItem(title: discoverNavigationController.title, image: UIImage(named: "TabBarGlobe"), tag: discoverTabTag)
        
        settingsNavigationController.settingsViewController.delegate = self
        settingsNavigationController.title = settingsNavigationController.settingsViewController.title
        settingsNavigationController.tabBarItem = self.tabBarItem(title: settingsNavigationController.title, image: UIImage(named: "TabBarUser"), tag: 3)
        settingsNavigationController.tabBarItem.badgeColor = UIColor.crazeRed
        settingsTabBarItem = settingsNavigationController.tabBarItem

        self.delegate = self
        self.restorationIdentifier = String(describing: type(of: self))
        
        self.viewControllers = [self.screenshotsNavigationController,
                                self.favoritesNavigationController,
                                self.discoverNavigationController,
                                self.settingsNavigationController]
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: .UIApplicationDidBecomeActive, object: nil)
        notificationCenter.addObserver(self, selector: #selector(applicationUserDidTakeScreenshot(_:)), name: .UIApplicationUserDidTakeScreenshot, object: nil)
        notificationCenter.addObserver(self, selector: #selector(applicationFetchedAppSettings(_:)), name: NSNotification.Name(rawValue: NotificationCenterKeys.fetchedAppSettings), object: nil)
        
        AssetSyncModel.sharedInstance.screenshotDetectionDelegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.lifeCycleDelegate?.viewController?(self, willAppear: animated)
        
        self.refreshTabBarSettingsBadge()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.lifeCycleDelegate?.viewController?(self, didAppear: animated)
        
        self.presentUpdatePromptIfNeeded()
        self.presentChangelogAlertIfNeeded()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.lifeCycleDelegate?.viewController?(self, willDisappear: animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.lifeCycleDelegate?.viewController?(self, didDisappear: animated)
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
                AnalyticsTrackers.standard.track("Took Screenshot While Showing Intercom Window", properties: nil)
            } else {
                AnalyticsTrackers.standard.track("Took Screenshot", properties: nil)
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
                self.settingsTabBarItem.setBadgeTextAttributes(nil, for: .normal)
                self.settingsTabBarItem.setBadgeTextAttributes([NSFontAttributeName : badgeFont], for: .normal)
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
        
        if item.tag == self.discoverTabTag {
            tabTitle = "Matchsticks"
        }
        
        if let tabTitle = tabTitle {
            AnalyticsTrackers.standard.track("Tab Bar tapped", properties:["tab": tabTitle])
        }
    }
    
    func presentTabBarSettingsBadge() {
        self.settingsTabBarItem.badgeValue = "!"
        
        if !isObservingSettingsBadgeFont {
            isObservingSettingsBadgeFont = true
            self.settingsTabBarItem.addObserver(self, forKeyPath: TabBarBadgeFontKey, options: .new, context: nil)
        }
    }
    
    func dismissTabBarSettingsBadge() {
        if isObservingSettingsBadgeFont {
            isObservingSettingsBadgeFont = false
            self.settingsTabBarItem.removeObserver(self, forKeyPath: TabBarBadgeFontKey)
        }
        
        self.settingsTabBarItem.badgeValue = nil
    }
    
    func refreshTabBarSettingsBadge() {
        let hasPhotoPermissions = PermissionsManager.shared._hasPhotoPermission()
        let hasPushPermissions = PermissionsManager.shared._hasPushPermission()
        
        if !hasPhotoPermissions || !hasPushPermissions {
            self.presentTabBarSettingsBadge()
        } else {
            self.dismissTabBarSettingsBadge()
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
    
    func backgroundScreenshotsWereTaken(assetIds: Set<String>) {
        if let assetId = assetIds.first {
            self.screenshotsNavigationController.screenshotsViewController.presentNotificationCell(withAssetId: assetId)
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
    
}
