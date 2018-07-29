//
//  MainTabBarController.swift
//  screenshot
//
//  Created by Gershon Kagan on 2/12/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController, UITabBarControllerDelegate, ScreenshotsNavigationControllerDelegate, ProfileViewControllerDelegate, ViewControllerLifeCycle {
    enum TabIndex {
        case favorites
        case discover
        case screenshots
        case profile
        case cart
        
        var tagValue: Int {
            switch self {
            case .favorites:
                return 1
            case .discover:
                return 2
            case .screenshots:
                return 3
            case .profile:
                return 4
            case .cart:
                return 5
            }
        }
    }
    
    weak var lifeCycleDelegate: ViewControllerLifeCycle?
    
    let screenshotsNavigationController = ScreenshotsNavigationController()
    let favoritesNavigationController = FavoritesNavigationController()
    let discoverNavigationController = DiscoverNavigationController()
    let profileNavigationController = ProfileNavigationController()
    
    fileprivate var settingsTabBarItem: UITabBarItem?
    var updatePromptHandler: UpdatePromptHandler?
    
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
            let tabBarItem = UITabBarItem(title: title, image: UIImage(named: imageNamed), tag: tag.tagValue)
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
        
        profileNavigationController.profileViewController.delegate = self
        profileNavigationController.title = profileNavigationController.profileViewController.title
        profileNavigationController.tabBarItem = createTabBarItem(title: profileNavigationController.title, imageNamed: "TabBarUser", tag: .profile)
        settingsTabBarItem = profileNavigationController.tabBarItem
        
        
        self.delegate = self
        self.restorationIdentifier = String(describing: type(of: self))
    
        let viewControllerList =  [
            screenshotsNavigationController,
            favoritesNavigationController,
            discoverNavigationController,
            profileNavigationController
        ]
      
        viewControllers = viewControllerList
        selectedIndex = viewControllers?.index(of: screenshotsNavigationController) ?? 0
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: .UIApplicationDidBecomeActive, object: nil)
        notificationCenter.addObserver(self, selector: #selector(applicationUserDidTakeScreenshot(_:)), name: .UIApplicationUserDidTakeScreenshot, object: nil)
        notificationCenter.addObserver(self, selector: #selector(applicationFetchedAppSettings(_:)), name: .fetchedAppSettings, object: nil)
        
        notificationCenter.addObserver(self, selector: #selector(syncFavoriteTabBadgeCount), name: .FavoriteUninformedAccumulatorModelDidChange, object: nil)
        

        notificationCenter.addObserver(self, selector: #selector(syncScreenshotTabBadgeCount), name: .ScreenshotUninformedAccumulatorModelDidChange, object: nil)
        
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
        presentGDPRIfNeeded()
        
        if let viewcontroller = self.selectedViewController {
            if viewcontroller == screenshotsNavigationController {
                AccumulatorModel.screenshotUninformed.resetUninformedCount()
            }
            if viewcontroller == favoritesNavigationController {
                AccumulatorModel.favoriteUninformed.resetUninformedCount()
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
            self.presentScreenshottingAlertIfNeeded()
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
        if isViewLoaded {
            self.dismissTabBarSettingsBadge()
        }
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Tab Bar
    
    func goToCart(){
        goTo(tab: .cart)
    }
    
    func goTo(tab: TabIndex) {
        func subViewControllers(_ vc:UIViewController) -> [UIViewController] {
            var subVC:[UIViewController] = vc.childViewControllers
            if let presentedViewController  = vc.presentedViewController{
                subVC.append(presentedViewController)
            }
            return subVC
        }
        
        func dismissViewController(_ vc:UIViewController) {
            let subViewController = subViewControllers(vc)
            for vc  in subViewController {
                dismissViewController(vc)
            }
            if vc.presentedViewController != nil {
                vc.dismiss(animated: false, completion: nil)
            }
            if let nav = vc.navigationController {
                nav.popToRootViewController(animated: false)
            }
        }
        
        if let current = self.selectedViewController {
            dismissViewController(current)
        }
        if let toSelect = self.viewControllers?.first(where: { (vc) -> Bool in
            return vc.tabBarItem.tag == tab.tagValue
        }) {
            self.selectedViewController = toSelect
        }
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if viewController == screenshotsNavigationController {
            AccumulatorModel.screenshotUninformed.resetUninformedCount()
        }
        if viewController == favoritesNavigationController {
            AccumulatorModel.favoriteUninformed.resetUninformedCount()
        }
        
        return true
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if let index = tabBar.items?.index(of: item), let vcs = self.viewControllers, vcs.count > index {
            let viewcontroller = vcs[index]
            
            if let tabTitle = viewcontroller.title {
                Analytics.trackTabBarTapped(tab: tabTitle)
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
    
    
    @objc func syncScreenshotTabBadgeCount() {
        let count = AccumulatorModel.screenshotUninformed.uninformedCount
        screenshotsNavigationController.tabBarItem.badgeValue = count > 0 ? "\(count)" : nil
    }
    
    @objc func syncFavoriteTabBadgeCount() {
        let count = AccumulatorModel.favoriteUninformed.uninformedCount
        favoritesNavigationController.tabBarItem.badgeValue = count > 0 ? "\(count)" : nil
    }
    
    // MARK: View Controllers
    
    static func resetViewControllerHierarchy(_ viewController: UIViewController, select tabIndex: MainTabBarController.TabIndex) {
        func popToRoot(_ tabBarController: MainTabBarController) {
            if let navigationController = tabBarController.selectedViewController as? UINavigationController {
                navigationController.popToRootViewController(animated: false)
            }
        }
        
        func dismiss(_ tabBarController: MainTabBarController) {
            tabBarController.dismiss(animated: true, completion: nil)
        }
        
        if let mainTabBarController = viewController.presentingViewController as? MainTabBarController {
            popToRoot(mainTabBarController)
            mainTabBarController.goTo(tab: tabIndex)
            dismiss(mainTabBarController)
        }
        else if let mainTabBarController = viewController.presentingViewController?.tabBarController as? MainTabBarController {
            popToRoot(mainTabBarController)
            mainTabBarController.goTo(tab: tabIndex)
            dismiss(mainTabBarController)
        }
        else if let mainTabBarController = viewController.tabBarController as? MainTabBarController {
            popToRoot(mainTabBarController)
            mainTabBarController.goTo(tab: tabIndex)
        }
    }
    
    // MARK: - Screenshots
    
    func screenshotsNavigationControllerDidGrantPushPermissions(_ navigationController: ScreenshotsNavigationController) {
        self.refreshTabBarSettingsBadge()
    }
    
    // MARK: - Profile View Controller
    
    func profileViewControllerDidGrantPermission(_ viewController: ProfileViewController) {
        self.refreshTabBarSettingsBadge()
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


typealias MainTabBarControllerGDPR = MainTabBarController
extension MainTabBarControllerGDPR: OnboardingGDPRViewControllerDelegate {
    private var needsToPresentGDPR: Bool {
        return UserDefaults.standard.value(forKey: UserDefaultsKeys.gdpr_agreedToEmail) == nil
    }
    
    private func presentGDPRIfNeeded() {
        guard needsToPresentGDPR else {
            return
        }
        
        let gdprViewController = OnboardingGDPRViewController()
        gdprViewController.delegate = self
        present(gdprViewController, animated: true)
    }
    
    func onboardingGDPRViewControllerDidComplete(_ viewController: OnboardingGDPRViewController) {
        dismiss(animated: true)
    }
}

// MARK: - Screenshotting

extension MainTabBarController {
    private func presentScreenshottingAlertIfNeeded() {
        guard let selectedViewController = self.selectedViewController else {
            return
        }
        
        var key: String?
        var title: String?
        var message: String?
        
        switch selectedViewController {
        case self.screenshotsNavigationController:
            if let _ = self.screenshotsNavigationController.topViewController as? ScreenshotsViewController {
                key = UserDefaultsKeys.screenshottingPresentedScreenshotAlert
                title = "screenshotting.screenshots.title".localized
                message = "screenshotting.screenshots.message".localized
            }
            else if let _ = self.screenshotsNavigationController.topViewController as? ProductsViewController {
                key = UserDefaultsKeys.screenshottingPresentedProductAlert
                title = "screenshotting.products.title".localized
                message = "screenshotting.products.message".localized
            }
        case self.discoverNavigationController:
            if let _ = self.discoverNavigationController.topViewController as? DiscoverScreenshotViewController {
                key = UserDefaultsKeys.screenshottingPresentedDiscoverAlert
                title = "screenshotting.discover.title".localized
                message = "screenshotting.discover.message".localized
            }
        default:
            break
        }
        
        if let key = key, !UserDefaults.standard.bool(forKey: key) {
            UserDefaults.standard.set(true, forKey: key)
            
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "generic.ok".localized, style: .cancel, handler: nil))
            self.present(alert, animated: true)
        }
    }
}
