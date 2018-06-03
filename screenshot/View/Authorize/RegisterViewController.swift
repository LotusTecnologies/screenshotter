//
//  RegisterViewController.swift
//  screenshot
//
//  Created by Corey Werner on 5/21/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import Appsee
import FacebookCore
import FacebookLogin

protocol RegisterViewControllerDelegate: NSObjectProtocol {
    func registerViewControllerDidSkip(_ viewController: RegisterViewController)
    func registerViewControllerDidLogin(_ viewController: RegisterViewController)
    func registerViewControllerDidSignup(_ viewController: RegisterViewController)
    func registerViewControllerDidFacebookLogin(_ viewController: RegisterViewController)
    func registerViewControllerDidFacebookSignup(_ viewController: RegisterViewController)
}

class RegisterView: UIScrollView {
    let facebookLoginButton = FacebookButton()
    private let horizontalLinesView = HorizontalLinesView()
    let contentView = ContentContainerView()
    let emailTextField = UnderlineTextField()
    let passwordTextField = UnderlineTextField()
    let continueButton = MainButton()
    let dealsSwitch = UISwitch()
    let skipButton = UIButton()
    let legalTextView = TappableTextView()
    
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
        
        let skipLayoutGuide = UILayoutGuide()
        addLayoutGuide(skipLayoutGuide)
        skipLayoutGuide.topAnchor.constraint(equalTo: contentView.bottomAnchor, constant: .padding).isActive = true
        
        let skipImage = UIImage(named: "OnboardingArrow")
        
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        skipButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: .padding, bottom: 6, right: .padding)
        skipButton.setTitle("generic.skip".localized, for: .normal)
        skipButton.setTitleColor(.gray3, for: .normal)
        skipButton.setTitleColor(.gray5, for: .highlighted)
        skipButton.setImage(skipImage, for: .normal)
        skipButton.setImage(skipImage?.withRenderingMode(.alwaysTemplate), for: .highlighted)
        skipButton.tintColor = skipButton.titleColor(for: .highlighted)
        skipButton.alignImageRight()
        skipButton.adjustInsetsForImage(withPadding: 6)
        addSubview(skipButton)
        skipButton.topAnchor.constraint(greaterThanOrEqualTo: skipLayoutGuide.topAnchor).isActive = true
        skipButton.bottomAnchor.constraint(lessThanOrEqualTo: skipLayoutGuide.bottomAnchor).isActive = true
        skipButton.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor).isActive = true
        skipButton.centerYAnchor.constraint(equalTo: skipLayoutGuide.centerYAnchor).isActive = true
        
        let dealsLayoutGuide = UILayoutGuide()
        addLayoutGuide(dealsLayoutGuide)
        dealsLayoutGuide.centerXAnchor.constraint(equalTo: contentView.layoutMarginsGuide.centerXAnchor).isActive = true
        dealsLayoutGuide.widthAnchor.constraint(lessThanOrEqualToConstant: 320 - (.padding * 2)).isActive = true
        
        let dealsLabel = UILabel()
        dealsLabel.translatesAutoresizingMaskIntoConstraints = false
        dealsLabel.text = "authorize.register.offers".localized
        dealsLabel.textColor = .gray3
        dealsLabel.numberOfLines = 0
        dealsLabel.font = .screenshopFont(.hindLight, size: 16)
        addSubview(dealsLabel)
        dealsLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        dealsLabel.topAnchor.constraint(equalTo: skipLayoutGuide.bottomAnchor, constant: .padding).isActive = true
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
        
        return NSMutableAttributedString(segmentedString: "authorize.register.legal", attributes: [
            attributes(),
            attributes(legalLinkTOS),
            attributes(),
            attributes(legalLinkPP),
            attributes()
            ])
    }
}

class RegisterViewController: UIViewController {
    private let inputViewAdjustsScrollViewController = InputViewAdjustsScrollViewController()
    
    weak var delegate: RegisterViewControllerDelegate?
    
    // MARK: View
    
    var classForView: RegisterView.Type {
        return RegisterView.self
    }
    
    var _view: RegisterView {
        return view as! RegisterView
    }
    
    var facebookLoginButton: FacebookButton {
        return _view.facebookLoginButton
    }
    
    var continueButton: UIButton {
        return _view.continueButton
    }
    
    var skipButton: UIButton {
        return _view.skipButton
    }
    
    override func loadView() {
        view = classForView.self.init()
    }
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _view.facebookLoginButton.addTarget(self, action: #selector(facebookLoginAction), for: .touchUpInside)
        
        _view.emailTextField.delegate = self
        _view.passwordTextField.delegate = self
        _view.legalTextView.delegate = self
        
        _view.continueButton.setTitle("authorize.register.continue".localized, for: .normal)
        _view.continueButton.addTarget(self, action: #selector(registerAction), for: .touchUpInside)
        
        _view.skipButton.addTarget(self, action: #selector(skipRegistration), for: .touchUpInside)
        
        inputViewAdjustsScrollViewController.scrollView = _view
        inputViewAdjustsScrollViewController.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        _view.addGestureRecognizer(tapGesture)
    }
    
    deinit {
        inputViewAdjustsScrollViewController.delegate = nil
        _view.emailTextField.delegate = nil
        _view.passwordTextField.delegate = nil
        _view.legalTextView.delegate = nil
    }
    
    // MARK: Keyboard
    
    @objc fileprivate func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: Register
    
    @objc fileprivate func registerAction() {
        let isValidRegistration = true
        
        if isValidRegistration {
            delegate?.registerViewControllerDidSignup(self)
        }
        else {
            // TODO: notify user there was an issue
        }
    }
    
    @objc fileprivate func skipRegistration() {
        delegate?.registerViewControllerDidSkip(self)
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
                    self.delegate?.registerViewControllerDidFacebookLogin(self)
                }
                else {
                    self.delegate?.registerViewControllerDidFacebookSignup(self)
                }
            }
        }
    }
}

extension RegisterViewController: InputViewAdjustsScrollViewControllerDelegate {
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

extension RegisterViewController: UITextFieldDelegate {
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
