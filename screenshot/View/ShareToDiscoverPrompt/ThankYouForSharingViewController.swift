//
//  ThankYouForSharingViewController.swift
//  screenshot
//
//  Created by Jonathan Rose on 3/13/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import Foundation
import UIKit

class ThankYouForSharingViewController : UIViewController {
    private let transitioning = ViewControllerTransitioningDelegate.init(presentation: .intrinsicContentSize, transition: .modal)
    
    let closeButton = MainButton()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        transitioningDelegate = transitioning
        modalPresentationStyle = .custom
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        // iOS 10 doesn't support setting view.layoutMargins in viewDidLoad. Use a guide for simple edge adjustment.
        let layoutMarginsGuide = UIView()
        layoutMarginsGuide.translatesAutoresizingMaskIntoConstraints = false
        layoutMarginsGuide.isHidden = true
        view.addSubview(layoutMarginsGuide)
        layoutMarginsGuide.topAnchor.constraint(equalTo: view.topAnchor, constant: .extendedPadding).isActive = true
        layoutMarginsGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: .padding).isActive = true
        layoutMarginsGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -.extendedPadding).isActive = true
        layoutMarginsGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -.padding).isActive = true
        layoutMarginsGuide.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -.padding * 2).isActive = true
        
        let titleLabel = UILabel()
        titleLabel.text = "share_to_discover.thank_you_popup.title".localized
        titleLabel.textColor = .gray3
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.font = .systemFont(ofSize: 28)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        view.addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true

        let messageLabel = UILabel()
        messageLabel.text = "share_to_discover.thank_you_popup.message".localized
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.textColor = .crazeGreen
        messageLabel.font = .systemFont(ofSize: 20)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        view.addSubview(messageLabel)
        messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: .padding).isActive =  true
        messageLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        messageLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        let imageViewPadding: CGFloat = 24
        
        let thumbsUpImageView = UIImageView(image: UIImage(named: "ShareToMatchsticksThumbsUp"))
        thumbsUpImageView.translatesAutoresizingMaskIntoConstraints = false
        thumbsUpImageView.contentMode = .scaleAspectFit
        thumbsUpImageView.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        view.addSubview(thumbsUpImageView)
        thumbsUpImageView.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: imageViewPadding).isActive = true
        thumbsUpImageView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        thumbsUpImageView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        closeButton.setTitle("generic.close".localized, for: .normal)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        view.addSubview(closeButton)
        closeButton.topAnchor.constraint(equalTo: thumbsUpImageView.bottomAnchor, constant: imageViewPadding).isActive = true
        closeButton.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
        closeButton.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor).isActive = true
    }
}
