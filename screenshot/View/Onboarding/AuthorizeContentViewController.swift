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
        horizontalLinesView.label.text = "or"
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
        
        let textFieldTopMargin: CGFloat = contentView.layoutMargins.top * 0.4
        
        emailTextField.translatesAutoresizingMaskIntoConstraints = false
        emailTextField.placeholder = "Email Address"
        emailTextField.returnKeyType = .next
        emailTextField.keyboardType = .emailAddress
        emailTextField.autocapitalizationType = .none
        emailTextField.autocorrectionType = .no
        emailTextField.spellCheckingType = .no
        contentView.addSubview(emailTextField)
        emailTextField.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor, constant: textFieldTopMargin - contentView.layoutMargins.top).isActive = true
        emailTextField.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        emailTextField.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        passwordTextField.placeholder = "Password"
        passwordTextField.isSecureTextEntry = true
        passwordTextField.returnKeyType = .done
        passwordTextField.autocapitalizationType = .none
        passwordTextField.autocorrectionType = .no
        passwordTextField.spellCheckingType = .no
        contentView.addSubview(passwordTextField)
        passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: textFieldTopMargin).isActive = true
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
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShowNotification(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHideNotification(_:)), name: .UIKeyboardWillHide, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _view.emailTextField.delegate = self
        _view.passwordTextField.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        _view.addGestureRecognizer(tapGesture)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Keyboard
    
    @objc private func keyboardWillShowNotification(_ notification: Notification) {
        var contentInset = _view.contentInset
        var scrollIndicatorInsets = _view.scrollIndicatorInsets
        
        contentInset.top = -_view.activeTextFieldTopOffset
        
        if let keyboardRect = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            contentInset.bottom = keyboardRect.height
            scrollIndicatorInsets.bottom = keyboardRect.height
        }
        
        _view.contentInset = contentInset
        _view.scrollIndicatorInsets = scrollIndicatorInsets
    }
    
    @objc private func keyboardWillHideNotification(_ notification: Notification) {
        var contentInset = _view.contentInset
        contentInset.top = 0
        contentInset.bottom = 0
        _view.contentInset = contentInset
        
        var scrollIndicatorInsets = _view.scrollIndicatorInsets
        scrollIndicatorInsets.bottom = 0
        _view.scrollIndicatorInsets = scrollIndicatorInsets
    }
    
    @objc fileprivate func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension AuthorizeContentViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.returnKeyType == .done {
            textField.resignFirstResponder()
        }
        return true
    }
}

