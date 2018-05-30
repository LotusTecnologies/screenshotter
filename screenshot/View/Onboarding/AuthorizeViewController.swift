//
//  AuthorizeViewController.swift
//  screenshot
//
//  Created by Corey Werner on 5/22/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import FacebookCore
import FacebookLogin

protocol AuthorizeViewControllerDelegate: NSObjectProtocol {
    func authorizeViewControllerDidSkip(_ viewController: AuthorizeViewController)
    func authorizeViewControllerDidLogin(_ viewController: AuthorizeViewController)
    func authorizeViewControllerDidSignup(_ viewController: AuthorizeViewController)
    func authorizeViewControllerDidFacebookLogin(_ viewController: AuthorizeViewController)
    func authorizeViewControllerDidFacebookSignup(_ viewController: AuthorizeViewController)
}

class AuthorizeView: UIView {
    let registerButton = UIButton()
    let loginButton = UIButton()
    let contentView = UIView()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = .red
        addSubview(headerView)
        headerView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        headerView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        headerView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        headerView.heightAnchor.constraint(equalToConstant: 70).isActive = true
        
        registerButton.translatesAutoresizingMaskIntoConstraints = false
        registerButton.setTitle("Sign Up", for: .normal)
        registerButton.backgroundColor = UIColor.cyan.withAlphaComponent(0.3)
        headerView.addSubview(registerButton)
        registerButton.leadingAnchor.constraint(equalTo: headerView.layoutMarginsGuide.leadingAnchor).isActive = true
        registerButton.bottomAnchor.constraint(equalTo: headerView.layoutMarginsGuide.bottomAnchor).isActive = true
        registerButton.trailingAnchor.constraint(equalTo: headerView.layoutMarginsGuide.centerXAnchor).isActive = true
        
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.setTitle("Log In", for: .normal)
        loginButton.backgroundColor = UIColor.yellow.withAlphaComponent(0.3)
        headerView.addSubview(loginButton)
        loginButton.leadingAnchor.constraint(equalTo: headerView.layoutMarginsGuide.centerXAnchor).isActive = true
        loginButton.bottomAnchor.constraint(equalTo: headerView.layoutMarginsGuide.bottomAnchor).isActive = true
        loginButton.trailingAnchor.constraint(equalTo: headerView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .gray9
        addSubview(contentView)
        contentView.topAnchor.constraint(equalTo: headerView.bottomAnchor).isActive = true
        contentView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }
}

class AuthorizeViewController: UIViewController {
    fileprivate let registerViewController = RegisterViewController()
    fileprivate let loginViewController = LoginViewController()
    
    weak var delegate: AuthorizeViewControllerDelegate?
    
    // MARK: View
    
    private let _view = AuthorizeView()
    
    override func loadView() {
        view = _view
    }
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _view.registerButton.addTarget(self, action: #selector(displayRegisterTab), for: .touchUpInside)
        _view.loginButton.addTarget(self, action: #selector(displayLoginTab), for: .touchUpInside)
        
        registerViewController.facebookLoginButton.addTarget(self, action: #selector(facebookLoginAction), for: .touchUpInside)
        registerViewController.continueButton.addTarget(self, action: #selector(registerAction), for: .touchUpInside)
        registerViewController.skipButton.addTarget(self, action: #selector(skipRegistration), for: .touchUpInside)
        
        loginViewController.facebookLoginButton.addTarget(self, action: #selector(facebookLoginAction), for: .touchUpInside)
        loginViewController.continueButton.addTarget(self, action: #selector(loginAction), for: .touchUpInside)
        loginViewController.forgotPasswordButton.addTarget(self, action: #selector(forgotPasswordAction), for: .touchUpInside)
        
        if UserDefaults.standard.string(forKey: UserDefaultsKeys.email) != nil {
            displayLoginTab()
        }
        else {
            displayRegisterTab()
        }
    }
    
    // MARK: Containment
    
    private func addContentController(_ childViewController: UIViewController) {
        addChildViewController(childViewController)
        _view.contentView.addSubview(childViewController.view)
        childViewController.didMove(toParentViewController: self)
        
        childViewController.view.clipsToBounds = true
        childViewController.view.translatesAutoresizingMaskIntoConstraints = false
        childViewController.view.topAnchor.constraint(equalTo: _view.contentView.topAnchor).isActive = true
        childViewController.view.leadingAnchor.constraint(equalTo: _view.contentView.leadingAnchor).isActive = true
        childViewController.view.bottomAnchor.constraint(equalTo: _view.contentView.bottomAnchor).isActive = true
        childViewController.view.trailingAnchor.constraint(equalTo: _view.contentView.trailingAnchor).isActive = true
    }
    
    private func removeContentController(_ childViewController: UIViewController) {
        childViewController.willMove(toParentViewController: nil)
        childViewController.view.removeFromSuperview()
        childViewController.removeFromParentViewController()
    }
    
    // MARK: Registration
    
    @objc fileprivate func displayRegisterTab() {
        guard !_view.registerButton.isSelected else {
            return
        }
        
        _view.registerButton.isSelected = true
        _view.loginButton.isSelected = false
        
        if !_view.contentView.subviews.isEmpty {
            removeContentController(loginViewController)
        }
        
        addContentController(registerViewController)
    }
    
    @objc fileprivate func registerAction() {
        let isValidRegistration = true
        
        if isValidRegistration {
            delegate?.authorizeViewControllerDidSignup(self)
        }
        else {
            // TODO: notify user there was an issue
        }
    }
    
    @objc fileprivate func skipRegistration() {
        delegate?.authorizeViewControllerDidSkip(self)
    }
    
    // MARK: Login
    
    @objc fileprivate func displayLoginTab() {
        guard !_view.loginButton.isSelected else {
            return
        }
        
        _view.registerButton.isSelected = false
        _view.loginButton.isSelected = true
        
        if !_view.contentView.subviews.isEmpty {
            removeContentController(registerViewController)
        }
        
        addContentController(loginViewController)
    }
    
    @objc fileprivate func loginAction() {
        let isValidLogin = true
        
        if isValidLogin {
            delegate?.authorizeViewControllerDidLogin(self)
        }
        else {
            // TODO: notify user there was an issue
        }
    }
    
    @objc private func forgotPasswordAction() {
        // TODO: present reset password page. this vc should prob be pushed up to the tutorial nav controller
        
        let resetPasswordViewController = UIViewController()
        navigationController?.pushViewController(resetPasswordViewController, animated: true)
    }
    
    // MARK: Facebook
    
    @objc fileprivate func facebookLoginAction() {
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
                // TODO: set up user
                
                let isExistingUser = false
                
                if isExistingUser {
                    self.delegate?.authorizeViewControllerDidFacebookLogin(self)
                }
                else {
                    self.delegate?.authorizeViewControllerDidFacebookSignup(self)
                }
            }
        }
    }
}
