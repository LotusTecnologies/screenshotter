//
//  CheckoutConfirmationViewController.swift
//  screenshot
//
//  Created by Corey Werner on 3/9/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit
import Whisper

class CheckoutConfirmationViewController: BaseViewController {
    fileprivate let helperView = HelperView()
    var email: String?
    var orderNumber:String?
    var shouldPresentGiftCardModal = false
    
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
            if let orderNumber = orderNumber, !orderNumber.isEmpty {
                message += "\n\n" + "checkout.confirmation.orderNumber".localized
                message += "\n" + "checkout.confirmation.orderNumber2".localized(withFormat: orderNumber)
            }
            
            let attributedString = NSMutableAttributedString(string: message)
            
            if let email = email {
                let emailRange = NSString(string: message).range(of: email)
                attributedString.addAttribute(.foregroundColor, value: UIColor.crazeGreen, range: emailRange)
            }
            
            if let orderNumber = orderNumber {
                let orderRange = NSString(string: message).range(of: orderNumber)
                
                var attributes:[NSAttributedStringKey:Any] = [:]
                attributes[.foregroundColor] = UIColor.black
                attributes[.underlineColor] = UIColor.black
                attributes[.underlineStyle] = NSUnderlineStyle.styleSingle.rawValue
                attributedString.addAttributes(attributes, range: orderRange)
            }
            
            return attributedString
        }()
        
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(didTap(gesture:)))
        helperView.subtitleLabel.addGestureRecognizer(tap)
        helperView.subtitleLabel.isUserInteractionEnabled = true
        
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if shouldPresentGiftCardModal {
           shouldPresentGiftCardModal = false
            
            let viewController = CartGiftCardConfirmationViewController()
            viewController.continueButton.addTarget(self, action: #selector(dismissGiftCardConfirmation), for: .touchUpInside)
            present(viewController, animated: true, completion: nil)
        }
    }
    
    @objc private func dismissGiftCardConfirmation() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc fileprivate func navigateToScreenshotTab() {
        MainTabBarController.resetViewControllerHierarchy(self, select: .screenshots)
    }
    
    @objc func didTap( gesture:UITapGestureRecognizer){
        if gesture.state == .recognized {
            if let orderNumber = orderNumber {
                let pasteBoard = UIPasteboard.general
                pasteBoard.string = orderNumber
                
                if let navigationController = self.navigationController {
                    let message = Message(title: "checkout.confirmation.orderNumber.savedToClipBoard".localized, backgroundColor: .crazeGreen)
                    
                    Whisper.show(whisper: message, to: navigationController, action: .show)
                }
            }
        }
    }
}
