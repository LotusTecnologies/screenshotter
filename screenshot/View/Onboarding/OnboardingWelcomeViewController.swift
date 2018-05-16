//
//  OnboardingWelcomeViewController.swift
//  screenshot
//
//  Created by Corey Werner on 5/15/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class OnboardingWelcomeView: BlankHeaderConfettiContentTemplate {
    let continueButton = MainButton()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let iconImageView = UIImageView(image: UIImage(named: "BrandIcon110"))
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        addSubview(iconImageView)
        iconImageView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.3).isActive = true
        iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        iconImageView.centerYAnchor.constraint(equalTo: headerLayoutGuide.bottomAnchor).isActive = true
        
        let headerVerticalContainerLayoutGuide = UILayoutGuide()
        addLayoutGuide(headerVerticalContainerLayoutGuide)
        headerVerticalContainerLayoutGuide.topAnchor.constraint(equalTo: headerLayoutGuide.topAnchor).isActive = true
        headerVerticalContainerLayoutGuide.bottomAnchor.constraint(equalTo: iconImageView.topAnchor).isActive = true
        
        let headerVerticalLayoutGuide = UILayoutGuide()
        addLayoutGuide(headerVerticalLayoutGuide)
        headerVerticalLayoutGuide.topAnchor.constraint(greaterThanOrEqualTo: headerVerticalContainerLayoutGuide.topAnchor).isActive = true
        headerVerticalLayoutGuide.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        headerVerticalLayoutGuide.bottomAnchor.constraint(lessThanOrEqualTo: headerVerticalContainerLayoutGuide.bottomAnchor).isActive = true
        headerVerticalLayoutGuide.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        headerVerticalLayoutGuide.centerYAnchor.constraint(equalTo: headerVerticalContainerLayoutGuide.centerYAnchor).isActive = true
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "onboarding.welcome.header".localized
        titleLabel.textColor = .gray3
        titleLabel.textAlignment = .center
        titleLabel.font = .screenshopFont(.hindLight, size: 17)
        addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: headerVerticalLayoutGuide.topAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.leadingAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor).isActive = true
        titleLabel.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor).isActive = true
        
        let logoImageView = UIImageView(image: UIImage(named: "BrandLogo31h"))
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.contentMode = .scaleAspectFit
        addSubview(logoImageView)
        logoImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4).isActive = true
        logoImageView.bottomAnchor.constraint(equalTo: headerVerticalLayoutGuide.bottomAnchor).isActive = true
        logoImageView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.6).isActive = true
        logoImageView.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor).isActive = true
        
        let topContentLayoutGuide = UILayoutGuide()
        addLayoutGuide(topContentLayoutGuide)
        topContentLayoutGuide.topAnchor.constraint(equalTo: iconImageView.bottomAnchor).isActive = true
        
        let contentLabel = UILabel()
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.text = "onboarding.welcome.content".localized
        contentLabel.textColor = .gray2
        contentLabel.textAlignment = .center
        contentLabel.font = .screenshopFont(.hindLight, textStyle: .title1)
        contentLabel.adjustsFontForContentSizeCategory = true
        contentLabel.numberOfLines = 2
        contentLabel.minimumScaleFactor = 0.1
        contentLabel.adjustsFontSizeToFitWidth = true
        addSubview(contentLabel)
        contentLabel.topAnchor.constraint(equalTo: topContentLayoutGuide.bottomAnchor).isActive = true
        contentLabel.leadingAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.leadingAnchor).isActive = true
        contentLabel.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor).isActive = true
        contentLabel.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor).isActive = true
        
        let middleContentLayoutGuide = UILayoutGuide()
        addLayoutGuide(middleContentLayoutGuide)
        middleContentLayoutGuide.topAnchor.constraint(equalTo: contentLabel.bottomAnchor).isActive = true
        middleContentLayoutGuide.heightAnchor.constraint(equalTo: topContentLayoutGuide.heightAnchor).isActive = true
        
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.backgroundColor = .crazeGreen
        continueButton.setTitle("onboarding.welcome.continue".localized, for: .normal)
        addSubview(continueButton)
        continueButton.topAnchor.constraint(equalTo: middleContentLayoutGuide.bottomAnchor).isActive = true
        continueButton.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor).isActive = true
        
        let bottomContentLayoutGuide = UILayoutGuide()
        addLayoutGuide(bottomContentLayoutGuide)
        bottomContentLayoutGuide.topAnchor.constraint(equalTo: continueButton.bottomAnchor).isActive = true
        bottomContentLayoutGuide.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
        bottomContentLayoutGuide.heightAnchor.constraint(equalTo: topContentLayoutGuide.heightAnchor, multiplier: 1.8).isActive = true
    }
}

protocol OnboardingWelcomeViewControllerDelegate: NSObjectProtocol {
    func onboardingWelcomeViewControllerDidComplete(_ viewController: OnboardingWelcomeViewController)
}

class OnboardingWelcomeViewController: UIViewController {
    weak var delegate: OnboardingWelcomeViewControllerDelegate?
    
    fileprivate var _view: OnboardingWelcomeView {
        return view as! OnboardingWelcomeView
    }
    
    override func loadView() {
        view = OnboardingWelcomeView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _view.continueButton.addTarget(self, action: #selector(continueAction), for: .touchUpInside)
    }
    
    @objc fileprivate func continueAction() {
        delegate?.onboardingWelcomeViewControllerDidComplete(self)
    }
}
