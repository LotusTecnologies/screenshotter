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
    
    // MARK: Life Cycle
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        titleLabel.text = "tutorial.email.title".localized
        subtitleLabel.text = "tutorial.email.detail".localized
        
        let paddingView1 = UIView()
        paddingView1.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(paddingView1)
        paddingView1.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        let paddingView1HeightConstraint = paddingView1.heightAnchor.constraint(equalToConstant: .extendedPadding)
        paddingView1HeightConstraint.priority = UILayoutPriorityDefaultLow
        paddingView1HeightConstraint.isActive = true
        
        setupTextField(nameTextField)
        nameTextField.text = UserDefaults.standard.string(forKey: UserDefaultsKeys.name) ?? ""
        nameTextField.placeholder = "tutorial.email.name".localized
        nameTextField.returnKeyType = .next
        nameTextField.autocapitalizationType = .words
        contentView.addSubview(nameTextField)
        nameTextField.topAnchor.constraint(equalTo: paddingView1.bottomAnchor).isActive = true
        nameTextField.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor).isActive = true
        nameTextField.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor).isActive = true
        nameTextField.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        nameTextField.widthAnchor.constraint(greaterThanOrEqualToConstant: 236).isActive = true
        
        setupTextField(emailTextField)
        emailTextField.text = UserDefaults.standard.string(forKey: UserDefaultsKeys.email) ?? ""
        emailTextField.placeholder = "tutorial.email.email".localized
        emailTextField.keyboardType = .emailAddress
        emailTextField.autocapitalizationType = .none
        contentView.addSubview(emailTextField)
        emailTextField.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: .extendedPadding).isActive = true
        emailTextField.leadingAnchor.constraint(equalTo: nameTextField.leadingAnchor).isActive = true
        emailTextField.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor).isActive = true
        emailTextField.widthAnchor.constraint(equalTo: nameTextField.widthAnchor).isActive = true
        
        let paddingView2 = UIView()
        paddingView2.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(paddingView2)
        paddingView2.topAnchor.constraint(equalTo: emailTextField.bottomAnchor).isActive = true
        let paddingView2HeightConstraint = paddingView2.heightAnchor.constraint(equalToConstant: .extendedPadding)
        paddingView2HeightConstraint.priority = UILayoutPriorityDefaultLow
        paddingView2HeightConstraint.isActive = true
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("generic.submit".localized, for: .normal)
        button.addTarget(self, action: #selector(submitEmail), for: .touchUpInside)
        contentView.addSubview(button)
        button.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        button.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        button.topAnchor.constraint(equalTo: paddingView2.bottomAnchor, constant: .extendedPadding).isActive = true
        button.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor).isActive = true
        button.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor).isActive = true
        button.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        
        {
            textView.tappableTextDelegate = self
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
            
            let tappableText: [[String : Bool]] = [
                ["By tapping \"Submit\" above, you agree to our ": false],
                ["Terms of Service": true],
                [" and ": false],
                ["Privacy Policy": true],
                [" ": false]
            ]
            
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = textView.textAlignment
            
            let attributes: [String : AnyObject] = [
                NSFontAttributeName: textView.font!,
                NSParagraphStyleAttributeName: paragraph
            ]
            
            textView.applyTappableText(tappableText, with: attributes)
        }()
        
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
        textField.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        
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
        let name = nameTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let trimmedEmail = emailTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let email = trimmedEmail.isValidEmail ? trimmedEmail : ""
        
        UserDefaults.standard.set(name, forKey: UserDefaultsKeys.name)
        UserDefaults.standard.set(email, forKey: UserDefaultsKeys.email)
        
        let channel = UserDefaults.standard.string(forKey: UserDefaultsKeys.referralChannel)
        
        let user = AnalyticsUser(name: name, email: email, channel: channel)
        AnalyticsTrackers.standard.identify(user)
        AnalyticsTrackers.branch.identify(user)
        
        let eventName = email.count > 0 ? "Submitted email" : "Submitted blank email"
        AnalyticsTrackers.standard.track(eventName, properties: user.analyticsProperties)

        UserDefaults.standard.set(user.identifier, forKey: UserDefaultsKeys.userID)
        UserDefaults.standard.synchronize()
        
        resignTextField()
        delegate?.tutorialEmailSlideViewDidComplete(self)
    }
    
    @objc private func resignTextField() {
        endEditing(true)
    }
    
    // MARK: Legal
    
    class func termsOfServiceViewController(withDoneTarget target: Any?, action: Selector?) -> UIViewController? {
        guard let url = URL(string: "http://crazeapp.com/legal/#tos") else {
            return nil
        }
        
        let title = "legal.terms_of_service".localized
        
        return webViewController(withTitle: title, url: url, doneTarget: target, action: action)
    }

    class func privacyPolicyViewController(withDoneTarget target: Any?, action: Selector?) -> UIViewController? {
        guard let url = URL(string: "http://crazeapp.com/legal/#privacy") else {
            return nil
        }
        
        let title = "legal.privacy_policy".localized
        
        return webViewController(withTitle: title, url: url, doneTarget: target, action: action)
    }
    
    private class func webViewController(withTitle title: String, url: URL, doneTarget target: Any?, action: Selector?) -> UIViewController? {
        let viewController = WebViewController()
        viewController.url = url
        viewController.isToolbarEnabled = false
        viewController.navigationItem.title = title
        viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: target, action: action)
        
        return UINavigationController(rootViewController: viewController)
    }
    
    // MARK: Keyboard
    
    @objc func keyboardWillShow(_ notification: NSNotification) {
        guard window != nil, let value = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        
        scrollInset = UIEdgeInsets(top: 0, left: 0, bottom: value.cgRectValue.size.height, right: 0)
    }
    
    @objc func keyboardWillHide(_ notification: NSNotification) {
        guard window != nil else {
            return
        }
        
        if let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber {
            UIView.animate(withDuration: duration.doubleValue) {
                self.scrollInset = .zero
            }
            
        } else {
            scrollInset = .zero
        }
    }
}

extension TutorialEmailSlideView : TappableTextDelegate {
    func tappableText(view: TappableTextProtocol, tappedTextAt index: UInt) {
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
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)
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
