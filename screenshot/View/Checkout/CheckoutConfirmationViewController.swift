//
//  CheckoutConfirmationViewController.swift
//  screenshot
//
//  Created by Corey Werner on 3/9/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class CheckoutConfirmationViewController: BaseViewController {
    fileprivate let helperView = HelperView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addNavigationItemLogo()
        navigationItem.hidesBackButton = true
        
        helperView.translatesAutoresizingMaskIntoConstraints = false
        helperView.titleLabel.text = "checkout.confirmation.title".localized
        helperView.subtitleLabel.text = "checkout.confirmation.detail".localized
        helperView.contentImage = UIImage(named: "CheckoutDeliveryBox")
        view.addSubview(helperView)
        helperView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: .extendedPadding).isActive = true
        helperView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        helperView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor, constant: -.extendedPadding).isActive = true
        helperView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        let button = MainButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("generic.close".localized, for: .normal)
        button.backgroundColor = .crazeGreen
        button.addTarget(self, action: #selector(navigateToScreenshotTab), for: .touchUpInside)
        helperView.controlView.addSubview(button)
        button.topAnchor.constraint(equalTo: helperView.controlView.topAnchor).isActive = true
        button.bottomAnchor.constraint(equalTo: helperView.controlView.bottomAnchor).isActive = true
        button.centerXAnchor.constraint(equalTo: helperView.controlView.centerXAnchor).isActive = true
    }
    
    @objc fileprivate func navigateToScreenshotTab() {
//        func select(_ tabBarController: MainTabBarController) {
//            tabBarController.selectedViewController = tabBarController.screenshotsNavigationController
//        }
//        
//        func popToRoot(_ tabBarController: MainTabBarController) {
//            if let navigationController = tabBarController.selectedViewController as? UINavigationController {
//                navigationController.popToRootViewController(animated: false)
//            }
//        }
//        
//        func dismiss(_ tabBarController: MainTabBarController) {
//            tabBarController.dismiss(animated: true, completion: nil)
//        }
//        
//        if let mainTabBarController = presentingViewController as? MainTabBarController {
//            select(mainTabBarController)
//            dismiss(mainTabBarController)
//        }
//        else if let mainTabBarController = presentingViewController?.tabBarController as? MainTabBarController {
//            select(mainTabBarController)
//            dismiss(mainTabBarController)
//        }
//        else if let mainTabBarController = tabBarController as? MainTabBarController {
//            popToRoot(mainTabBarController)
//            select(mainTabBarController)
//        }
    }
}
