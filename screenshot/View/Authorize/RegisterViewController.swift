//
//  RegisterViewController.swift
//  screenshot
//
//  Created by Corey Werner on 5/21/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import Appsee

protocol RegisterViewControllerDelegate: NSObjectProtocol {
    func registerViewControllerDidSkip(_ viewController: RegisterViewController)
    func registerViewControllerNeedEmailConfirmation(_ viewController: RegisterViewController)
    func registerViewControllerDidSignup(_ viewController: RegisterViewController)
    func registerViewControllerDidFacebookLogin(_ viewController: RegisterViewController)
    func registerViewControllerDidFacebookSignup(_ viewController: RegisterViewController)
}

class RegisterView: UIScrollView {
    let facebookLoginButton = FacebookButton()
    private let horizontalLinesView = HorizontalLinesView()
    let contentView = ContentContainerView()
    let emailTextField = RegisterExistingTextField()
    let passwordTextField = UnderlineTextField()
    let forgotPasswordButton = UIButton()
    let continueButton = MainButton()
    let dealsSwitch = UISwitch()
    let skipButton = UIButton()
    let legalTextView = TappableTextView()
    
    private var showForgotPasswordConstraints: [NSLayoutConstraint] = []
    private var hideForgotPasswordConstraints: [NSLayoutConstraint] = []
    
    var isForgotPasswordButtonHidden = true {
        didSet {
            let duration: TimeInterval = .defaultAnimationDuration
            let curve: String
            let startTime: TimeInterval
            
            if isForgotPasswordButtonHidden {
                startTime = 0
                curve = kCAMediaTimingFunctionEaseIn
                
                NSLayoutConstraint.deactivate(showForgotPasswordConstraints)
                NSLayoutConstraint.activate(hideForgotPasswordConstraints)
            }
            else {
                startTime = 0.5
                curve = kCAMediaTimingFunctionEaseOut
                
                NSLayoutConstraint.deactivate(hideForgotPasswordConstraints)
                NSLayoutConstraint.activate(showForgotPasswordConstraints)
            }
            
            if self.window == nil {
                self.forgotPasswordButton.alpha = self.isForgotPasswordButtonHidden ? 0 : 1
                self.layoutSubviews()
            }else{
                CATransaction.begin()
                CATransaction.setAnimationDuration(duration)
                CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: curve))
                
                UIView.animateKeyframes(withDuration: duration, delay: 0, options: .init(rawValue: 0), animations: {
                    UIView.addKeyframe(withRelativeStartTime: startTime, relativeDuration: 0.5, animations: {
                        self.forgotPasswordButton.alpha = self.isForgotPasswordButtonHidden ? 0 : 1
                    })
                    UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1, animations: {
                        self.layoutSubviews()
                    })
                })
                
                let animation = CABasicAnimation(keyPath: "shadowPath")
                contentView.layer.add(animation, forKey: animation.keyPath)
                
                CATransaction.commit()
            }
           
        }
    }
    
    var activeTextFieldTopOffset: CGFloat {
        return horizontalLinesView.frame.maxY
    }
    
    var verticalNegativeMargin: CGFloat {
        return contentView.layoutMargins.top * 0.4
    }
    
    let _layoutMargins: UIEdgeInsets = {
        let verticalInset: CGFloat = UIDevice.is320w ? .padding : .padding * 2
        return UIEdgeInsets(top: verticalInset, left: .padding, bottom: verticalInset, right: .padding)
    }()
    
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        if let backgroundImage = UIImage(named: "BrandConfettiFullBackground") {
            backgroundColor = UIColor(patternImage: backgroundImage)
        }
        
        let verticalLayoutHeightConstant: CGFloat = {
            let statusBarHeight = UIApplication.shared.statusBarFrame.height
            
            if #available(iOS 11.0, *) {
                return statusBarHeight
            }
            else {
                return -statusBarHeight
            }
        }()
        
        // Force the height to be at least that of the scroll view
        let verticalLayoutView = UIView()
        verticalLayoutView.translatesAutoresizingMaskIntoConstraints = false
        verticalLayoutView.isHidden = true
        addSubview(verticalLayoutView)
        verticalLayoutView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        verticalLayoutView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        verticalLayoutView.heightAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.heightAnchor, constant: verticalLayoutHeightConstant).isActive = true
        
        facebookLoginButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(facebookLoginButton)
        facebookLoginButton.topAnchor.constraint(equalTo: topAnchor, constant: _layoutMargins.top).isActive = true
        facebookLoginButton.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        facebookLoginButton.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        let horizontalLinesLayoutGuide = UILayoutGuide()
        addLayoutGuide(horizontalLinesLayoutGuide)
        horizontalLinesLayoutGuide.topAnchor.constraint(equalTo: facebookLoginButton.bottomAnchor, constant: .padding).isActive = true
        
        horizontalLinesView.translatesAutoresizingMaskIntoConstraints = false
        horizontalLinesView.label.text = "generic.or".localized
        horizontalLinesView.leftLine.backgroundColor = .gray6
        horizontalLinesView.rightLine.backgroundColor = .gray6
        addSubview(horizontalLinesView)
        horizontalLinesView.topAnchor.constraint(greaterThanOrEqualTo: horizontalLinesLayoutGuide.topAnchor).isActive = true
        horizontalLinesView.bottomAnchor.constraint(lessThanOrEqualTo: horizontalLinesLayoutGuide.bottomAnchor).isActive = true
        horizontalLinesView.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor).isActive = true
        horizontalLinesView.centerYAnchor.constraint(equalTo: horizontalLinesLayoutGuide.centerYAnchor).isActive = true
        horizontalLinesView.widthAnchor.constraint(equalToConstant: 170).isActive = true
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentView.topAnchor.constraint(equalTo: horizontalLinesLayoutGuide.bottomAnchor, constant: .padding).isActive = true
        contentView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        contentView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -_layoutMargins.bottom).isActive = true
        contentView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        emailTextField.translatesAutoresizingMaskIntoConstraints = false
        emailTextField.placeholder = "authorize.register.email".localized
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
        passwordTextField.placeholder = "authorize.register.password".localized
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
        continueButton.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        hideForgotPasswordConstraints += [
            continueButton.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor, constant: verticalNegativeMargin)
        ]
        
        let color: UIColor = .crazeRed
        
        // TODO: underline
        forgotPasswordButton.translatesAutoresizingMaskIntoConstraints = false
        forgotPasswordButton.setTitle("authorize.register.forgot".localized, for: .normal)
        forgotPasswordButton.setTitleColor(color, for: .normal)
        forgotPasswordButton.setTitleColor(color.darker(), for: .highlighted)
        forgotPasswordButton.contentEdgeInsets = UIEdgeInsets(top: 6 + .padding, left: .padding, bottom: 6, right: .padding)
        forgotPasswordButton.alpha = 0
        contentView.addSubview(forgotPasswordButton)
        forgotPasswordButton.topAnchor.constraint(equalTo: continueButton.bottomAnchor).isActive = true
        forgotPasswordButton.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        forgotPasswordButton.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        showForgotPasswordConstraints += [
            forgotPasswordButton.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor, constant: verticalNegativeMargin)
        ]
        
        NSLayoutConstraint.activate(hideForgotPasswordConstraints)
        
        let skipLayoutGuide = UILayoutGuide()
        addLayoutGuide(skipLayoutGuide)
        skipLayoutGuide.topAnchor.constraint(equalTo: contentView.bottomAnchor, constant: .padding).isActive = true
        skipLayoutGuide.heightAnchor.constraint(equalTo: horizontalLinesLayoutGuide.heightAnchor).isActive = true
        
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
        legalTextView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
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
    private enum ContinueCopy {
        case `default`
        case login
        case register
    }
    
    weak var delegate: RegisterViewControllerDelegate?
    
    private let inputViewAdjustsScrollViewController = InputViewAdjustsScrollViewController()
    
    private func setContinueCopy(_ continueCopy: ContinueCopy) {
        let copy: String
        
        switch continueCopy {
        case .default:
            copy = "authorize.register.continue".localized
        case .login:
            copy = "authorize.register.continue.login".localized
        case .register:
            copy = "authorize.register.continue.register".localized
        }
        
        _view.continueButton.setTitle(copy, for: .normal)
    }
    
    private let emailFormRow = FormRow.Email()
    private var previousEmail: String?
    var email: String? {
        set {
            let newEmail = newValue?.trimmingCharacters(in: .whitespaces)
            emailFormRow.value = newEmail
            _view.emailTextField.text = newEmail
        }
        get {
            return emailFormRow.value
        }
    }
    
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
    
    var continueButton: MainButton {
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(textFieldTextDidChange(_:)), name: .UITextFieldTextDidChange, object: _view.emailTextField)
        
        _view.facebookLoginButton.addTarget(self, action: #selector(facebookLoginAction), for: .touchUpInside)
        
        _view.emailTextField.delegate = self
        _view.passwordTextField.delegate = self
        _view.legalTextView.delegate = self
        
        _view.forgotPasswordButton.addTarget(self, action: #selector(forgotPasswordAction), for: .touchUpInside)
        _view.continueButton.addTarget(self, action: #selector(registerAction), for: .touchUpInside)
        setContinueCopy(.default)
        
        if let email = UserDefaults.standard.string(forKey: UserDefaultsKeys.email) {
            self.email = email
            _view.emailTextField.exists = .yes
            setContinueCopy(.login)
        }
        
        _view.skipButton.addTarget(self, action: #selector(skipRegistration), for: .touchUpInside)
        
        inputViewAdjustsScrollViewController.scrollView = _view
        inputViewAdjustsScrollViewController.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        _view.addGestureRecognizer(tapGesture)
        
        self._view.isForgotPasswordButtonHidden = false
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
    
    private func isPasswordValid(_ password: String?) -> Bool {
        if let password = password, !password.isEmpty, password.lengthOfBytes(using: .utf8) >= 8 {
            return true
        }
        else {
            return false
        }
    }
    
    @objc fileprivate func registerAction() {
        let hasValidEmail = emailFormRow.isValid()
        let hasValidPassword = isPasswordValid(_view.passwordTextField.text)
        
        if hasValidEmail,
//            hasValidPassword,
            let email = self.email,
            let password = _view.passwordTextField.text,
            self.continueButton.isLoading == false
        {
            self._view.emailTextField.isUserInteractionEnabled = false
            self._view.passwordTextField.isUserInteractionEnabled = false
            self.continueButton.isLoading = true
            self.continueButton.isEnabled = false
            SigninManager.shared.loginOrCreatAccountAsNeeded(email: email, password: password)
            .then { result -> Void in
                
                switch result {
                case .login, .createAccountConfirmed:
                    self.delegate?.registerViewControllerDidSignup(self)
                case .createAccountUnconfirmed:
                    self.delegate?.registerViewControllerNeedEmailConfirmation(self)
                }
            }
            .catch { error in
                DispatchQueue.main.async {
                 
                    self._view.emailTextField.isInvalid = true
                    self._view.passwordTextField.isInvalid = true
                    self._view.isForgotPasswordButtonHidden = false
                    ActionFeedbackGenerator().actionOccurred(.nope)
                    let error = error as NSError
                    if SigninManager.shared.isNoInternetError(error: error) {
                        let alert = SigninManager.shared.alertViewForNoInternet()
                        self.present(alert, animated: true, completion: nil)
                    }else if SigninManager.shared.isCantSendEmailError(error: error) {
                        let alert = SigninManager.shared.alertViewForCantSendEmail(email: email)
                        self.present(alert, animated: true, completion: nil)
                    }else if SigninManager.shared.isWrongPasswordError(error: error) {
                        let alert = SigninManager.shared.alertViewForWrongPassword()
                        self.present(alert, animated: true, completion: nil)
                    }else {
                        let alert = SigninManager.shared.alertViewForUndefinedError(error: error, viewController: self)
                        self.present(alert, animated: true, completion: nil)
                    }
                }
                
               
            }.always {
                self._view.emailTextField.isUserInteractionEnabled = true
                self._view.passwordTextField.isUserInteractionEnabled = true
                self.continueButton.isLoading = false
                self.continueButton.isEnabled = true
            }
        }
        else {
            if !hasValidEmail {
                _view.emailTextField.isInvalid = true
            }
            if !hasValidPassword {
                _view.passwordTextField.isInvalid = true
                _view.passwordTextField.errorText = "authorize.error.passwordInvalid".localized
            }
            
            ActionFeedbackGenerator().actionOccurred(.nope)
        }
    }
    
    @objc fileprivate func skipRegistration() {
        func skip() {
            Analytics.trackSubmittedBlankEmail()
            delegate?.registerViewControllerDidSkip(self)

        }
        if let password = _view.passwordTextField.text, password.lengthOfBytes(using: .utf8) > 0, let email = _view.emailTextField.text, email.lengthOfBytes(using: .utf8) > 0{
            skip()
        }else{
            let alert = UIAlertController.init(title: nil, message: "authorize.register.skipConfirm".localized, preferredStyle: .alert)
            alert.addAction(UIAlertAction.init(title: "generic.cancel".localized, style: .cancel, handler: nil))
            alert.addAction(UIAlertAction.init(title: "generic.skip".localized, style: .default, handler: { (a) in
                skip()
            }))

            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
    
    // MARK: Forgot
    
    @objc private func forgotPasswordAction() {
        let resetPasswordViewController = InitiateResetPasswordViewController()
        resetPasswordViewController.delegate = self
        resetPasswordViewController._view.emailTextField.text = self.email
        navigationController?.pushViewController(resetPasswordViewController, animated: true)
    }
    
    // MARK: Facebook
    
    @objc fileprivate func facebookLoginAction() {
       
        SigninManager.shared.loginWithFacebook().then { (result) -> Void in
            let isExistingUser = false
            
            if isExistingUser {
                self.delegate?.registerViewControllerDidFacebookLogin(self)
            }
            else {
                self.delegate?.registerViewControllerDidFacebookSignup(self)
            }
            
            }.catch { (error) in
                print("facebook login error: \(error)")
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
    @objc private func textFieldTextDidChange(_ notification: Notification) {
        if let textField = notification.object as? UITextField, textField == _view.emailTextField {
            email = textField.text?.trimmingCharacters(in: .whitespaces)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == _view.emailTextField {
            _view.passwordTextField.becomeFirstResponder()
        }
        else if textField == _view.passwordTextField {
            textField.resignFirstResponder()
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == _view.emailTextField {
            if let email = self.email, emailFormRow.isValid() {
                _view.emailTextField.exists = .unknown
                
                previousEmail = email
            }
            else {
                _view.emailTextField.exists = .unknown
                _view.emailTextField.isInvalid = true
                ActionFeedbackGenerator().actionOccurred(.nope)
            }
        }
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
            present(viewController, animated: true)
        }
    }
    
    fileprivate func presentPrivacyPolicy() {
        Analytics.trackOnboardingSubmittedEmailPrivacy()
        
        if let viewController = LegalViewControllerFactory.privacyPolicyViewController() {
            present(viewController, animated: true)
        }
    }
}

extension RegisterViewController: InitiateResetPasswordViewControllerDelegate {
    func initiateResetPasswordViewControllerDidReset(_ viewController: InitiateResetPasswordViewController) {
        let resetPasswordViewController = ResetPasswordViewController()
        resetPasswordViewController.delegate = self
        self.email = viewController._view.emailTextField.text
        resetPasswordViewController.email = self.email
        self.navigationController?.pushViewController(resetPasswordViewController, animated: true)
    }
    
    func initiateResetPasswordViewControllerDidCancel(_ viewController: InitiateResetPasswordViewController) {
        navigationController?.popViewController(animated: true)
    }
}
extension RegisterViewController: ResetPasswordViewControllerDelegate {
    func resetPasswordViewControllerDidReset(_ viewController: ResetPasswordViewController) {
        self.delegate?.registerViewControllerDidSignup(self)
    }
    
    func resetPasswordViewControllerDidCancel(_ viewController: ResetPasswordViewController) {
        navigationController?.popToViewController(self, animated: true)

    }
    
    
}
