//
//  AuthorizeContentViewController.swift
//  screenshot
//
//  Created by Corey Werner on 5/24/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import Appsee

class AuthorizeContentScrollView: UIScrollView {
    let facebookLoginButton = FacebookButton()
    private let horizontalLinesView = HorizontalLinesView()
    let contentView = ContentContainerView()
    let emailTextField = UnderlineTextField()
    let passwordTextField = UnderlineTextField()
    let continueButton = MainButton()
    
    var activeTextFieldTopOffset: CGFloat {
        return horizontalLinesView.frame.maxY
    }
    
    var verticalNegativeMargin: CGFloat {
        return contentView.layoutMargins.top * 0.4
    }
    
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
        
        facebookLoginButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(facebookLoginButton)
        facebookLoginButton.topAnchor.constraint(equalTo: topAnchor, constant: _layoutMargins.top).isActive = true
        facebookLoginButton.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        facebookLoginButton.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        horizontalLinesView.translatesAutoresizingMaskIntoConstraints = false
        horizontalLinesView.label.text = "generic.or".localized
        horizontalLinesView.leftLine.backgroundColor = .gray6
        horizontalLinesView.rightLine.backgroundColor = .gray6
        addSubview(horizontalLinesView)
        horizontalLinesView.topAnchor.constraint(equalTo: facebookLoginButton.bottomAnchor, constant: .padding).isActive = true
        horizontalLinesView.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor).isActive = true
        horizontalLinesView.widthAnchor.constraint(equalToConstant: 170).isActive = true
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentView.topAnchor.constraint(equalTo: horizontalLinesView.bottomAnchor, constant: .padding).isActive = true
        contentView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        contentView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -_layoutMargins.bottom).isActive = true
        contentView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        emailTextField.translatesAutoresizingMaskIntoConstraints = false
        emailTextField.placeholder = "authorize.generic.email".localized
        emailTextField.returnKeyType = .next
        emailTextField.keyboardType = .emailAddress
        emailTextField.autocapitalizationType = .none
        emailTextField.autocorrectionType = .no
        emailTextField.spellCheckingType = .no
        contentView.addSubview(emailTextField)
        emailTextField.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor, constant: verticalNegativeMargin - contentView.layoutMargins.top).isActive = true
        emailTextField.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        emailTextField.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        passwordTextField.placeholder = "authorize.generic.password".localized
        passwordTextField.isSecureTextEntry = true
        passwordTextField.autocapitalizationType = .none
        passwordTextField.autocorrectionType = .no
        passwordTextField.spellCheckingType = .no
        contentView.addSubview(passwordTextField)
        passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: verticalNegativeMargin).isActive = true
        passwordTextField.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        passwordTextField.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        Appsee.markView(asSensitive: passwordTextField)
        
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(continueButton)
        continueButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: contentView.layoutMargins.bottom).isActive = true
        continueButton.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        continueButton.bottomAnchor.constraint(lessThanOrEqualTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
        continueButton.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layoutMargins = _layoutMargins
    }
}

class AuthorizeContentViewController: UIViewController {
    private let inputViewAdjustsScrollViewController = InputViewAdjustsScrollViewController()
    
    // MARK: View
    
    var classForView: AuthorizeContentScrollView.Type {
        return AuthorizeContentScrollView.self
    }
    
    var _view: AuthorizeContentScrollView {
        return view as! AuthorizeContentScrollView
    }
    
    var facebookLoginButton: FacebookButton {
        return _view.facebookLoginButton
    }
    
    override func loadView() {
        view = classForView.self.init()
    }
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        inputViewAdjustsScrollViewController.scrollView = _view
        inputViewAdjustsScrollViewController.delegate = self
        
        _view.emailTextField.delegate = self
        _view.passwordTextField.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        _view.addGestureRecognizer(tapGesture)
    }
    
    deinit {
        inputViewAdjustsScrollViewController.delegate = nil
        _view.emailTextField.delegate = nil
        _view.passwordTextField.delegate = nil
    }
    
    // MARK: Keyboard
    
    @objc fileprivate func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension AuthorizeContentViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == _view.emailTextField {
            _view.passwordTextField.becomeFirstResponder()
        }
        else if textField == _view.passwordTextField {
            textField.resignFirstResponder()
        }
        return true
    }
}

extension AuthorizeContentViewController: InputViewAdjustsScrollViewControllerDelegate {
    func inputViewAdjustsScrollViewControllerWillShow(_ controller: InputViewAdjustsScrollViewController) {
        var contentInset = _view.contentInset
        contentInset.top = -_view.activeTextFieldTopOffset
        _view.contentInset = contentInset
    }
    
    func inputViewAdjustsScrollViewControllerWillHide(_ controller: InputViewAdjustsScrollViewController) {
        var contentInset = _view.contentInset
        contentInset.top = 0
        _view.contentInset = contentInset
    }
}
