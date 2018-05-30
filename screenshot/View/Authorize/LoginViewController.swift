//
//  LoginViewController.swift
//  screenshot
//
//  Created by Corey Werner on 5/24/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class LoginView: AuthorizeContentScrollView {
    let forgotPasswordButton = UIButton()
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let color: UIColor = .crazeRed
        
        // TODO: underline
        forgotPasswordButton.translatesAutoresizingMaskIntoConstraints = false
        forgotPasswordButton.setTitle("onboarding.login.forgot".localized, for: .normal)
        forgotPasswordButton.setTitleColor(color, for: .normal)
        forgotPasswordButton.setTitleColor(color.darker(), for: .highlighted)
        forgotPasswordButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: .padding, bottom: 6, right: .padding)
        contentView.addSubview(forgotPasswordButton)
        forgotPasswordButton.topAnchor.constraint(equalTo: continueButton.bottomAnchor, constant: .padding).isActive = true
        forgotPasswordButton.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        forgotPasswordButton.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor, constant: verticalNegativeMargin).isActive = true
        forgotPasswordButton.trailingAnchor.constraint(lessThanOrEqualTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        forgotPasswordButton.centerXAnchor.constraint(equalTo: contentView.layoutMarginsGuide.centerXAnchor).isActive = true
    }
}

class LoginViewController: AuthorizeContentViewController {
    override var classForView: AuthorizeContentScrollView.Type {
        return LoginView.self
    }
    
    override var _view: LoginView {
        return view as! LoginView
    }
    
    var continueButton: UIButton {
        return _view.continueButton
    }
    
    var forgotPasswordButton: UIButton {
        return _view.forgotPasswordButton
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let email = UserDefaults.standard.string(forKey: UserDefaultsKeys.email) {
            _view.emailTextField.text = email
        }
        
        _view.facebookLoginButton.textCopy = .login
        _view.continueButton.setTitle("onboarding.login.continue".localized, for: .normal)
    }
}
