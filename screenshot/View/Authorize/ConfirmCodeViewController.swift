//
//  ResetPasswordViewController.swift
//  screenshot
//
//  Created by Corey Werner on 5/30/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

protocol ConfirmCodeViewControllerDelegate: NSObjectProtocol {
    func confirmCodeViewControllerDidConfirm(_ viewController: ConfirmCodeViewController)
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
        titleLabel.text = "authorize.confirm.title".localized
        titleLabel.textColor = .gray3
        titleLabel.font = .screenshopFont(.hindSemibold, textStyle: .title1, staticSize: true)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.7
        addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: .extendedPadding).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        
        let explainLabel = UILabel()
        explainLabel.translatesAutoresizingMaskIntoConstraints = false
        let text = "authorize.confirm.explaination".localized(withFormat: email)
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
        
        let codeLabel = UILabel()
        codeLabel.translatesAutoresizingMaskIntoConstraints = false
        codeLabel.text = "authorize.confirm.code".localized
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
        codeTextField.keyboardType = .numbersAndPunctuation
        contentView.addSubview(codeTextField)
        codeTextField.topAnchor.constraint(equalTo: codeLabel.bottomAnchor).isActive = true
        codeTextField.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        codeTextField.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
      
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.backgroundColor = .crazeGreen
        continueButton.setTitle("generic.submit".localized, for: .normal)
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
    var email:String?
    private let inputViewAdjustsScrollViewController = InputViewAdjustsScrollViewController()
    
    // MARK: View
    
    var classForView: ConfirmCodeView.Type {
        return ConfirmCodeView.self
    }
    
    var _view: ConfirmCodeView {
        return view as! ConfirmCodeView
    }
    
    override func loadView() {
        let email = self.email ?? ""
        view = ConfirmCodeView.init(frame: .zero, email: email)
    }
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        inputViewAdjustsScrollViewController.scrollView = _view
        
        _view.codeTextField.delegate = self
        
        _view.continueButton.addTarget(self, action: #selector(continueAction), for: .touchUpInside)
        _view.cancelButton.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        _view.addGestureRecognizer(tapGesture)
    }
    
    deinit {
        _view.codeTextField.delegate = nil
    }
    
    // MARK: Actions
    
    @objc func continueAction() {
        if let code = _view.codeTextField.text {
            _view.codeTextField.resignFirstResponder()
            _view.continueButton.isLoading = true
            _view.continueButton.isUserInteractionEnabled = false
            _view.codeTextField.isUserInteractionEnabled = false
            UserAccountManager.shared.confirmSignup(code: code).then(on: .main) { () -> Void in
                    self.delegate?.confirmCodeViewControllerDidConfirm(self)
                }.catch { (error) in
                    DispatchQueue.main.async {
                        let error = error as NSError
                        if UserAccountManager.shared.isNoInternetError(error: error) {
                            let alert = UserAccountManager.shared.alertViewForNoInternet()
                            self.present(alert, animated: true, completion: nil)
                        }else if UserAccountManager.shared.isBadCodeError(error: error) {
                            let alert = UserAccountManager.shared.alertViewForBadCode()
                            self.present(alert, animated: true, completion: nil)
                        }else if UserAccountManager.shared.isCantSendEmailError(error: error), let email = self.email {
                            let alert = UserAccountManager.shared.alertViewForCantSendEmail(email: email)
                            self.present(alert, animated: true, completion: nil)
                        }else {
                            let alert = UserAccountManager.shared.alertViewForUndefinedError(error: error, viewController: self)
                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                }.always {
                    DispatchQueue.main.async {
                        self._view.continueButton.isLoading = false
                        self._view.continueButton.isUserInteractionEnabled = true
                        self._view.codeTextField.isUserInteractionEnabled = true
                    }
            }
        }
    }
    
    @objc private func cancelAction() {
        delegate?.confirmCodeViewControllerDidCancel(self)
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
        if textField == _view.codeTextField {
            _view.codeTextField.becomeFirstResponder()
        }
        return true
    }
}
