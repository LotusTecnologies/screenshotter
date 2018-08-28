//
//  InitiateResetPasswordViewController.swift
//  screenshot
//
//  Created by Corey Werner on 5/30/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

protocol InitiateResetPasswordViewControllerDelegate: NSObjectProtocol {
    func initiateResetPasswordViewControllerDidReset(_ viewController: InitiateResetPasswordViewController, email:String)
    func initiateResetPasswordViewControllerDidCancel(_ viewController: InitiateResetPasswordViewController)
}

class InitiateResetPasswordView: UIScrollView {
    private let titleLabel = UILabel()
    let emailTextField = UnderlineTextField()
    let continueButton = MainButton()
    let backButton = UIButton()
    
    var activeTextFieldTopOffset: CGFloat {
        return titleLabel.frame.maxY - contentOffset.y
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
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "authorize.initiate_reset_password.title".localized
        titleLabel.textColor = .gray3
        titleLabel.font = .screenshopFont(.quicksandMedium, textStyle: .title1, staticSize: true)
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
        
        let emailImageView = UIImageView(image: UIImage(named: "AuthorizeEmailSent"))
        emailImageView.translatesAutoresizingMaskIntoConstraints = false
        emailImageView.contentMode = .scaleAspectFit
        contentView.addSubview(emailImageView)
        emailImageView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
        emailImageView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        
        let messageLabel = UILabel()
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.text = "authorize.initiate_reset_password.message".localized
        messageLabel.textColor = .gray2
        messageLabel.font = .screenshopFont(.hindLight, textStyle: .body, staticSize: true)
        messageLabel.numberOfLines = 0
        contentView.addSubview(messageLabel)
        messageLabel.topAnchor.constraint(equalTo: emailImageView.bottomAnchor, constant: .padding).isActive = true
        messageLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        messageLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        emailTextField.translatesAutoresizingMaskIntoConstraints = false
        emailTextField.placeholder = "your.email@gmail.com"
        emailTextField.textColor = .gray2
        emailTextField.autocapitalizationType = .none
        emailTextField.autocorrectionType = .no
        emailTextField.spellCheckingType = .no
        emailTextField.returnKeyType = .send
        emailTextField.keyboardType = .emailAddress
        contentView.addSubview(emailTextField)
        emailTextField.topAnchor.constraint(equalTo: messageLabel.lastBaselineAnchor, constant: .extendedPadding).isActive = true
        emailTextField.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        emailTextField.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.backgroundColor = .crazeGreen
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

class InitiateResetPasswordViewController: UIViewController {
    weak var delegate: InitiateResetPasswordViewControllerDelegate?
    
    private let inputViewAdjustsScrollViewController = InputViewAdjustsScrollViewController()
    
    // MARK: View
    
    var classForView: InitiateResetPasswordView.Type {
        return InitiateResetPasswordView.self
    }
    
    var _view: InitiateResetPasswordView {
        return view as! InitiateResetPasswordView
    }
    
    var continueButton: MainButton {
        return _view.continueButton
    }
    
    var backButton: UIButton {
        return _view.backButton
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
        
        _view.continueButton.addTarget(self, action: #selector(continueAction), for: .touchUpInside)
        _view.backButton.addTarget(self, action: #selector(backAction), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        _view.addGestureRecognizer(tapGesture)
    }
    
    deinit {
        inputViewAdjustsScrollViewController.delegate = nil
        if isViewLoaded {
            _view.emailTextField.delegate = nil
        }
    }
    
    // MARK: Actions
    
    @objc private func continueAction() {
        dismissKeyboard()
        
        if let email = validateEmail(_view.emailTextField.text) {
            Analytics.trackOnboardingForgotSubmited(email: email)
            self.continueButton.isLoading = true
            self.continueButton.isEnabled = false
            self._view.backButton.isUserInteractionEnabled = false
            self._view.emailTextField.isUserInteractionEnabled = false
            
            UserAccountManager.shared.forgotPassword(email: email)
                .then(on: .main) { () -> Void in
                    self.delegate?.initiateResetPasswordViewControllerDidReset(self, email:email)
                }.catch { (error) in
                    DispatchQueue.main.async {
                        let error = error as NSError
                        if UserAccountManager.shared.isNoInternetError(error: error) {
                            let alert = UserAccountManager.shared.alertViewForNoInternet()
                            self.present(alert, animated: true, completion: nil)
                        }else if UserAccountManager.shared.isNoAccountWithEmailError(error: error) {
                            let alert = UserAccountManager.shared.alertViewForNoAccountWithEmail()
                            self.present(alert, animated: true, completion: nil)
                        }else if UserAccountManager.shared.isCantSendEmailError(error: error) {
                            let alert = UserAccountManager.shared.alertViewForCantSendEmail(email: email)
                            self.present(alert, animated: true, completion: nil)
                        }else {
                            let alert = UserAccountManager.shared.alertViewForUndefinedError(error: error, viewController: self)
                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                }.always {
                    self.continueButton.isLoading = false
                    self.continueButton.isEnabled = true
                    self._view.emailTextField.isUserInteractionEnabled = true
                    self._view.backButton.isUserInteractionEnabled = true
            }
        }
        else {
            Analytics.trackOnboardingError(domain: "craze", code: #line, localizedDescription: "Invalid email")
            _view.emailTextField.isInvalid = true
            
            ActionFeedbackGenerator().actionOccurred(.nope)
        }
    }
    
    @objc private func backAction() {
        delegate?.initiateResetPasswordViewControllerDidCancel(self)
    }
    
    // MARK: Email
    
    private func validateEmail(_ email: String?) -> String? {
        if let email = email, !email.isEmpty {
            let emailFormRow = FormRow.Email()
            emailFormRow.value = email
            if emailFormRow.isValid() {
                return email
            }
        }
        return nil
    }
    
    
    // MARK: Keyboard
    
    @objc fileprivate func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension InitiateResetPasswordViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        continueAction()
        return true
    }
}

extension InitiateResetPasswordViewController: InputViewAdjustsScrollViewControllerDelegate {
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
