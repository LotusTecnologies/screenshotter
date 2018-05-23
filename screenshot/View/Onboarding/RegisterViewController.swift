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

class RegisterView: UIScrollView {
    let facebookLoginButton = FacebookButton()
    private let horizontalLinesView = HorizontalLinesView()
    let emailTextField = UnderlineTextField()
    let passwordTextField = UnderlineTextField()
    let dealsSwitch = UISwitch()
    let continueButton = MainButton()
    let skipButton = UIButton()
    let legalTextView = TappableTextView()
    
    fileprivate var activeTextFieldTopOffset: CGFloat {
        return horizontalLinesView.frame.maxY
    }
    
    private let _layoutMargins = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        if let backgroundImage = UIImage(named: "BrandConfettiFullBackground") {
            backgroundColor = UIColor(patternImage: backgroundImage)
        }
        
        // Force the height to be at least that of the scroll view
        let verticalLayoutView = UIView()
        verticalLayoutView.translatesAutoresizingMaskIntoConstraints = false
        verticalLayoutView.isHidden = true
        addSubview(verticalLayoutView)
        verticalLayoutView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        verticalLayoutView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        verticalLayoutView.heightAnchor.constraint(greaterThanOrEqualTo: heightAnchor).isActive = true
        
        facebookLoginButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(facebookLoginButton)
        facebookLoginButton.topAnchor.constraint(equalTo: topAnchor, constant: _layoutMargins.top).isActive = true
        facebookLoginButton.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        facebookLoginButton.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        let vertical1LayoutGuide = UILayoutGuide()
        addLayoutGuide(vertical1LayoutGuide)
        vertical1LayoutGuide.topAnchor.constraint(equalTo: facebookLoginButton.bottomAnchor, constant: .padding).isActive = true
        
        horizontalLinesView.translatesAutoresizingMaskIntoConstraints = false
        horizontalLinesView.label.text = "or"
        horizontalLinesView.leftLine.backgroundColor = .gray6
        horizontalLinesView.rightLine.backgroundColor = .gray6
        addSubview(horizontalLinesView)
        horizontalLinesView.topAnchor.constraint(greaterThanOrEqualTo: vertical1LayoutGuide.topAnchor).isActive = true
        horizontalLinesView.bottomAnchor.constraint(lessThanOrEqualTo: vertical1LayoutGuide.bottomAnchor).isActive = true
        horizontalLinesView.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor).isActive = true
        horizontalLinesView.centerYAnchor.constraint(equalTo: vertical1LayoutGuide.centerYAnchor).isActive = true
        horizontalLinesView.widthAnchor.constraint(equalToConstant: 170).isActive = true
        
        let contentView = ContentContainerView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentView.topAnchor.constraint(equalTo: vertical1LayoutGuide.bottomAnchor, constant: .padding).isActive = true
        contentView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
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
        continueButton.setTitle("Sign Up", for: .normal)
        contentView.addSubview(continueButton)
        continueButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: contentView.layoutMargins.bottom).isActive = true
        continueButton.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        continueButton.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
        continueButton.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        let vertical2LayoutGuide = UILayoutGuide()
        addLayoutGuide(vertical2LayoutGuide)
        vertical2LayoutGuide.topAnchor.constraint(equalTo: contentView.bottomAnchor, constant: .padding).isActive = true
        vertical2LayoutGuide.heightAnchor.constraint(equalTo: vertical1LayoutGuide.heightAnchor).isActive = true
        
        let skipImage = UIImage(named: "OnboardingArrow")
        
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        skipButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: .padding, bottom: 6, right: .padding)
        skipButton.setTitle("Skip", for: .normal)
        skipButton.setTitleColor(.gray3, for: .normal)
        skipButton.setTitleColor(.gray5, for: .highlighted)
        skipButton.setImage(skipImage, for: .normal)
        skipButton.setImage(skipImage?.withRenderingMode(.alwaysTemplate), for: .highlighted)
        skipButton.tintColor = skipButton.titleColor(for: .highlighted)
        skipButton.alignImageRight()
        skipButton.adjustInsetsForImage(withPadding: 6)
        addSubview(skipButton)
        skipButton.topAnchor.constraint(greaterThanOrEqualTo: vertical2LayoutGuide.topAnchor).isActive = true
        skipButton.bottomAnchor.constraint(lessThanOrEqualTo: vertical2LayoutGuide.bottomAnchor).isActive = true
        skipButton.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor).isActive = true
        skipButton.centerYAnchor.constraint(equalTo: vertical2LayoutGuide.centerYAnchor).isActive = true
        
        let dealsLayoutGuide = UILayoutGuide()
        addLayoutGuide(dealsLayoutGuide)
        dealsLayoutGuide.centerXAnchor.constraint(equalTo: contentView.layoutMarginsGuide.centerXAnchor).isActive = true
        dealsLayoutGuide.widthAnchor.constraint(lessThanOrEqualToConstant: 320 - (.padding * 2)).isActive = true
        
        let dealsLabel = UILabel()
        dealsLabel.translatesAutoresizingMaskIntoConstraints = false
        dealsLabel.text = "Send me emails about exclusive offers, sales and new features."
        dealsLabel.textColor = .gray3
        dealsLabel.numberOfLines = 0
        dealsLabel.font = .screenshopFont(.hindLight, size: 16)
        addSubview(dealsLabel)
        dealsLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        dealsLabel.topAnchor.constraint(equalTo: vertical2LayoutGuide.bottomAnchor, constant: .padding).isActive = true
        dealsLabel.leadingAnchor.constraint(equalTo: dealsLayoutGuide.leadingAnchor).isActive = true
        
        dealsSwitch.translatesAutoresizingMaskIntoConstraints = false
        dealsSwitch.isOn = true
        dealsSwitch.onTintColor = .crazeGreen
        addSubview(dealsSwitch)
        dealsSwitch.leadingAnchor.constraint(equalTo: dealsLabel.trailingAnchor, constant: .padding).isActive = true
        dealsSwitch.trailingAnchor.constraint(equalTo: dealsLayoutGuide.trailingAnchor).isActive = true
        dealsSwitch.centerYAnchor.constraint(equalTo: dealsLabel.centerYAnchor).isActive = true
        
        legalTextView.translatesAutoresizingMaskIntoConstraints = false
        legalTextView.backgroundColor = .clear
        legalTextView.adjustsFontForContentSizeCategory = true
        legalTextView.isEditable = false
        legalTextView.isScrollEnabled = false
        legalTextView.scrollsToTop = false
        legalTextView.linkTextAttributes = [
            NSAttributedStringKey.foregroundColor.rawValue: UIColor.crazeGreen,
            NSAttributedStringKey.underlineStyle.rawValue: NSUnderlineStyle.styleSingle.rawValue,
            NSAttributedStringKey.underlineColor.rawValue: UIColor.crazeGreen
        ]
        legalTextView.attributedText = legalAttributedText()
        addSubview(legalTextView)
        legalTextView.setContentCompressionResistancePriority(.required, for: .vertical)
        legalTextView.topAnchor.constraint(equalTo: dealsLabel.lastBaselineAnchor, constant: .padding).isActive = true
        legalTextView.leadingAnchor.constraint(equalTo: dealsLayoutGuide.leadingAnchor).isActive = true
        legalTextView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -_layoutMargins.bottom).isActive = true
        legalTextView.trailingAnchor.constraint(equalTo: dealsLayoutGuide.trailingAnchor).isActive = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layoutMargins = _layoutMargins
    }
    
    // MARK: Legal
    
    fileprivate let legalLinkTOS = "TOS"
    fileprivate let legalLinkPP = "PP"
    
    private func legalAttributedText() -> NSAttributedString {
        let textViewFont: UIFont = .screenshopFont(.hindLight, size: 14)
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        
        func attributes(_ link: String? = nil) -> [NSAttributedStringKey : Any] {
            var attributes: [NSAttributedStringKey : Any] = [
                .font: textViewFont,
                .paragraphStyle: paragraph,
                .foregroundColor: UIColor.gray6
            ]
            
            if let link = link {
                attributes[.link] = link
            }
            
            return attributes
        }
        
        // TODO: localized copy needs to say 'Sign up' not 'Submit'
        return NSMutableAttributedString(segmentedString: "tutorial.email.legal", attributes: [
            attributes(),
            attributes(legalLinkTOS),
            attributes(),
            attributes(legalLinkPP),
            attributes()
            ])
    }
}

class RegisterViewController: UIViewController {
    
    // MARK: View
    
    private let _view = RegisterView()
    
    var skipButton: UIButton {
        return _view.skipButton
    }
    
    override func loadView() {
        view = _view
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
        
        _view.facebookLoginButton.addTarget(self, action: #selector(facebookLoginAction), for: .touchUpInside)
        _view.emailTextField.delegate = self
        _view.passwordTextField.delegate = self
        _view.legalTextView.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        _view.addGestureRecognizer(tapGesture)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Facebook
    
    @objc func facebookLoginAction() {
        // TODO: use AccessToken to see if user already logged in
//        AccessToken.current
        
        let loginManager = LoginManager()
        UIFont.preferredFont(forTextStyle: .title1)
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

extension RegisterViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.returnKeyType == .done {
            textField.resignFirstResponder()
        }
        return true
    }
}

extension RegisterViewController: UITextViewDelegate {
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        switch URL.absoluteString {
        case _view.legalLinkTOS:
            presentTermsOfService()
        case _view.legalLinkPP:
            presentPrivacyPolicy()
        default:
            break
        }
        return false
    }
    
    fileprivate func presentTermsOfService() {
        Analytics.trackOnboardingSubmittedEmailTOS()
        
        if let viewController = LegalViewControllerFactory.termsOfServiceViewController() {
            present(viewController, animated: true, completion: nil)
        }
    }
    
    fileprivate func presentPrivacyPolicy() {
        Analytics.trackOnboardingSubmittedEmailPrivacy()
        
        if let viewController = LegalViewControllerFactory.privacyPolicyViewController() {
            present(viewController, animated: true, completion: nil)
        }
    }
}
