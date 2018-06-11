//
//  MainTabBarController.swift
//  screenshot
//
//  Created by Gershon Kagan on 2/12/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController, UITabBarControllerDelegate, ScreenshotsNavigationControllerDelegate, SettingsViewControllerDelegate, ScreenshotDetectionProtocol, ViewControllerLifeCycle {
    enum TabIndex: Int {
        case favorites   = 0
        case discover    = 1
        case screenshots = 2
        case settings    = 3
        case cart        = 4
    }
    
    weak var lifeCycleDelegate: ViewControllerLifeCycle?
    
    let screenshotsNavigationController = ScreenshotsNavigationController()
    let favoritesNavigationController = FavoritesNavigationController()
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
        
        func createTabBarItem(title: String?, imageNamed: String, tag: TabIndex) -> UITabBarItem {
            let tabBarItem = UITabBarItem(title: title, image: UIImage(named: imageNamed), tag: tag.rawValue)
            tabBarItem.badgeColor = .crazeRed
            return tabBarItem
        }
        
        screenshotsNavigationController.screenshotsNavigationControllerDelegate = self
        screenshotsNavigationController.title = screenshotsNavigationController.screenshotsViewController.title
        screenshotsNavigationController.tabBarItem = createTabBarItem(title: screenshotsNavigationController.title, imageNamed: "TabBarScreenshot", tag: .screenshots)
        
        favoritesNavigationController.title = favoritesNavigationController.favoritesViewController.title
        favoritesNavigationController.tabBarItem = createTabBarItem(title: favoritesNavigationController.title, imageNamed: "TabBarHeart", tag: .favorites)
        
        discoverNavigationController.title = discoverNavigationController.discoverScreenshotViewController.title
        discoverNavigationController.tabBarItem = createTabBarItem(title: discoverNavigationController.title, imageNamed: "TabBarGlobe", tag: .discover)
        
        settingsNavigationController.settingsViewController.delegate = self
        settingsNavigationController.title = settingsNavigationController.settingsViewController.title
        settingsNavigationController.tabBarItem = createTabBarItem(title: settingsNavigationController.title, imageNamed: "TabBarUser", tag: .settings)
        settingsTabBarItem = settingsNavigationController.tabBarItem
        
        cartNavigationController.title = cartNavigationController.cartViewController.title
        cartNavigationController.tabBarItem = createTabBarItem(title: cartNavigationController.title, imageNamed: "TabBarCart", tag: .cart)
        
        self.delegate = self
        self.restorationIdentifier = String(describing: type(of: self))
    
        var viewControllerList =  [
            screenshotsNavigationController,
            favoritesNavigationController,
            discoverNavigationController,
            settingsNavigationController
        ]
        if UIApplication.isUSC {
            viewControllerList.append(cartNavigationController)
        }
        viewControllers = viewControllerList
        selectedIndex = viewControllers?.index(of: screenshotsNavigationController) ?? 0
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: .UIApplicationDidBecomeActive, object: nil)
        notificationCenter.addObserver(self, selector: #selector(applicationUserDidTakeScreenshot(_:)), name: .UIApplicationUserDidTakeScreenshot, object: nil)
        notificationCenter.addObserver(self, selector: #selector(applicationFetchedAppSettings(_:)), name: .fetchedAppSettings, object: nil)
        
        notificationCenter.addObserver(self, selector: #selector(syncFavoriteTabBadgeCount), name: .FavoriteAccumulatorModelDidChange, object: nil)
        
        notificationCenter.addObserver(self, selector: #selector(syncShowingCart), name: .isUSCUpdated, object: nil)

        notificationCenter.addObserver(self, selector: #selector(syncScreenshotTabBadgeCount), name: .ScreenshotUninformedAccumulatorModelDidChange, object: nil)


        AssetSyncModel.sharedInstance.screenshotDetectionDelegate = self
        
        cartItemFrc = DataModel.sharedInstance.cartItemFrc(delegate: self)
        syncCartTabBadgeCount()
    }
    
    @objc public func syncShowingCart(){
        DispatchQueue.mainAsyncIfNeeded {
            let index = self.selectedIndex
            var viewControllerList =  [
                self.screenshotsNavigationController,
                self.favoritesNavigationController,
                self.discoverNavigationController,
                self.settingsNavigationController
            ]
            
            if UIApplication.isUSC {
                viewControllerList.append(self.cartNavigationController)
            }
            
            self.viewControllers = viewControllerList
            
            if viewControllerList.count > index {
                self.selectedIndex = index
            }else{
                self.selectedIndex = self.viewControllers?.index(of: self.screenshotsNavigationController) ?? 0
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        lifeCycleDelegate?.viewControllerDidLoad(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.lifeCycleDelegate?.viewController(self, willAppear: animated)
        
        self.refreshTabBarSettingsBadge()
        self.syncScreenshotTabBadgeCount()
        self.syncFavoriteTabBadgeCount()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.lifeCycleDelegate?.viewController(self, didAppear: animated)
        
        self.presentUpdatePromptIfNeeded()
        self.presentChangelogAlertIfNeeded()
        
        
        if let viewcontroller = self.selectedViewController {
            if viewcontroller == screenshotsNavigationController {
                AccumulatorModel.screenshotUninformed.resetUninformedCount()
            }
            if viewcontroller == favoritesNavigationController {
                AccumulatorModel.favorite.resetUninformedCount()
            }
        }

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.lifeCycleDelegate?.viewController(self, willDisappear: animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.lifeCycleDelegate?.viewController(self, didDisappear: animated)
    }
    
    @objc private func applicationDidBecomeActive(_ notification: Notification) {
        if self.view.window != nil {
            self.refreshTabBarSettingsBadge()
        }
    }
    
    @objc private func applicationUserDidTakeScreenshot(_ notification: Notification) {
        if self.view.window != nil {
            Analytics.trackTookScreenshot()
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
                settingsTabBarItem?.setBadgeTextAttributes([NSAttributedStringKey.font.rawValue : badgeFont], for: .normal)
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
    func goToCart(){
        if let index = self.viewControllers?.index(of: cartNavigationController){
            self.selectedIndex = index
        }
    }
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if self.selectedViewController == self.settingsNavigationController {
            self.settingsNavigationController.popToRootViewController(animated: false)
        }
        
        if viewController == screenshotsNavigationController {
            AccumulatorModel.screenshotUninformed.resetUninformedCount()
        }
        if viewController == favoritesNavigationController {
            AccumulatorModel.favorite.resetUninformedCount()
        }
        

        return true
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if let index = tabBar.items?.index(of: item) {
            if  let vcs = self.viewControllers, vcs.count > index {
                let viewcontroller = vcs[index]
                if let tabTitle = viewcontroller.title {
                    Analytics.trackTabBarTapped(tab: tabTitle)
                }
                if viewcontroller != screenshotsNavigationController {
                    AccumulatorModel.screenshotUninformed.resetUninformedCount()
                }
                if viewcontroller != favoritesNavigationController {
                    AccumulatorModel.favorite.resetUninformedCount()
                }
            }
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
    
    func pulse(tabBarItem:UITabBarItem){
        guard let tabView = tabBarItem.targetView else {
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
    func screenshotsTabPulseAnimation() {
        guard let tabView = screenshotsNavigationController.tabBarItem else {
            return
        }
        self.pulse(tabBarItem: tabView)
    }
    func cartTabPulseAnimation() {
        guard let tabView = cartNavigationController.tabBarItem else {
            return
        }
        self.pulse(tabBarItem: tabView)
    }

    
    fileprivate func syncCartTabBadgeCount() {
        let count = cartItemFrc?.fetchedObjectsCount ?? 0
        cartNavigationController.tabBarItem.badgeValue = count > 0 ? "\(count)" : nil
    }
    
    @objc func syncScreenshotTabBadgeCount() {
        let count = AccumulatorModel.screenshotUninformed.uninformedCount
        screenshotsNavigationController.tabBarItem.badgeValue = count > 0 ? "\(count)" : nil
    }
    
    @objc func syncFavoriteTabBadgeCount() {
        let count = AccumulatorModel.favorite.uninformedCount
        favoritesNavigationController.tabBarItem.badgeValue = count > 0 ? "\(count)" : nil
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
}

extension MainTabBarController: FetchedResultsControllerManagerDelegate {
    func managerDidChangeContent(_ controller: NSObject, change: FetchedResultsControllerManagerChange) {
        syncCartTabBadgeCount()
    }
}
