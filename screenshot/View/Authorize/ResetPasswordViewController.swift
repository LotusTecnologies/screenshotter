//
//  ResetPasswordViewController.swift
//  screenshot
//
//  Created by Corey Werner on 5/30/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

protocol ResetPasswordViewControllerDelegate: NSObjectProtocol {
    func resetPasswordViewControllerDidReset(_ viewController: ResetPasswordViewController)
}

class ResetPasswordView: UIScrollView {
    let continueButton = MainButton()
    let backButton = UIButton()
    
    let _layoutMargins = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        if let backgroundImage = UIImage(named: "BrandConfettiFullBackground") {
            backgroundColor = UIColor(patternImage: backgroundImage)
        }
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "authorize.reset_password.title".localized
        titleLabel.textColor = .gray3
        titleLabel.font = .screenshopFont(.hindSemibold, textStyle: .title1, staticSize: true)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.7
        addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: .extendedPadding).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        let contentView = ContentContainerView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: .padding).isActive = true
        contentView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        let emailImageView = UIImageView(image: UIImage(named: ""))
        emailImageView.translatesAutoresizingMaskIntoConstraints = false
        emailImageView.contentMode = .scaleAspectFit
        contentView.addSubview(emailImageView)
        emailImageView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
        emailImageView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        
        let messageLabel = UILabel()
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.text = "Enter the email you signed up with and we'll send you a link to reset your password"
        messageLabel.textColor = .gray2
        messageLabel.font = .screenshopFont(.hindLight, textStyle: .body, staticSize: true)
        messageLabel.numberOfLines = 0
        contentView.addSubview(messageLabel)
        messageLabel.topAnchor.constraint(equalTo: emailImageView.bottomAnchor, constant: .padding).isActive = true
        messageLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        messageLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        let emailTextField = UnderlineTextField()
        emailTextField.translatesAutoresizingMaskIntoConstraints = false
        emailTextField.placeholder = "Your Email"
        emailTextField.textColor = .gray2
        contentView.addSubview(emailTextField)
        emailTextField.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: .extendedPadding).isActive = true
        emailTextField.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        emailTextField.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.setTitle("generic.send".localized, for: .normal)
        contentView.addSubview(continueButton)
        continueButton.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: .extendedPadding).isActive = true
        continueButton.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        continueButton.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
        continueButton.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        let skipLayoutGuide = UILayoutGuide()
        addLayoutGuide(skipLayoutGuide)
        skipLayoutGuide.topAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        
        let skipImage = UIImage(named: "OnboardingArrow")?.withHorizontallyFlippedOrientation()
        
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: .padding, bottom: 6, right: .padding)
        backButton.setTitle("generic.back".localized, for: .normal)
        backButton.setTitleColor(.gray3, for: .normal)
        backButton.setTitleColor(.gray5, for: .highlighted)
        backButton.setImage(skipImage, for: .normal)
        backButton.setImage(skipImage?.withRenderingMode(.alwaysTemplate), for: .highlighted)
        backButton.tintColor = backButton.titleColor(for: .highlighted)
        backButton.adjustInsetsForImage(withPadding: 6)
        addSubview(backButton)
        backButton.topAnchor.constraint(equalTo: skipLayoutGuide.bottomAnchor, constant: .padding).isActive = true
        backButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -_layoutMargins.bottom).isActive = true
        backButton.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor).isActive = true
    }
}

class ResetPasswordViewController: UIViewController {
    weak var delegate: ResetPasswordViewController?
    
    private let inputViewAdjustsScrollViewController = InputViewAdjustsScrollViewController()
    
    // MARK: View
    
    var classForView: ResetPasswordView.Type {
        return ResetPasswordView.self
    }
    
    var _view: ResetPasswordView {
        return view as! ResetPasswordView
    }
    
    override func loadView() {
        view = classForView.self.init()
    }
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        inputViewAdjustsScrollViewController.scrollView = _view
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        _view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: Keyboard
    
    @objc fileprivate func dismissKeyboard() {
        view.endEditing(true)
    }
}
