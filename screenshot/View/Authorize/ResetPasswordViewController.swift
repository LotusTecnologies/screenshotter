//
//  ResetPasswordViewController.swift
//  screenshot
//
//  Created by Corey Werner on 5/30/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

protocol ResetPasswordViewControllerDelegate: NSObjectProtocol {
    func resetPasswordViewControllerDidReset(_ viewController: ResetPasswordViewController)
    func resetPasswordViewControllerDidCancel(_ viewController: ResetPasswordViewController)
}

class ResetPasswordView: UIScrollView {
    let newPasswordTextField = UnderlineTextField()
    let continueButton = MainButton()
    let cancelButton = UIButton()
    
    let _layoutMargins = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override convenience init(frame: CGRect) {
        self.init(frame: frame, email: "")
    }
    
    init(frame: CGRect, email:String) {
        super.init(frame: frame)
        
        if let backgroundImage = UIImage(named: "BrandConfettiFullBackground") {
            backgroundColor = UIColor(patternImage: backgroundImage)
        }
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "authorize.reset_password.title".localized
        titleLabel.textColor = .gray3
        titleLabel.font = .screenshopFont(.quicksandMedium, textStyle: .title1, staticSize: true)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.7
        addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: .extendedPadding).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        let explainLabel = UILabel()
        explainLabel.translatesAutoresizingMaskIntoConstraints = false
        
        
        let text = "authorize.reset_password.explanation".localized(withFormat: email)
        let attributedString = NSMutableAttributedString(string: text, attributes: [
            NSAttributedStringKey.font: UIFont.screenshopFont(.hindLight, textStyle: .headline, staticSize: true),
            NSAttributedStringKey.foregroundColor : UIColor.gray3
            ])
        let range = NSString(string: text).range(of: email)
        if range.location != NSNotFound{
            attributedString.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.gray2, range: range)
            attributedString.addAttribute(NSAttributedStringKey.font, value: UIFont.screenshopFont(.hindMedium, textStyle: .headline, staticSize: true), range: range)
        }
        
        explainLabel.attributedText = attributedString
        explainLabel.minimumScaleFactor = 0.7
        explainLabel.numberOfLines = -1
        addSubview(explainLabel)
        explainLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: .padding).isActive = true
        explainLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        explainLabel.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        
        
        let contentView = ContentContainerView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentView.topAnchor.constraint(equalTo: explainLabel.bottomAnchor, constant: .padding).isActive = true
        contentView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        

        let newPasswordLabel = UILabel()
        newPasswordLabel.translatesAutoresizingMaskIntoConstraints = false
        newPasswordLabel.text = "authorize.reset_password.enter".localized
        newPasswordLabel.textColor = .gray2
        newPasswordLabel.font = .screenshopFont(.hindLight, textStyle: .body, staticSize: true)
        newPasswordLabel.adjustsFontSizeToFitWidth = true
        newPasswordLabel.minimumScaleFactor = 0.7
        newPasswordLabel.baselineAdjustment = .alignCenters
        contentView.addSubview(newPasswordLabel)
        newPasswordLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
        newPasswordLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        newPasswordLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        newPasswordTextField.translatesAutoresizingMaskIntoConstraints = false
        newPasswordTextField.isSecureTextEntry = true
        newPasswordTextField.autocorrectionType = .no
        newPasswordTextField.autocapitalizationType = .none
        newPasswordTextField.spellCheckingType = .no
        newPasswordTextField.textColor = .gray2
        contentView.addSubview(newPasswordTextField)
        newPasswordTextField.topAnchor.constraint(equalTo: newPasswordLabel.bottomAnchor).isActive = true
        newPasswordTextField.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        newPasswordTextField.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.backgroundColor = .crazeGreen
        
        continueButton.setTitle("generic.save".localized, for: .normal)
        contentView.addSubview(continueButton)
        continueButton.topAnchor.constraint(equalTo: newPasswordTextField.bottomAnchor, constant: .extendedPadding).isActive = true
        continueButton.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        continueButton.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
        continueButton.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        let skipLayoutGuide = UILayoutGuide()
        addLayoutGuide(skipLayoutGuide)
        skipLayoutGuide.topAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: .padding, bottom: 6, right: .padding)
        cancelButton.setTitle("generic.cancel".localized, for: .normal)
        cancelButton.setTitleColor(.gray3, for: .normal)
        cancelButton.setTitleColor(.gray5, for: .highlighted)
        addSubview(cancelButton)
        cancelButton.topAnchor.constraint(equalTo: skipLayoutGuide.bottomAnchor, constant: .padding).isActive = true
        cancelButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -_layoutMargins.bottom).isActive = true
        cancelButton.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor).isActive = true
    }
}

class ResetPasswordViewController: UIViewController {
    weak var delegate: ResetPasswordViewControllerDelegate?
    var email:String?
    var code:String? {
        didSet {
            _view.continueButton.isEnabled = ( code != nil )
        }
    }
    
    private let inputViewAdjustsScrollViewController = InputViewAdjustsScrollViewController()
    
    // MARK: View
    
    var classForView: ResetPasswordView.Type {
        return ResetPasswordView.self
    }
    
    var _view: ResetPasswordView {
        return view as! ResetPasswordView
    }
    
    override func loadView() {
        let email = self.email ?? ""
        view = ResetPasswordView.init(frame: .zero, email: email)
    }
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        inputViewAdjustsScrollViewController.scrollView = _view
        _view.continueButton.isEnabled = false
        _view.newPasswordTextField.delegate = self
        
        _view.continueButton.addTarget(self, action: #selector(continueAction), for: .touchUpInside)
        _view.cancelButton.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        _view.addGestureRecognizer(tapGesture)
    }
    
    deinit {
        _view.newPasswordTextField.delegate = nil
    }
    
    // MARK: Actions
    
    @objc private func continueAction() {
        let password =  UserAccountManager.shared.validatePassword(_view.newPasswordTextField.text)
        
        if let password = password, let code = code {
            dismissKeyboard()
            self._view.continueButton.isEnabled = false
            self._view.continueButton.isLoading = true
            self._view.cancelButton.isUserInteractionEnabled = false
            self._view.newPasswordTextField.isUserInteractionEnabled = false
            UserAccountManager.shared.confirmForgotPassword(code: code, password: password)
                .then(on: .main) { () -> Void in
                    self.delegate?.resetPasswordViewControllerDidReset(self)
                }.catch { (error) in
                    DispatchQueue.main.async {
                        let error = error as NSError
                        if UserAccountManager.shared.isNoInternetError(error: error) {
                            let alert = UserAccountManager.shared.alertViewForNoInternet()
                            self.present(alert, animated: true, completion: nil)
                        }else if UserAccountManager.shared.isBadCodeError(error: error){
                            let alert = UserAccountManager.shared.alertViewForBadCode()
                            self.present(alert, animated: true, completion: nil)
                        }else if UserAccountManager.shared.isWeakPasswordError(error: error) {
                            self._view.newPasswordTextField.isInvalid = true
                            self._view.newPasswordTextField.errorText = "authorize.error.passwordInvalid.server".localized
                       }else {
                            let alert = UserAccountManager.shared.alertViewForUndefinedError(error: error, viewController: self)
                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                }.always(on: .main) {
                    self._view.continueButton.isEnabled = (self.code != nil)
                    self._view.continueButton.isLoading = false
                    self._view.newPasswordTextField.isUserInteractionEnabled = true
                    self._view.cancelButton.isUserInteractionEnabled = true
            }

        }
        else {

            if password == nil {
                _view.newPasswordTextField.isInvalid = true
                _view.newPasswordTextField.errorText = "authorize.error.passwordInvalid".localized
            }
            
            ActionFeedbackGenerator().actionOccurred(.nope)
        }
    }
    
    @objc private func cancelAction() {
        delegate?.resetPasswordViewControllerDidCancel(self)
    }
    
    // MARK: Password
    private func validatePassword(_ password: String?) -> String? {
        if let password = password, !password.isEmpty {
            return password
        }
        return nil
    }
    
    private func validateCode(_ code: String?) -> String? {
        if let code = code, !code.isEmpty {
            return code
        }
        return nil
    }
    
    private func resetPassword() {
        _view.newPasswordTextField.text = nil
        _view.newPasswordTextField.isInvalid = false
    }
    
    // MARK: Keyboard
    
    @objc fileprivate func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension ResetPasswordViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        if textField == _view.newPasswordTextField {
            textField.resignFirstResponder()
        }
        return true
    }
}
