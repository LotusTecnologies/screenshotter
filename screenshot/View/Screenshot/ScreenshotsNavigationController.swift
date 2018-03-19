//
//  ScreenshotsNavigationController.swift
//  screenshot
//
//  Created by Jonathan Rose on 2/21/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

protocol ScreenshotsNavigationControllerDelegate: NSObjectProtocol {
    func screenshotsNavigationControllerDidGrantPushPermissions(_ navigationController: ScreenshotsNavigationController)
}

class ScreenshotsNavigationController: UINavigationController {
    weak var screenshotsNavigationControllerDelegate:ScreenshotsNavigationControllerDelegate?
    var screenshotsViewController:ScreenshotsViewController = ScreenshotsViewController()
    var pickerNavigationController:ScreenshotPickerNavigationController?
    var clipView:ClipView?
    var activityBarButtonItem:UIBarButtonItem?
    var previousDidAppearViewControllerWasProductViewController = false
    
    var restoredScreenshotNumber:Int?
    
    init() {
        super.init(nibName: nil, bundle: nil)
        screenshotsViewController.navigationItem.leftBarButtonItem = screenshotsViewController.editButtonItem
        screenshotsViewController.navigationItem.rightBarButtonItem?.tintColor = .crazeRed
        screenshotsViewController.navigationItem.rightBarButtonItem = UIBarButtonItem.init(image: UIImage.init(named: "NavigationBarAddPhotos"), style: .plain, target: self, action: #selector(presentPickerViewController))
        screenshotsViewController.delegate = self
        screenshotsViewController.lifeCycleDelegate = self
        
        self.restorationIdentifier = "ScreenshotsNavigationController"
        NotificationCenter.default.addObserver(self, selector: #selector(coreDataStackCompleted(_:)), name: .coreDataStackCompleted, object: nil)
        
        self.viewControllers = [self.screenshotsViewController]
        
        AssetSyncModel.sharedInstance.networkingIndicatorDelegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        AssetSyncModel.sharedInstance.networkingIndicatorDelegate = self
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad(){
        super.viewDidLoad()
        self.view.backgroundColor = .background
    }
    
}
//picker
extension ScreenshotsNavigationController {
    func createScreenshotPickerNavigationController()->ScreenshotPickerNavigationController{
        let navigationController = ScreenshotPickerNavigationController.init(nibName: nil, bundle: nil)
        navigationController.cancelButton.target = self
        navigationController.cancelButton.action = #selector(pickerViewControllerDidCancel)
        navigationController.doneButton.target = self
        navigationController.doneButton.action = #selector(pickerViewControllerDidFinish)
        return navigationController
    }
    
    func needsToPresentPickerViewController() -> Bool {
        return !UserDefaults.standard.bool(forKey: UserDefaultsKeys.onboardingPresentedScreenshotPicker)
    }
    
    func presentPickerViewController() {
        self.dismissPickerClipView()
        
        let picker = self.createScreenshotPickerNavigationController()
        self.pickerNavigationController = picker // ???: is this needed?
        self.present(picker, animated: true, completion: nil)
        
        UserDefaults.standard.setValue(true, forKey: UserDefaultsKeys.onboardingPresentedScreenshotPicker)
        
        AnalyticsTrackers.standard.track(.openedPicker)
    }
    
    func pickerViewControllerDidCancel() {
        self.dismiss(animated: true) {
            if self.needsToPresentPushAlert() {
                self.presentPushAlert()
            }
        }
    }
    func pickerViewControllerDidFinish(){
        self.pickerNavigationController = nil
        self.dismiss(animated: true, completion: nil)
    }
    
}
extension ScreenshotsNavigationController {
    @objc func coreDataStackCompleted(_ notification: Notification) {
        if let index = self.restoredScreenshotNumber {
            // Dispatch async to allow other listening objects to first do their setup
            DispatchQueue.main.async {
                if let productsViewController = self.topViewController as? ProductsViewController{
                    if let screenshot = self.screenshotsViewController.screenshot(at: index) {
                        productsViewController.screenshot = screenshot
                    }
                }
            }
            self.restoredScreenshotNumber = nil
        }
    }
}
extension ScreenshotsNavigationController : ViewControllerLifeCycle {
    func viewController(_ viewController: UIViewController, didAppear animated: Bool){
        if (viewController == self.screenshotsViewController &&
            self.previousDidAppearViewControllerWasProductViewController)
        {
            if self.needsToPresentPickerViewController() {
                // Allow the view controller transition view to cleanup
                DispatchQueue.main.async {
                    self.presentPickerClipView()
                }
                
                // Go back into Products before presenting the next view
                self.previousDidAppearViewControllerWasProductViewController = false
                
            } else if (self.needsToPresentPushAlert()) {
                self.presentPushAlert()
            }
        }
        
        if let _ = viewController as? ProductsViewController {
            self.previousDidAppearViewControllerWasProductViewController = true
        }else{
            self.previousDidAppearViewControllerWasProductViewController = false
        }
    }
}

extension ScreenshotsNavigationController :ScreenshotsViewControllerDelegate{
    func screenshotsViewController(_  viewController:ScreenshotsViewController, didSelectItemAt:IndexPath){
        if let screenshot = viewController.screenshot(at: didSelectItemAt.item){
            let productsViewController = ProductsViewController.init(screenshot: screenshot)
            
            productsViewController.lifeCycleDelegate = self
            productsViewController.hidesBottomBarWhenPushed = true
            self.pushViewController(productsViewController, animated: true)
            
            if (screenshot.isNew) {
                screenshot.setViewed()
            }
            RatingFlow.sharedInstance.recordSignificantEvent()
        }
    }
    
    func screenshotsViewControllerDeletedLastScreenshot(_  viewController:ScreenshotsViewController){
        if (self.needsToPresentPickerViewController()) {
            self.presentPickerClipView()
        }
    }
    func screenshotsViewControllerWantsToPresentPicker(_  viewController:ScreenshotsViewController){
        self.presentPickerViewController()
    }
}

extension ScreenshotsNavigationController { //push permission
    func needsToPresentPushAlert() -> Bool {
        return !UserDefaults.standard.bool(forKey: UserDefaultsKeys.onboardingPresentedPushAlert) && PermissionsManager.shared.hasPermission(for: .photo)
    }
    
    func presentPushAlert(){
        let alertController = UIAlertController.init(title: "screenshot.permission.push.title".localized, message: "screenshot.permission.push.message".localized, preferredStyle: .alert)
        alertController.addAction(UIAlertAction.init(title: "generic.ok".localized, style: .default, handler: { (a) in
            PermissionsManager.shared.requestPermission(for: .push, response: { (granted) in
                if (granted) {
                    self.screenshotsNavigationControllerDelegate?.screenshotsNavigationControllerDidGrantPushPermissions(self)
                    AnalyticsTrackers.standard.track(.acceptedPushPermissions)
                } else {
                    AnalyticsTrackers.standard.track(.deniedPushPermissions)
                }
            })
        }))
        self.present(alertController, animated: true, completion: nil)
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.onboardingPresentedPushAlert)
    }
}

extension ScreenshotsNavigationController : NetworkingIndicatorProtocol {
    func networkingIndicatorDidStart(type: NetworkingIndicatorType) {
        if (self.activityBarButtonItem == nil) {
            let activityView = UIActivityIndicatorView.init(activityIndicatorStyle: .white)
            activityView.color = .crazeRed
            activityView.startAnimating()
            let barButtonItem = UIBarButtonItem(customView: activityView)
            self.activityBarButtonItem = barButtonItem
            
            if let currentItem = self.screenshotsViewController.navigationItem.leftBarButtonItems?.first {
                self.screenshotsViewController.navigationItem.leftBarButtonItems = [currentItem, barButtonItem]
            }
        }
        
        self.activityBarButtonItem?.tag += 1
    }
    
    func networkingIndicatorDidComplete(type: NetworkingIndicatorType) {
        self.activityBarButtonItem?.tag -= 1
        
        if (self.activityBarButtonItem?.tag == 0) {
            if let currentItem = self.screenshotsViewController.navigationItem.leftBarButtonItems?.first {
                self.screenshotsViewController.navigationItem.leftBarButtonItems = [currentItem]
            }
            
            self.activityBarButtonItem = nil
        }
    }
}

//clipview
extension ScreenshotsNavigationController {
    func presentPickerClipView() {
        
        if (self.clipView == nil && !self.screenshotsViewController.isEditing) {
            if let tabBarView = self.tabBarController?.view {
                if let rightBarButtonView = self.screenshotsViewController.navigationItem.rightBarButtonItem?.targetView, let rightBarButtonViewSuperview = rightBarButtonView.superview {
                    
                    let rightBarButtonItemFrame = rightBarButtonView.frame
                    let rect = rightBarButtonViewSuperview.convert(rightBarButtonItemFrame, to:self.view)
                    let radius = min(rect.size.height / 2.0, rect.size.width / 2.0)
                    let croppedPath = UIBezierPath.init(roundedRect: rect, cornerRadius: radius)
                    
                    let clipView = ClipView()
                    clipView.translatesAutoresizingMaskIntoConstraints = false
                    clipView.clippings = [croppedPath]
                    clipView.alpha = 0.0
                    tabBarView.addSubview(clipView)
                    clipView.topAnchor.constraint(equalTo: tabBarView.topAnchor).isActive = true
                    clipView.leadingAnchor.constraint(equalTo: tabBarView.leadingAnchor).isActive = true
                    clipView.bottomAnchor.constraint(equalTo: tabBarView.bottomAnchor).isActive = true
                    clipView.trailingAnchor.constraint(equalTo: tabBarView.trailingAnchor).isActive = true
                    self.clipView = clipView
                    UIView.animate(withDuration: .defaultAnimationDuration, animations: {
                        self.clipView?.alpha = 1.0
                    })
                }
            }
        }
    }
    
    func dismissPickerClipView() {
        if let _ = self.clipView {
            UIView.animate(withDuration: .defaultAnimationDuration, animations: {
                self.clipView?.alpha = 0.0
                
            }, completion: { (finished) in
                self.clipView?.removeFromSuperview()
                self.clipView = nil
            })
        }
    }
}

extension ScreenshotsNavigationController  {
    override func encodeRestorableState(with coder: NSCoder){
        
        if let productsViewController = self.topViewController as? ProductsViewController {
            let screenshot = productsViewController.screenshot
            if let index = self.screenshotsViewController.indexOf(screenshot: screenshot) {
                coder.encode(index, forKey: "screenshotIndex")
            }
        }
        
        super.encodeRestorableState(with: coder)
    }
    
    override func decodeRestorableState(with coder: NSCoder){
        if coder.containsValue(forKey: "screenshotIndex") {
            self.restoredScreenshotNumber = coder.decodeInteger(forKey: "screenshotIndex")
        }
        
        super.decodeRestorableState(with: coder)
    }
    
}
