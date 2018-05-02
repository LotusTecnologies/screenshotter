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
    var email: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addNavigationItemLogo()
        navigationItem.hidesBackButton = true
        
        helperView.translatesAutoresizingMaskIntoConstraints = false
        helperView.titleLabel.text = "checkout.confirmation.title".localized
        helperView.subtitleLabel.attributedText = {
            var message = "checkout.confirmation.detail".localized
            
            if let email = email, !email.isEmpty {
                message += "\n" + "checkout.confirmation.email".localized(withFormat: email)
            }
            
            let attributedString = NSMutableAttributedString(string: message)
            
            if let email = email {
                let emailRange = NSString(string: message).range(of: email)
                attributedString.addAttribute(.foregroundColor, value: UIColor.crazeGreen, range: emailRange)
            }
            
            return attributedString
        }()
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
        MainTabBarController.resetViewControllerHierarchy(self, select: .screenshots)
    }
}
