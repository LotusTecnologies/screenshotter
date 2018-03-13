//
//  ThankYouForSharingView.swift
//  screenshot
//
//  Created by Jonathan Rose on 3/13/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import UIKit

class ThankYouForSharingView : UIViewController {
    
    private let transitioning = ViewControllerTransitioningDelegate.init(presentation: .intrinsicContentSize, transition: .modal)
    
    var closeButton:MainButton?
    
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
        
        let containerView = self.view! //UIView.init()
        let title = UILabel.init()
        let message = UILabel.init()
        let closeButton = MainButton.init()

        /*
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = .defaultCornerRadius
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 3
        containerView.layer.shadowOpacity = 0.5
        containerView.layer.borderColor = UIColor.black.cgColor
        containerView.layer.borderWidth = 1.0
        containerView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(containerView)
        containerView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        containerView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        containerView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        containerView.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 0.75)
        */
        
        title.text = "share_to_discover.thank_you_popup.title".localized
        title.textAlignment = .center
        title.numberOfLines = 0
        title.font = UIFont.init(name: "Hind", size: 25)
        title.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(title)
        title.topAnchor.constraint(equalTo: containerView.topAnchor, constant:120).isActive = true
        title.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant:20).isActive = true
        title.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant:-20).isActive = true

        
        message.text = "share_to_discover.thank_you_popup.message".localized
        message.textAlignment = .center
        message.numberOfLines = 0
        message.textColor = .crazeGreen
        message.font = UIFont.init(name: "Hind", size: 18)
        message.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(message)
        message.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 20).isActive =  true
        message.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant:20).isActive = true
        message.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant:-20).isActive = true
        
        let image = UIImage.init(named: "ThumbsUpBanner")
        let thumbsUpBanner = UIImageView.init(image: image)
        thumbsUpBanner.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(thumbsUpBanner)
        thumbsUpBanner.topAnchor.constraint(equalTo: message.bottomAnchor, constant: 20).isActive = true
        thumbsUpBanner.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant:40).isActive = true
        thumbsUpBanner.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant:40).isActive = true
        var multipler:CGFloat = 0.1
        if let image = image {
            multipler = (image.size.height / image.size.width)
        }
        
        thumbsUpBanner.heightAnchor.constraint(equalTo: thumbsUpBanner.widthAnchor, multiplier: multipler).isActive = true

        closeButton.setTitle("generic.close".localized, for: .normal)
        closeButton.backgroundColor = .crazeRed
        closeButton.isUserInteractionEnabled = true
        closeButton.showsTouchWhenHighlighted = true
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.layer.cornerRadius = .defaultCornerRadius
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(closeButton)
        closeButton.topAnchor.constraint(equalTo: thumbsUpBanner.bottomAnchor, constant: 20).isActive = true
        closeButton.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.5).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: 50.0).isActive = true
        closeButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
//        closeButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)

        self.closeButton = closeButton
        
        
        let backgroundView = UIView.init()
        backgroundView.backgroundColor = .white
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        self.view.insertSubview(backgroundView, belowSubview: title)
        backgroundView.topAnchor.constraint(equalTo: title.topAnchor, constant:-40).isActive = true
        backgroundView.bottomAnchor.constraint(equalTo: closeButton.bottomAnchor, constant:20).isActive = true
        backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant:20).isActive = true
        backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant:-20).isActive = true
        
        
        backgroundView.layer.cornerRadius = .defaultCornerRadius
        backgroundView.layer.shadowColor = UIColor.black.cgColor
        backgroundView.layer.shadowOffset = CGSize(width: 0, height: 2)
        backgroundView.layer.shadowRadius = 3
        backgroundView.layer.shadowOpacity = 0.5
        backgroundView.layer.borderColor = UIColor.black.cgColor
        backgroundView.layer.borderWidth = 1.0
    }
    
}
