//
//  CartGiftCardConfirmationViewController.swift
//  screenshot
//
//  Created by Corey Werner on 5/9/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class CartGiftCardConfirmationViewController: UIViewController {
    let continueButton = MainButton()
    
    fileprivate let transitioning = ViewControllerTransitioningDelegate(presentation: .intrinsicContentSize, transition: .modal)
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        transitioningDelegate = transitioning
        modalPresentationStyle = .custom
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        let layoutGuide = UIView()
        layoutGuide.translatesAutoresizingMaskIntoConstraints = false
        layoutGuide.isHidden = true
        view.addSubview(layoutGuide)
        layoutGuide.topAnchor.constraint(equalTo: view.topAnchor, constant: .extendedPadding).isActive = true
        layoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: .padding).isActive = true
        layoutGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -.extendedPadding).isActive = true
        layoutGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -.padding).isActive = true
        
        let topBorderImageView = UIImageView()
        topBorderImageView.translatesAutoresizingMaskIntoConstraints = false
        topBorderImageView.backgroundColor = .crazeRed // TODO: replace with image
        topBorderImageView.contentMode = .scaleToFill
        view.addSubview(topBorderImageView)
        topBorderImageView.setContentCompressionResistancePriority(.required, for: .vertical)
        topBorderImageView.setContentHuggingPriority(.required, for: .vertical)
        topBorderImageView.heightAnchor.constraint(equalToConstant: 6).isActive = true
        topBorderImageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        topBorderImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        topBorderImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        let giftCardImageView = UIImageView(image: UIImage(named: "giftCard25USD"))
        giftCardImageView.translatesAutoresizingMaskIntoConstraints = false
        giftCardImageView.contentMode = .scaleAspectFit
        view.addSubview(giftCardImageView)
        giftCardImageView.setContentHuggingPriority(.required, for: .vertical)
        giftCardImageView.heightAnchor.constraint(equalToConstant: 90).isActive = true
        giftCardImageView.topAnchor.constraint(equalTo: layoutGuide.topAnchor).isActive = true
        giftCardImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .gray3
        titleLabel.font = .screenshopFont(.hindSemibold, textStyle: .title2, staticSize: true)
        titleLabel.text = "$25 gift card, coming your way!" // TODO: localize
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        view.addSubview(titleLabel)
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.topAnchor.constraint(equalTo: giftCardImageView.bottomAnchor, constant: .padding).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor).isActive = true
        
        let detailLabel = UILabel()
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.textColor = .gray4
        detailLabel.font = .screenshopFont(.hindSemibold, textStyle: .body, staticSize: true)
        detailLabel.text = "You’ll receive an email with redemption instructions shortly." // TODO: localize
        detailLabel.textAlignment = .center
        detailLabel.numberOfLines = 0
        view.addSubview(detailLabel)
        detailLabel.setContentHuggingPriority(.required, for: .vertical)
        detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: .padding).isActive = true
        detailLabel.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor).isActive = true
        detailLabel.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor).isActive = true
        
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.setTitle("Awesome!", for: .normal) // TODO: localize
        continueButton.backgroundColor = .crazeGreen
        view.addSubview(continueButton)
        continueButton.setContentHuggingPriority(.required, for: .vertical)
        continueButton.topAnchor.constraint(equalTo: detailLabel.bottomAnchor, constant: .extendedPadding).isActive = true
        continueButton.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor).isActive = true
        continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }
}
