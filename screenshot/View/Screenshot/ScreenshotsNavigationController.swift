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
            if self.needsToPresentPushAlert {
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
    
    func screenshotsViewControllerWantsToPresentPicker(_  viewController:ScreenshotsViewController, openScreenshots:Bool){
        self.presentPickerViewController(openScreenshots:openScreenshots)
    }
}

extension ScreenshotsNavigationController: GiftCardCampaignViewControllerDelegate {
    fileprivate var giftCardActiveViewController: UIViewController {
        if let presentedViewController = presentedViewController, !presentedViewController.isBeingDismissed {
            return presentedViewController
        }
        
        return self
    }
    
    func presentGiftCardCampaignIfNeeded() {
        if UIApplication.isUSC && !UserDefaults.standard.bool(forKey: UserDefaultsKeys.onboardingPresentedGiftCard) {
            UserDefaults.standard.set(true, forKey: UserDefaultsKeys.onboardingPresentedGiftCard)
            UserDefaults.standard.synchronize()
            
            let viewController = GiftCardCampaignViewController()
            viewController.delegate = self
        
            giftCardActiveViewController.present(viewController, animated: true, completion: nil)
        }
    }
    
    func giftCardCampaignViewControllerDidSkip(_ viewController: GiftCardCampaignViewController) {
        Analytics.trackOnboardingCampainCreditCardSkip()
        
        giftCardActiveViewController.dismiss(animated: true, completion: nil)
    }
    
    func giftCardCampaignViewControllerDidContinue(_ viewController: GiftCardCampaignViewController) {
        Analytics.trackOnboardingCampainCreditCardLetsGo()
        
        giftCardActiveViewController.dismiss(animated: true, completion: nil)
        
        let viewController = CheckoutPaymentFormViewController(withCard: nil, isEditLayout: true, confirmBeforeSave: false, autoSaveBillAddressAsShippingAddress:true)
        viewController.title = "2018_05_01_campaign.payment".localized
        viewController.delegate = self
        
        let modalNavigationController = ModalNavigationController(rootViewController: viewController)
        giftCardActiveViewController.present(modalNavigationController, animated: true, completion: nil)
    }
}

extension ScreenshotsNavigationController: GiftCardDoneViewControllerDelegate {
    func giftCardDoneViewControllerDidPressDone(_ viewController: GiftCardDoneViewController) {
        let frc = DataModel.sharedInstance.cardFrc(delegate: nil).fetchedObjects.first
        Analytics.trackOnboardingCampainCreditCardDone(email: frc?.email, phone: frc?.phone)
        
        giftCardActiveViewController.dismiss(animated: true, completion: nil)
    }
}

extension ScreenshotsNavigationController: CheckoutFormViewControllerDelegate {
    func checkoutFormViewControllerDidAdd(_ viewController: CheckoutFormViewController) {
        Analytics.trackOnboardingCampainCreditCardEnteredCard()
        
        let doneViewController = GiftCardDoneViewController()
        doneViewController.delegate = self
        doneViewController.navigationItem.hidesBackButton = true
        viewController.navigationController?.pushViewController(doneViewController, animated: true)
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

typealias ScreenshotsNavigationControllerPushPermission = ScreenshotsNavigationController
extension ScreenshotsNavigationControllerPushPermission {
    fileprivate var needsToPresentPushAlert: Bool {
        return !UserDefaults.standard.bool(forKey: UserDefaultsKeys.onboardingPresentedPushAlert) && PermissionsManager.shared.hasPermission(for: .photo) && !PermissionsManager.shared.hasPermission(for: .push)
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
