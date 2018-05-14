//
//  ScreenshotsNavigationController.swift
//  screenshot
//
//  Created by Jonathan Rose on 2/21/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import CoreData

protocol ScreenshotsNavigationControllerDelegate: NSObjectProtocol {
    func screenshotsNavigationControllerDidGrantPushPermissions(_ navigationController: ScreenshotsNavigationController)
}

class ScreenshotsNavigationController: UINavigationController {
    weak var screenshotsNavigationControllerDelegate:ScreenshotsNavigationControllerDelegate?
    var screenshotsViewController:ScreenshotsViewController = ScreenshotsViewController()
    var activityBarButtonItem:UIBarButtonItem?
    
    fileprivate var restoredProductsViewController: ProductsViewController?
    
    init() {
        super.init(nibName: nil, bundle: nil)
        screenshotsViewController.navigationItem.leftBarButtonItem = screenshotsViewController.editButtonItem
        screenshotsViewController.navigationItem.rightBarButtonItem?.tintColor = .crazeRed
        screenshotsViewController.navigationItem.rightBarButtonItem = UIBarButtonItem.init(image: UIImage.init(named: "NavigationBarAddPhotos"), style: .plain, target: self, action: #selector(pickerButtonPresses(_:)))
        screenshotsViewController.delegate = self
        
        self.restorationIdentifier = "ScreenshotsNavigationController"
        
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .background
    }
}

extension ScreenshotsNavigationController {
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
    @objc func pickerButtonPresses(_ sender:Any) {
        self.presentPickerViewController(openScreenshots: false)
    }
    
    @objc func pickerViewControllerDidCancel() {
        self.dismiss(animated: true) {
            if self.needsToPresentPushAlert() {
                self.presentPushAlert()
            }
        }
    }
    
    @objc func pickerViewControllerDidFinish(){
        self.dismiss(animated: true, completion: nil)
    }
}

extension ScreenshotsNavigationController :ScreenshotsViewControllerDelegate{
    func screenshotsViewController(_ viewController:ScreenshotsViewController, didSelectItemAt:IndexPath) {
        if let screenshot = viewController.screenshot(at: didSelectItemAt.item) {
            let screenshotOID = screenshot.objectID
            let _ = ShoppingCartModel.shared.checkStock(screenshotOID: screenshotOID)
            
            let productsViewController = createProductsViewController(screenshot: screenshot)
            self.pushViewController(productsViewController, animated: true)
            
            if (screenshot.isNew) {
                if screenshot.source == .discover {
                    AccumulatorModel.screenshotUninformed.decrementUninformedCount(by:1)
                }
                screenshot.setViewed()
            }
            
            RatingFlow.sharedInstance.recordSignificantEvent()
        }
    }
    
    func screenshotsViewControllerDeletedLastScreenshot(_  viewController:ScreenshotsViewController){
        
    }
    func screenshotsViewControllerWantsToPresentPicker(_  viewController:ScreenshotsViewController, openScreenshots:Bool){
        self.presentPickerViewController(openScreenshots:openScreenshots)
    }
}

extension ScreenshotsNavigationController: GiftCardCampaignViewControllerDelegate {
    func presentGiftCardCampaign() {
        let viewController = GiftCardCampaignViewController()
        viewController.delegate = self
        present(viewController, animated: true, completion: nil)
        
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.onboardingPresentedGiftCard)
    }
    
    func giftCardCampaignViewControllerDidSkip(_ viewController: GiftCardCampaignViewController) {
        Analytics.trackOnboardingCampainCreditCardSkip()
        
        dismiss(animated: true, completion: nil)
    }
    
    func giftCardCampaignViewControllerDidContinue(_ viewController: GiftCardCampaignViewController) {
        Analytics.trackOnboardingCampainCreditCardLetsGo()
        
        MainTabBarController.resetViewControllerHierarchy(viewController, select: .cart)
    }
}

typealias ScreenshotsNavigationControllerProducts = ScreenshotsNavigationController
extension ScreenshotsNavigationControllerProducts {
    func createProductsViewController(screenshot: Screenshot) -> ProductsViewController {
        let productsViewController = ProductsViewController(screenshot: screenshot)
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
                    Analytics.trackAcceptedPushPermissions()
                } else {
                    Analytics.trackDeniedPushPermissions()
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

typealias ScreenshotsNavigationControllerStateRestoration = ScreenshotsNavigationController
extension ScreenshotsNavigationControllerStateRestoration {
    private var screenshotKey: String {
        return "screenshotKey"
    }
    
    override func encodeRestorableState(with coder: NSCoder) {
        if let productsViewController = topViewController as? ProductsViewController {
            coder.encode(productsViewController.screenshot.objectID.uriRepresentation(), forKey: screenshotKey)
        }
        
        super.encodeRestorableState(with: coder)
    }
    
    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
        
        // Below isn't needed until createRestoredProductsViewController is implemented
        guard "keep the below code alive" == "but make this fail" else {
            return
        }
        
        guard let _ = DataModel.sharedInstance.mainMoc().persistentStoreCoordinator else {
            return
        }
        
        if coder.containsValue(forKey: screenshotKey),
            let url = coder.decodeObject(forKey: screenshotKey) as? URL,
            let objectID = DataModel.sharedInstance.mainMoc().objectId(for: url),
            let screenshot = DataModel.sharedInstance.mainMoc().screenshotWith(objectId: objectID)
        {
            restoredProductsViewController?.screenshot = screenshot
        }
    }
}
