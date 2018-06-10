//
//  ResetPasswordViewController.swift
//  screenshot
//
//  Created by Corey Werner on 5/30/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

protocol ConfirmCodeViewControllerDelegate: NSObjectProtocol {
    func confirmCodeViewControllerDidReset(_ viewController: ConfirmCodeViewController)
    func confirmCodeViewControllerDidCancel(_ viewController: ConfirmCodeViewController)
}

class ConfirmCodeView: UIScrollView {
    let codeTextField = UnderlineTextField()
    let continueButton = MainButton()
    let cancelButton = UIButton()
    
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
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "authorize.reset_password.title".localized
        titleLabel.textColor = .gray3
        titleLabel.font = .screenshopFont(.hindSemibold, textStyle: .title1, staticSize: true)
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
        
        let codeLabel = UILabel()
        codeLabel.translatesAutoresizingMaskIntoConstraints = false
        codeLabel.text = "authorize.reset_password.enter".localized
        codeLabel.textColor = .gray2
        codeLabel.font = .screenshopFont(.hindLight, textStyle: .body, staticSize: true)
        codeLabel.adjustsFontSizeToFitWidth = true
        codeLabel.minimumScaleFactor = 0.7
        codeLabel.baselineAdjustment = .alignCenters
        contentView.addSubview(codeLabel)
        codeLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
        codeLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        codeLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        codeTextField.translatesAutoresizingMaskIntoConstraints = false
        codeTextField.placeholder = ""
        codeTextField.autocorrectionType = .no
        codeTextField.autocapitalizationType = .none
        codeTextField.spellCheckingType = .no
        codeTextField.returnKeyType = .next
        codeTextField.textColor = .gray2
        contentView.addSubview(codeTextField)
        codeTextField.topAnchor.constraint(equalTo: codeLabel.bottomAnchor).isActive = true
        codeTextField.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        codeTextField.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
      
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.backgroundColor = .crazeGreen
        continueButton.setTitle("generic.save".localized, for: .normal)
        contentView.addSubview(continueButton)
        continueButton.topAnchor.constraint(equalTo: codeTextField.bottomAnchor, constant: .extendedPadding).isActive = true
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

class ConfirmCodeViewController: UIViewController {
    weak var delegate: ConfirmCodeViewControllerDelegate?
    
    private let inputViewAdjustsScrollViewController = InputViewAdjustsScrollViewController()
    
    // MARK: View
    
    var classForView: ResetPasswordView.Type {
        return ResetPasswordView.self
    }
    
    var _view: ResetPasswordView {
        return view as! ResetPasswordView
    }
    
    override func loadView() {
        view = classForView.self.init()
    }
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        inputViewAdjustsScrollViewController.scrollView = _view
        
        _view.passwordTextField.delegate = self
        _view.rePasswordTextField.delegate = self
        
        _view.continueButton.addTarget(self, action: #selector(continueAction), for: .touchUpInside)
        _view.cancelButton.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        _view.addGestureRecognizer(tapGesture)
    }
    
    deinit {
        _view.passwordTextField.delegate = nil
        _view.rePasswordTextField.delegate = nil
    }
    
    // MARK: Actions
    
    @objc private func continueAction() {
        let password = validatePassword(_view.passwordTextField.text)
        let rePassword = validatePassword(_view.rePasswordTextField.text)
        
        if let password = password, let rePassword = rePassword {
            dismissKeyboard()
            
            if password == rePassword {
                savePassword(password)
                
                let alertController = UIAlertController(title: "authorize.reset_password.success_alert.title".localized, message: "authorize.reset_password.success_alert.message".localized, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "generic.ok".localized, style: .cancel, handler: { alertAction in
                    self.delegate?.confirmCodeViewControllerDidReset(self)
                }))
                present(alertController, animated: true)
            }
            else {
                let alertController = UIAlertController(title: "authorize.reset_password.failed_alert.title".localized, message: nil, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "generic.ok".localized, style: .cancel, handler: { alertAction in
                    self.resetPassword()
                }))
                present(alertController, animated: true)
                
                _view.passwordTextField.isInvalid = true
                _view.rePasswordTextField.isInvalid = true
                
                ActionFeedbackGenerator().actionOccurred(.nope)
            }
        }
        else {
            if password == nil {
                _view.passwordTextField.isInvalid = true
            }
            if rePassword == nil {
                _view.rePasswordTextField.isInvalid = true
            }
            
            ActionFeedbackGenerator().actionOccurred(.nope)
        }
    }
    
    @objc private func cancelAction() {
        delegate?.confirmCodeViewControllerDidCancel(self)
    }
    
    // MARK: Password
    
    private func validatePassword(_ password: String?) -> String? {
        if let password = password, !password.isEmpty {
            return password
        }
        return nil
    }
    
    private func resetPassword() {
        _view.passwordTextField.text = nil
        _view.passwordTextField.isInvalid = false
        _view.rePasswordTextField.text = nil
        _view.rePasswordTextField.isInvalid = false
    }
    
    private func savePassword(_ password: String) {
        // TODO:
    }
    
    // MARK: Keyboard
    
    @objc fileprivate func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension ConfirmCodeViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == _view.passwordTextField {
            _view.rePasswordTextField.becomeFirstResponder()
        }
        else if textField == _view.rePasswordTextField {
            textField.resignFirstResponder()
        }
        return true
    }
}
