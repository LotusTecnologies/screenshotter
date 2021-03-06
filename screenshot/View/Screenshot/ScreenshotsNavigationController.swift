//
//  ScreenshotsNavigationController.swift
//  screenshot
//
//  Created by Jonathan Rose on 2/21/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit
import CoreData

protocol ScreenshotsNavigationControllerDelegate: NSObjectProtocol {
    func screenshotsNavigationControllerDidGrantPushPermissions(_ navigationController: ScreenshotsNavigationController)
}

class ScreenshotsNavigationController: UINavigationController {
    weak var screenshotsNavigationControllerDelegate:ScreenshotsNavigationControllerDelegate?
    var screenshotsViewController:ScreenshotsViewController = ScreenshotsViewController()
    fileprivate var restoredProductsViewController: ProductsViewController?
    
    
    init() {
        super.init(nibName: nil, bundle: nil)
        screenshotsViewController.navigationItem.rightBarButtonItem = screenshotsViewController.editButtonItem
        screenshotsViewController.delegate = self
        
        self.viewControllers = [self.screenshotsViewController]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .background
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UniversalSearchController.shared.updateInboxBadgeCount()
    }
}

extension ScreenshotsNavigationController: ViewControllerLifeCycle {
    func viewController(_ viewController: UIViewController, didDisappear animated: Bool) {
        if let productsViewController = viewController as? ProductsViewController, let _ = self.topViewController as? ScreenshotsViewController {
            if needsToPresentPushAlert {
                presentPushAlert()
            }
            
            let screenshot = productsViewController.screenshot
            AssetSyncModel.sharedInstance.clearSubShoppables(screenshot: screenshot)
        }
    }
}

typealias ScreenshotsNavigationControllerPicker = ScreenshotsNavigationController
extension ScreenshotsNavigationControllerPicker {
    func createScreenshotPickerNavigationController()->ScreenshotPickerNavigationController{
        let navigationController = ScreenshotPickerNavigationController.init(nibName: nil, bundle: nil)
        navigationController.cancelButton.target = self
        navigationController.cancelButton.action = #selector(pickerViewControllerDidCancel)
        navigationController.doneButton.target = self
        navigationController.doneButton.action = #selector(pickerViewControllerDidFinish)
        return navigationController
    }
    
    func presentPickerViewController(openScreenshots:Bool) {
        let picker = self.createScreenshotPickerNavigationController()
        picker.screenshotPickerViewController.openScreenshots = openScreenshots
        self.present(picker, animated: true, completion: nil)
        
        Analytics.trackOpenedPicker()
    }
    
    @objc func pickerViewControllerDidCancel() {
        self.dismiss(animated: true)
    }
    
    @objc func pickerViewControllerDidFinish(){
        self.dismiss(animated: true, completion: nil)
    }
}

extension ScreenshotsNavigationController :ScreenshotsViewControllerDelegate{
    func screenshotsViewController(_ viewController:ScreenshotsViewController, didSelectItemAt:IndexPath) {
        if viewController == self.topViewController {
            if let screenshot = viewController.screenshot(at: didSelectItemAt.item) {
                presentScreenshot(screenshot)
            }
        }
    }
    
    func presentScreenshot(_ screenshot: Screenshot, animated:Bool = true) {
        
        let productsViewController = createProductsViewController(screenshot: screenshot)
        self.pushViewController(productsViewController, animated: animated)
        
        if (screenshot.isNew) {
            if screenshot.source == .discover {
                AccumulatorModel.screenshotUninformed.decrementUninformedCount(by:1)
            }
            screenshot.setViewed()
        }
    }
    
    func screenshotsViewControllerWantsToPresentPicker(_  viewController:ScreenshotsViewController, openScreenshots:Bool){
        self.presentPickerViewController(openScreenshots:openScreenshots)
    }
}



typealias ScreenshotsNavigationControllerProducts = ScreenshotsNavigationController
extension ScreenshotsNavigationControllerProducts {
    func createProductsViewController(screenshot: Screenshot) -> ProductsViewController {
        let productsViewController = ProductsViewController(screenshot: screenshot)
        productsViewController.lifeCycleDelegate = self
        return productsViewController
    }
    
    func createRestoredProductsViewController() -> ProductsViewController? {
        // This solution does not work. The only solution is to design the ProductsViewController so it can be created without a screenshot. In the meantime, return nil and restoration wont work for this view controller.
        return nil
//        let tempScreenshot = Screenshot()
//        let productsViewController = createProductsViewController(screenshot: tempScreenshot)
//        restoredProductsViewController = productsViewController
//        return productsViewController
    }
}

typealias ScreenshotsNavigationControllerPushPermission = ScreenshotsNavigationController
extension ScreenshotsNavigationControllerPushPermission {
    fileprivate var needsToPresentPushAlert: Bool {
        return !UserDefaults.standard.bool(forKey: UserDefaultsKeys.onboardingPresentedPushAlert) && !PermissionsManager.shared.hasPermission(for: .push)
    }
    
    fileprivate func presentPushAlert() {
        let alertController = UIAlertController.init(title: "screenshot.permission.push.title".localized, message: "screenshot.permission.push.message".localized, preferredStyle: .alert)
        alertController.addAction(UIAlertAction.init(title: "generic.ok".localized, style: .default, handler: { action in
            PermissionsManager.shared.requestPermission(for: .push, response: { granted in
                if granted {
                    self.screenshotsNavigationControllerDelegate?.screenshotsNavigationControllerDidGrantPushPermissions(self)
                    Analytics.trackAcceptedPushPermissions()
                }
                else {
                    Analytics.trackDeniedPushPermissions()
                }
            })
        }))
        present(alertController, animated: true, completion: nil)
        
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.onboardingPresentedPushAlert)
        UserDefaults.standard.synchronize()
    }
}
