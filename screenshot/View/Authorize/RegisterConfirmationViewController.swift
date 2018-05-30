//
//  RegisterConfirmationViewController.swift
//  screenshot
//
//  Created by Corey Werner on 5/29/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class RegisterConfirmationViewController: UIViewController {
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
        view.clipsToBounds = true
        
        let backgroundImageView = UIImageView(image: UIImage(named: "BrandConfettiColorContent"))
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        view.addSubview(backgroundImageView)
        backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        let topBorderImageView = UIImageView(image: UIImage(named: "BrandGradientBorder"))
        topBorderImageView.translatesAutoresizingMaskIntoConstraints = false
        topBorderImageView.contentMode = .scaleToFill
        view.addSubview(topBorderImageView)
        topBorderImageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        topBorderImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        topBorderImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        let iconImageView = UIImageView(image: UIImage(named: "BrandIcon110"))
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        view.addSubview(iconImageView)
        iconImageView.setContentHuggingPriority(.required, for: .vertical)
        iconImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: .extendedPadding).isActive = true
        iconImageView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.3).isActive = true
        iconImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        let titleLable = UILabel()
        titleLable.translatesAutoresizingMaskIntoConstraints = false
        titleLable.text = "authorize.register.confirmation.title".localized
        titleLable.textAlignment = .center
        titleLable.textColor = .gray2
        titleLable.font = .screenshopFont(.quicksandMedium, textStyle: .title1, staticSize: true)
        titleLable.adjustsFontSizeToFitWidth = true
        titleLable.minimumScaleFactor = 0.7
        titleLable.baselineAdjustment = .alignCenters
        view.addSubview(titleLable)
        titleLable.setContentHuggingPriority(.required, for: .vertical)
        titleLable.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: .padding).isActive = true
        titleLable.leadingAnchor.constraint(greaterThanOrEqualTo: view.layoutMarginsGuide.leadingAnchor).isActive = true
        titleLable.trailingAnchor.constraint(lessThanOrEqualTo: view.layoutMarginsGuide.trailingAnchor).isActive = true
        titleLable.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor).isActive = true
        
        let messageLable = UILabel()
        messageLable.translatesAutoresizingMaskIntoConstraints = false
        messageLable.text = "authorize.register.confirmation.message".localized
        messageLable.textAlignment = .center
        messageLable.textColor = .gray2
        messageLable.font = .screenshopFont(.quicksandMedium, textStyle: .title3, staticSize: true)
        messageLable.adjustsFontSizeToFitWidth = true
        messageLable.minimumScaleFactor = 0.7
        messageLable.baselineAdjustment = .alignCenters
        messageLable.numberOfLines = 2
        view.addSubview(messageLable)
        messageLable.setContentHuggingPriority(.required, for: .vertical)
        messageLable.topAnchor.constraint(equalTo: titleLable.bottomAnchor, constant: .padding).isActive = true
        messageLable.leadingAnchor.constraint(greaterThanOrEqualTo: view.layoutMarginsGuide.leadingAnchor).isActive = true
        messageLable.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -.extendedPadding).isActive = true
        messageLable.trailingAnchor.constraint(lessThanOrEqualTo: view.layoutMarginsGuide.trailingAnchor).isActive = true
        messageLable.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor).isActive = true
    }
}
