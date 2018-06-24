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
    func registerViewControllerDidSignin(_ viewController: RegisterViewController)
    func registerViewControllerDidFacebookLogin(_ viewController: RegisterViewController)
    func registerViewControllerDidFacebookSignup(_ viewController: RegisterViewController)
}

class RegisterView: UIScrollView {
    let facebookLoginButton = FacebookButton()
    private let horizontalLinesView = HorizontalLinesView()
    let contentView = ContentContainerView()
    let emailTextField = UnderlineTextField()
    let passwordTextField = UnderlineTextField()
    let forgotPasswordButton = UIButton()
    let continueButton = MainButton()
    let skipButton = UIButton()
    
    var activeTextFieldTopOffset: CGFloat {
        return horizontalLinesView.frame.maxY - UIApplication.shared.statusBarFrame.height
    }
    
    var verticalNegativeMargin: CGFloat {
        return contentView.layoutMargins.top * 0.4
    }
    
    let _layoutMargins: UIEdgeInsets = {
        return UIEdgeInsets(top: .marginY, left: .padding, bottom: .marginY, right: .padding)
    }()
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init(frame: CGRect, isOnboardingLayout: Bool) {
        super.init(frame: frame)
        
        if let backgroundImage = UIImage(named: "BrandConfettiFullBackground") {
            backgroundColor = UIColor(patternImage: backgroundImage)
        }
        
        let verticalCenterLayoutView = UIView()
        verticalCenterLayoutView.translatesAutoresizingMaskIntoConstraints = false
        verticalCenterLayoutView.isHidden = true
        verticalCenterLayoutView.setContentCompressionResistancePriority(.required, for: .vertical)
        addSubview(verticalCenterLayoutView)
        let verticalTopConstraint = verticalCenterLayoutView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor)
        verticalTopConstraint.priority = .defaultHigh
        verticalTopConstraint.isActive = true
        let verticalBottomConstraint = verticalCenterLayoutView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
        verticalBottomConstraint.priority = .defaultHigh
        verticalBottomConstraint.isActive = true
        verticalCenterLayoutView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        var onboardingByLine: UILabel?
        
        if isOnboardingLayout {
            let welcomeTo = UILabel.init()
            welcomeTo.text = "authorize.register.welcome_to".localized
            welcomeTo.textAlignment = .center
            welcomeTo.translatesAutoresizingMaskIntoConstraints = false
            welcomeTo.font = UIFont.screenshopFont(.quicksand, size: 15)
            welcomeTo.textColor = UIColor.gray3
            addSubview(welcomeTo)
            welcomeTo.topAnchor.constraint(equalTo: verticalCenterLayoutView.topAnchor).isActive = true
            welcomeTo.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor).isActive = true
            
            let screenshopImageView = UIImageView.init(image: UIImage.init(named: "LaunchLogo"))
            screenshopImageView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(screenshopImageView)
            screenshopImageView.topAnchor.constraint(equalTo: welcomeTo.bottomAnchor, constant: .marginY).isActive = true
            screenshopImageView.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor).isActive = true
            
            let byLine = UILabel.init()
            byLine.text = "authorize.register.byline".localized
            byLine.textAlignment = .center
            byLine.translatesAutoresizingMaskIntoConstraints = false
            byLine.font = UIFont.screenshopFont(.quicksandMedium, size: 20)
            byLine.textColor = UIColor.gray3
            byLine.adjustsFontSizeToFitWidth = true
            byLine.minimumScaleFactor = 0.7
            byLine.baselineAdjustment = .alignCenters
            addSubview(byLine)
            byLine.topAnchor.constraint(equalTo: screenshopImageView.bottomAnchor, constant: .marginY).isActive = true
            byLine.leadingAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.leadingAnchor).isActive = true
            byLine.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor).isActive = true
            byLine.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor).isActive = true
            onboardingByLine = byLine
        }
        
        facebookLoginButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(facebookLoginButton)
        if let byLine = onboardingByLine {
            facebookLoginButton.topAnchor.constraint(equalTo: byLine.bottomAnchor, constant: .extendedPadding).isActive = true
        }
        else {
            facebookLoginButton.topAnchor.constraint(equalTo: verticalCenterLayoutView.topAnchor).isActive = true
        }
        facebookLoginButton.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        facebookLoginButton.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        horizontalLinesView.translatesAutoresizingMaskIntoConstraints = false
        horizontalLinesView.label.text = "generic.or".localized
        horizontalLinesView.leftLine.backgroundColor = .gray6
        horizontalLinesView.rightLine.backgroundColor = .gray6
        addSubview(horizontalLinesView)
        horizontalLinesView.topAnchor.constraint(equalTo: facebookLoginButton.bottomAnchor, constant: .marginY).isActive = true
        horizontalLinesView.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor).isActive = true
        horizontalLinesView.widthAnchor.constraint(equalToConstant: 170).isActive = true
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentView.topAnchor.constraint(equalTo: horizontalLinesView.bottomAnchor, constant: .marginY).isActive = true
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
        
        let color: UIColor = .crazeRed
        
        forgotPasswordButton.translatesAutoresizingMaskIntoConstraints = false
        forgotPasswordButton.setTitle("authorize.register.forgot".localized, for: .normal)
        forgotPasswordButton.setTitleColor(color, for: .normal)
        forgotPasswordButton.setTitleColor(color.darker(), for: .highlighted)
        forgotPasswordButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: .padding, bottom: 6, right: .padding)
        contentView.addSubview(forgotPasswordButton)
        forgotPasswordButton.topAnchor.constraint(equalTo: continueButton.bottomAnchor, constant: .marginY).isActive = true
        forgotPasswordButton.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        forgotPasswordButton.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor, constant: verticalNegativeMargin).isActive = true
        forgotPasswordButton.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        skipButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: .padding, bottom: 6, right: .padding)
        skipButton.setTitleColor(.gray3, for: .normal)
        skipButton.setTitleColor(.gray5, for: .highlighted)
        skipButton.alignImageRight()
        skipButton.adjustInsetsForImage(withPadding: 6)
        addSubview(skipButton)
        skipButton.topAnchor.constraint(equalTo: contentView.bottomAnchor, constant: .marginY).isActive = true
        skipButton.bottomAnchor.constraint(equalTo: verticalCenterLayoutView.bottomAnchor).isActive = true
        skipButton.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor).isActive = true
        
        if isOnboardingLayout {
            let skipImage = UIImage(named: "OnboardingArrow")
            skipButton.setImage(skipImage, for: .normal)
            skipButton.setImage(skipImage?.withRenderingMode(.alwaysTemplate), for: .highlighted)
            skipButton.tintColor = skipButton.titleColor(for: .highlighted)
            skipButton.setTitle("generic.skip".localized, for: .normal)
        }
        else {
            skipButton.setTitle("generic.cancel".localized, for: .normal)
        }
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
    }
    
    weak var delegate: RegisterViewControllerDelegate?
    var isOnboardingLayout = false
    
    private let inputViewAdjustsScrollViewController = InputViewAdjustsScrollViewController()
    
    private func setContinueCopy(_ continueCopy: ContinueCopy) {
        let copy: String
        
        switch continueCopy {
        case .default:
            copy = "authorize.register.continue".localized
        case .login:
            copy = "authorize.register.continue.login".localized
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
        view = classForView.self.init(frame: .zero, isOnboardingLayout: isOnboardingLayout)
    }
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(textFieldTextDidChange(_:)), name: .UITextFieldTextDidChange, object: _view.emailTextField)
        
        automaticallyAdjustsScrollViewInsets = false
        
        _view.facebookLoginButton.addTarget(self, action: #selector(facebookLoginAction), for: .touchUpInside)
        
        _view.emailTextField.delegate = self
        _view.passwordTextField.delegate = self
        
        _view.forgotPasswordButton.addTarget(self, action: #selector(forgotPasswordAction), for: .touchUpInside)
        _view.continueButton.addTarget(self, action: #selector(registerAction), for: .touchUpInside)
        setContinueCopy(.default)
        
        if let email = UserDefaults.standard.string(forKey: UserDefaultsKeys.email) {
            self.email = email
            setContinueCopy(.login)
        }
        
        _view.skipButton.addTarget(self, action: #selector(skipRegistration), for: .touchUpInside)
        
        inputViewAdjustsScrollViewController.scrollView = _view
        inputViewAdjustsScrollViewController.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        _view.addGestureRecognizer(tapGesture)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        inputViewAdjustsScrollViewController.delegate = nil
        _view.emailTextField.delegate = nil
        _view.passwordTextField.delegate = nil
    }
    
    // MARK: Keyboard
    
    @objc fileprivate func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: Register
    
    private func isPasswordValid(_ password: String?) -> Bool {
        if let _ = UserAccountManager.shared.validatePassword(password) {
            return true
        }
        else {
            return false
        }
    }
    
    @objc fileprivate func registerAction() {
        Analytics.trackOnboardingLoginStarted()
        
        let hasValidEmail = emailFormRow.isValid()
        let hasValidPassword = isPasswordValid(_view.passwordTextField.text)
        
        if hasValidEmail,
            hasValidPassword,
            let email = self.email,
            let password = _view.passwordTextField.text,
            self.continueButton.isLoading == false
        {
            self._view.emailTextField.resignFirstResponder()
            self._view.passwordTextField.resignFirstResponder()
            self._view.emailTextField.isUserInteractionEnabled = false
            self._view.passwordTextField.isUserInteractionEnabled = false
            self.continueButton.isLoading = true
            self.continueButton.isEnabled = false
            self.skipButton.isUserInteractionEnabled = false
            self.facebookLoginButton.isUserInteractionEnabled = false
            UserAccountManager.shared.loginOrCreatAccountAsNeeded(email: email, password: password)
            .then { result -> Void in
                if  result  == .unconfirmed {
                    
                    self.delegate?.registerViewControllerNeedEmailConfirmation(self)
                } else {
                    self.delegate?.registerViewControllerDidSignin(self)
                }
            }.catch { error in
                
                let e = error as NSError
                Analytics.trackOnboardingError(domain: e.domain, code: e.code, localizedDescription: e.localizedDescription)

                DispatchQueue.main.async {
                 
                    self._view.emailTextField.isInvalid = true
                    self._view.passwordTextField.isInvalid = true
                    ActionFeedbackGenerator().actionOccurred(.nope)
                    let error = error as NSError
                    if UserAccountManager.shared.isNoInternetError(error: error) {
                        let alert = UserAccountManager.shared.alertViewForNoInternet()
                        self.present(alert, animated: true, completion: nil)
                    }else if UserAccountManager.shared.isCantSendEmailError(error: error) {
                        let alert = UserAccountManager.shared.alertViewForCantSendEmail(email: email)
                        self.present(alert, animated: true, completion: nil)
                    }else if UserAccountManager.shared.isWrongPasswordError(error: error) {
                        let alert = UserAccountManager.shared.alertViewForWrongPassword()
                        self.present(alert, animated: true, completion: nil)
                    }else if UserAccountManager.shared.isWeakPasswordError(error: error) {
                        self._view.passwordTextField.isInvalid = true
                        self._view.passwordTextField.errorText = "authorize.error.password_invalid.server".localized

                    }else {
                        let alert = UserAccountManager.shared.alertViewForUndefinedError(error: error, viewController: self)
                        self.present(alert, animated: true, completion: nil)
                    }
                }
                
               
            }.always {
                self._view.emailTextField.isUserInteractionEnabled = true
                self._view.passwordTextField.isUserInteractionEnabled = true
                self.continueButton.isLoading = false
                self.continueButton.isEnabled = true
                self.skipButton.isUserInteractionEnabled = true
                self.facebookLoginButton.isUserInteractionEnabled = true

            }
        }
        else {
            if !hasValidEmail {
                Analytics.trackOnboardingLoginBadEmail(email: _view.emailTextField.text)
                _view.emailTextField.isInvalid = true
            }
            if !hasValidPassword {
                Analytics.trackOnboardingLoginBadPassword()
                _view.passwordTextField.isInvalid = true
                if _view.passwordTextField.text == "password" {
                    Analytics.trackFeaturePasswordIsPassword()
                    _view.passwordTextField.errorText = "authorize.error.password_invalid_password".localized
                }else{
                    _view.passwordTextField.errorText = "authorize.error.password_invalid".localized
                }
            }
            
            ActionFeedbackGenerator().actionOccurred(.nope)
        }
    }
    
    @objc fileprivate func skipRegistration() {
        func skip() {
            UserAccountManager.shared.makeAnonAccount()
            delegate?.registerViewControllerDidSkip(self)

        }
        if let password = _view.passwordTextField.text, password.lengthOfBytes(using: .utf8) == 0, let email = _view.emailTextField.text, email.lengthOfBytes(using: .utf8) == 0{
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
        Analytics.trackOnboardingForgotStarted(email: self.email)
        let resetPasswordViewController = InitiateResetPasswordViewController()
        resetPasswordViewController.delegate = self
        resetPasswordViewController._view.emailTextField.text = self.email
        navigationController?.pushViewController(resetPasswordViewController, animated: true)
    }
    
    // MARK: Facebook
    
    @objc fileprivate func facebookLoginAction() {
        Analytics.trackOnboardingFacebookStarted()
        self.continueButton.isUserInteractionEnabled = false
        self.skipButton.isUserInteractionEnabled = false
        self.facebookLoginButton.isUserInteractionEnabled = false

        UserAccountManager.shared.loginWithFacebook().then
            { (result) -> Void in
            
            let isExistingUser = (result == .facebookOld)
            
            if isExistingUser {
                self.delegate?.registerViewControllerDidFacebookLogin(self)
            } else {
                self.delegate?.registerViewControllerDidFacebookSignup(self)
            }
                
        }.catch { (error) in
            
            let e = error as NSError
            Analytics.trackOnboardingError(domain: e.domain, code: e.code, localizedDescription: e.localizedDescription)
            print("facebook login error: \(error)")
        }.always {
            self.continueButton.isUserInteractionEnabled = true
            self.skipButton.isUserInteractionEnabled = true
            self.facebookLoginButton.isUserInteractionEnabled = true

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
        if textField == _view.emailTextField, let email = self.email, !email.isEmpty {
            if emailFormRow.isValid() {
                previousEmail = email
            }
            else {
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
    func initiateResetPasswordViewControllerDidReset(_ viewController: InitiateResetPasswordViewController, email:String) {
        Analytics.trackOnboardingForgotEmailSend()
        let resetPasswordViewController = ResetPasswordViewController()
        resetPasswordViewController.delegate = self
        self.email = email
        resetPasswordViewController.email = email
        self.navigationController?.pushViewController(resetPasswordViewController, animated: true)
    }
    
    func initiateResetPasswordViewControllerDidCancel(_ viewController: InitiateResetPasswordViewController) {
        navigationController?.popViewController(animated: true)
    }
}
extension RegisterViewController: ResetPasswordViewControllerDelegate {
    func resetPasswordViewControllerDidReset(_ viewController: ResetPasswordViewController) {
        Analytics.trackOnboardingForgotSuccess()
        self.delegate?.registerViewControllerDidSignin(self)
    }
    
    func resetPasswordViewControllerDidCancel(_ viewController: ResetPasswordViewController) {
        navigationController?.popToViewController(self, animated: true)

    }
    
    
}
