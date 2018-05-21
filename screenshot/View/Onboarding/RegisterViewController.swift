//
//  RegisterViewController.swift
//  screenshot
//
//  Created by Corey Werner on 5/21/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import FacebookCore
import FacebookLogin
import Appsee

class RegisterView: UIView {
    let facebookLoginButton = FacebookButton()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        
        let backgroundImageView = UIImageView(image: UIImage(named: "BrandConfettiFullBackground"))
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        backgroundImageView.contentMode = .scaleAspectFill
        addSubview(backgroundImageView)
        backgroundImageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        backgroundImageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        backgroundImageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        backgroundImageView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        facebookLoginButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(facebookLoginButton)
        facebookLoginButton.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        facebookLoginButton.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        facebookLoginButton.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        let horizontalLinesView = HorizontalLinesView()
        horizontalLinesView.translatesAutoresizingMaskIntoConstraints = false
        horizontalLinesView.label.text = "or"
        horizontalLinesView.leftLine.backgroundColor = .gray6
        horizontalLinesView.rightLine.backgroundColor = .gray6
        addSubview(horizontalLinesView)
        horizontalLinesView.topAnchor.constraint(equalTo: facebookLoginButton.bottomAnchor, constant: .padding).isActive = true
        horizontalLinesView.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor).isActive = true
        horizontalLinesView.widthAnchor.constraint(equalToConstant: 170).isActive = true
        
        let contentView = ContentContainerView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentView.topAnchor.constraint(equalTo: horizontalLinesView.bottomAnchor, constant: .padding).isActive = true
        contentView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        let emailTextField = UnderlineTextField()
        emailTextField.translatesAutoresizingMaskIntoConstraints = false
        emailTextField.placeholder = "Email Address"
        contentView.addSubview(emailTextField)
        emailTextField.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
        emailTextField.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        emailTextField.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        let passwordTextField = UnderlineTextField()
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        passwordTextField.placeholder = "Password"
        passwordTextField.isSecureTextEntry = true
        contentView.addSubview(passwordTextField)
        passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: .padding).isActive = true
        passwordTextField.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        passwordTextField.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        Appsee.markView(asSensitive: passwordTextField)
        
        let continueButton = MainButton()
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.setTitle("Sign Up", for: .normal)
        contentView.addSubview(continueButton)
        continueButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: .padding * 2).isActive = true
        continueButton.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        continueButton.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor, constant: -.padding).isActive = true
        continueButton.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layoutMargins = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
    }
}

class RegisterViewController: UIViewController {
    
    // MARK: View
    
    fileprivate var _view: RegisterView {
        return view as! RegisterView
    }
    
    override func loadView() {
        view = RegisterView()
    }
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _view.facebookLoginButton.addTarget(self, action: #selector(facebookLoginAction), for: .touchUpInside)
    }
    
    // MARK: Facebook
    
    @objc func facebookLoginAction() {
        // TODO: use AccessToken to see if user already logged in
//        AccessToken.current
        
        let loginManager = LoginManager()
        
        loginManager.logIn(readPermissions: [.publicProfile, .email], viewController: self) { loginResult in
            switch loginResult {
            case .failed(let error):
                print(error)
                
            case .cancelled:
                print("User cancelled login.")
                
            case .success(let grantedPermissions, let declinedPermissions, let accessToken):
                print("Logged in!")
            }
        }
    }
}
