//
//  TutorialEmailSlideView.swift
//  screenshot
//
//  Created by Corey Werner on 10/22/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit

protocol TutorialEmailSlideViewDelegate : class {
    func tutorialEmailSlideViewDidComplete(_ slideView: TutorialEmailSlideView)
    func tutorialEmailSlideViewDidTapTermsOfService(_ slideView: TutorialEmailSlideView)
    func tutorialEmailSlideViewDidTapPrivacyPolicy(_ slideView: TutorialEmailSlideView)
}

public class TutorialEmailSlideView : HelperView {
    weak var delegate: TutorialEmailSlideViewDelegate?
    
    fileprivate let nameTextField = TutorialEmailSlideTextField()
    fileprivate let emailTextField = TutorialEmailSlideTextField()
    fileprivate let textView = TappableTextView()
    fileprivate let button = MainButton()
    fileprivate var expandableViewHeightConstraint: NSLayoutConstraint!
    
    fileprivate var keyboardFrame = CGRect.zero
    private var readyToSubmit = false
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        titleLabel.text = "Sign Up"
        subtitleLabel.text = "Fill out your info below"
        
        setupTextField(nameTextField)
        nameTextField.text = UserDefaults.standard.string(forKey: UserDefaultsKeys.name) ?? ""
        nameTextField.placeholder = "Name"
        nameTextField.returnKeyType = .next
        contentView.addSubview(nameTextField)
        nameTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: .extendedPadding).isActive = true
        nameTextField.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor).isActive = true
        nameTextField.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor).isActive = true
        nameTextField.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        nameTextField.widthAnchor.constraint(greaterThanOrEqualToConstant: 236).isActive = true
        
        setupTextField(emailTextField)
        emailTextField.text = UserDefaults.standard.string(forKey: UserDefaultsKeys.email) ?? ""
        emailTextField.placeholder = "Email"
        emailTextField.keyboardType = .emailAddress
        emailTextField.autocapitalizationType = .none
        contentView.addSubview(emailTextField)
        emailTextField.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: .extendedPadding).isActive = true
        emailTextField.leadingAnchor.constraint(equalTo: nameTextField.leadingAnchor).isActive = true
        emailTextField.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor).isActive = true
        emailTextField.widthAnchor.constraint(equalTo: nameTextField.widthAnchor).isActive = true
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Submit", for: .normal)
        button.addTarget(self, action: #selector(submitEmail), for: .touchUpInside)
        contentView.addSubview(button)
        button.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        button.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, for: .vertical)
        button.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: .extendedPadding * 2).isActive = true
        button.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor).isActive = true
        button.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor).isActive = true
        button.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        
        {
            textView.delegate = self
            textView.translatesAutoresizingMaskIntoConstraints = false
            textView.backgroundColor = .clear
            textView.textColor = .gray6
            textView.textAlignment = .center
            textView.font = UIFont.preferredFont(forTextStyle: .footnote)
            textView.adjustsFontForContentSizeCategory = true
            textView.isEditable = false
            textView.isScrollEnabled = false
            textView.scrollsToTop = false
            contentView.addSubview(textView)
            textView.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
            textView.topAnchor.constraint(greaterThanOrEqualTo:button.bottomAnchor, constant: .extendedPadding).isActive = true
            textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
            textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
            textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
            
            let tappableText: [[String: NSNumber]] = [
                ["By tapping \"Submit\" above, you agree to our ": NSNumber(value:false)],
                ["Terms of Service": NSNumber(value:true)],
                [" and ": NSNumber(value:false)],
                ["Privacy Policy": NSNumber(value:true)],
                [" ": NSNumber(value:false)]
            ]
            
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = textView.textAlignment
            
            let attributes: [String : Any] = [
                NSFontAttributeName : textView.font!,
                NSParagraphStyleAttributeName : paragraph
            ]
            
            textView.applyTappableText(tappableText, withAttributes: attributes)
        }()
        
        let expandableView = UIView()
        expandableView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(expandableView)
        expandableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        expandableViewHeightConstraint = NSLayoutConstraint(item: expandableView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
        expandableViewHeightConstraint.isActive = true
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(resignTextField)))
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        
        textView.delegate = nil
    }
    
    // MARK: Layout
    
    func setupTextField(_ textField: UITextField) {
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        textField.textAlignment = .center
        textField.font = UIFont.preferredFont(forTextStyle: .body)
        textField.adjustsFontForContentSizeCategory = true
        textField.backgroundColor = .white
        textField.borderStyle = .none
        textField.spellCheckingType = .no
        textField.autocorrectionType = .no
        textField.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: .vertical)
        
        let borderView = UIView()
        borderView.translatesAutoresizingMaskIntoConstraints = false
        borderView.backgroundColor = .gray3
        textField.addSubview(borderView)
        borderView.leadingAnchor.constraint(equalTo: textField.leadingAnchor).isActive = true
        borderView.bottomAnchor.constraint(equalTo: textField.bottomAnchor).isActive = true
        borderView.trailingAnchor.constraint(equalTo: textField.trailingAnchor).isActive = true
        borderView.heightAnchor.constraint(equalToConstant: .halfPoint).isActive = true
    }
    
    // MARK: Actions
    
    @objc private func submitEmail() {
        readyToSubmit = true
        
        let trimmedName = nameTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let trimmedEmail = (emailTextField.text?.isValidEmail() ?? false) ? (emailTextField.text?.trimmingCharacters(in: .whitespaces) ?? "") : ""
        
        UserDefaults.standard.set(trimmedName, forKey: UserDefaultsKeys.name)
        UserDefaults.standard.set(trimmedEmail, forKey: UserDefaultsKeys.email)
        
        let user = identify(trimmedName, email: trimmedEmail)
        _ = identify(trimmedName, email: trimmedEmail, tracker: AnalyticsTrackers.branch)
        
        if trimmedEmail.count > 0 {
            track("Submitted email", properties: [
                "id": user.identifier,
                "name": trimmedName,
                "email": trimmedEmail
                ])
            
        } else {
            track("Submitted blank email", properties: [
                "id": user.identifier,
                "name": trimmedName
                ])
        }

        if let ambassadorUsername = UserDefaults.standard.string(forKey: UserDefaultsKeys.ambasssadorUsername) {
            track("Referring Ambassador", properties: ["username": ambassadorUsername])
        }
        
        UserDefaults.standard.set(user.identifier, forKey: UserDefaultsKeys.userID)
        UserDefaults.standard.synchronize()
        
        informDelegateOfSubmittedEmailIfPossible()
        emailTextField.resignFirstResponder()
    }
    
    @objc private func resignTextField() {
        endEditing(true)
    }
    
    private func informDelegateOfSubmittedEmailIfPossible() {
        if !emailTextField.isFirstResponder, readyToSubmit {
            resignTextField()
            delegate?.tutorialEmailSlideViewDidComplete(self)
        }
    }
    
    // MARK: Legal
    
    class func termsOfServiceViewController(withDoneTarget target: Any?, action: Selector?) -> UIViewController? {
        guard let url = URL(string: "http://crazeapp.com/legal/#tos") else {
            return nil
        }
        
        let title = "Terms of Service"
        
        return webViewController(withTitle: title, url: url, doneTarget: target, action: action)
    }

    class func privacyPolicyViewController(withDoneTarget target: Any?, action: Selector?) -> UIViewController? {
        guard let url = URL(string: "http://crazeapp.com/legal/#privacy") else {
            return nil
        }
        
        let title = "Privacy Policy"
        
        return webViewController(withTitle: title, url: url, doneTarget: target, action: action)
    }
    
    private class func webViewController(withTitle title: String, url: URL, doneTarget target: Any?, action: Selector?) -> UIViewController? {
        let webVC = WebViewController()
        webVC.url = url
        webVC.toolbarEnabled = false
        webVC.navigationItem.title = title
        webVC.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: target, action: action)
        
        return UINavigationController(rootViewController: webVC)
    }
    
    // MARK: Alert
    
    func failedAlertController() -> UIAlertController {
        let controller = UIAlertController(title: "Submission Failed", message: "Please enter a valid email.", preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        return controller
    }
    
    // MARK: Keyboard
    
    @objc func keyboardDidHide(_ note: NSNotification) {
        guard let _ = window else {
            return
        }
        
        informDelegateOfSubmittedEmailIfPossible()
    }
    
    @objc func keyboardWillShow(_ note: NSNotification) {
        guard let _ = window,
        let value = note.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        
        keyboardFrame = value.cgRectValue
    }
}

extension TutorialEmailSlideView : TappableTextViewDelegate {
    public func tappableTextView(_ textView: TappableTextView!, tappedTextAt index: UInt) {
        switch index {
        case 3:
            delegate?.tutorialEmailSlideViewDidTapPrivacyPolicy(self)
            break
        case 1:
            delegate?.tutorialEmailSlideViewDidTapTermsOfService(self)
            break
        default:
            break
        }
    }
}

extension TutorialEmailSlideView : UITextFieldDelegate {
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        // Wait until keyboard frame has been set!
        
        DispatchQueue.main.async {
            guard let window = self.window else {
                return
            }
            
            let toWindowRect = self.convert(self.frame, to: window)
            let bottomOffset = window.bounds.size.height - toWindowRect.maxY + self.button.bounds.size.height
            
            self.expandableViewHeightConstraint.constant = max(self.keyboardFrame.size.height - bottomOffset, 0)
            UIView.animate(withDuration: 0.25) {
                self.contentView.layoutIfNeeded()
            }
        }
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        expandableViewHeightConstraint.constant = 0
        
        UIView.animate(withDuration: 0.25) {
            self.contentView.layoutIfNeeded()
        }
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameTextField {
            emailTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        
        return true
    }
}

extension TutorialEmailSlideView : TutorialSlideView {
    public func didEnterSlide() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(_:)), name: .UIKeyboardDidHide, object: nil)
    }
    
    public func willLeaveSlide() {
        NotificationCenter.default.removeObserver(self)
    }
}

private class TutorialEmailSlideTextField : UITextField {
    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height *= 1.5
        return size
    }
}
