//
//  TutorialEmailSlideView.swift
//  screenshot
//
//  Created by Jacob Relkin on 10/22/17.
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
    
    let nameTextField = UITextField()
    let emailTextField = UITextField()
    let textView = TappableTextView()
    let button = MainButton()
    var expandableViewHeightConstraint: NSLayoutConstraint!
    
    var keyboardFrame: CGRect = .zero
    var readyToSubmit: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        titleLabel.text = "Sign Up"
        subtitleLabel.text = "Fill out your info belows"
        
        let p = Geometry.padding
        
        let nameLabel = { _ -> UILabel in
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = "Your name:"
            label.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: -5, right: 0)
            
            contentView.addSubview(label)
            label.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
            
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 30),
                label.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor),
                label.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor),
                label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                
                { _ -> NSLayoutConstraint in
                    let width = NSLayoutConstraint(item: label, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 400)
                    width.priority = UILayoutPriorityDefaultHigh
                    return width
                }()
            ])
            
            return label
        }()
        
        ({ _ -> Void in
            let textField = nameTextField
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.delegate = self
            textField.text = UserDefaults.standard.string(forKey: UserDefaultsKeys.name) ?? ""
            textField.placeholder = "Enter your name"
            textField.backgroundColor = .white
            textField.borderStyle = .roundedRect
            textField.returnKeyType = .next
            textField.spellCheckingType = .no
            textField.autocorrectionType = .no
            textField.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: -p, right: 0)
            contentView.addSubview(textField)
            
            textField.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: .vertical)
            
            NSLayoutConstraint.activate([
                textField.topAnchor.constraint(equalTo: nameLabel.layoutMarginsGuide.bottomAnchor),
                textField.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
                textField.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
                textField.heightAnchor.constraint(equalToConstant: 50)
            ])
        })()
        
        let emailLabel = { _ -> UILabel in
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = "Your email:"
            label.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: -5, right: 0)
            
            contentView.addSubview(label)
            label.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
            
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: nameTextField.layoutMarginsGuide.bottomAnchor, constant: 20),
                label.leadingAnchor.constraint(equalTo: nameTextField.leadingAnchor),
                label.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor)
            ])
            
            return label
        }()
        
        ({ _ in
            emailTextField.translatesAutoresizingMaskIntoConstraints = false
            emailTextField.delegate = self
            emailTextField.text = UserDefaults.standard.string(forKey: UserDefaultsKeys.email) ?? ""
            emailTextField.placeholder = "yourname@website.com"
            emailTextField.keyboardType = .emailAddress
            emailTextField.backgroundColor = .white
            emailTextField.borderStyle = .roundedRect
            emailTextField.spellCheckingType = .no
            emailTextField.autocorrectionType = .no
            emailTextField.autocapitalizationType = .none
            
            contentView.addSubview(emailTextField)
            emailTextField.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: .vertical)
            
            NSLayoutConstraint.activate([
                emailTextField.topAnchor.constraint(equalTo: emailLabel.layoutMarginsGuide.bottomAnchor),
                emailTextField.leadingAnchor.constraint(equalTo: emailLabel.leadingAnchor),
                emailTextField.trailingAnchor.constraint(equalTo: emailLabel.trailingAnchor),
                emailTextField.heightAnchor.constraint(equalTo: nameTextField.heightAnchor)
            ])
        })()

        ({ _ in
            let p2 = Geometry.extendedPadding

            button.translatesAutoresizingMaskIntoConstraints = false
            button.setTitle("Submit", for: .normal)
            button.addTarget(self, action: #selector(submitEmail), for: .touchUpInside)
        
            contentView.addSubview(button)
            button.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
            button.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
            
            NSLayoutConstraint.activate([
                button.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: p2),
                button.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor),
                button.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor),
                button.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
            ])
        })()
        
        ({
            textView.delegate = self
            textView.translatesAutoresizingMaskIntoConstraints = false
            textView.backgroundColor = .clear
            textView.textColor = .gray6
            textView.textAlignment = .center
            textView.font = UIFont.preferredFont(forTextStyle: .footnote)
            textView.isEditable = false
            textView.isScrollEnabled = false
            textView.scrollsToTop = false
            
            contentView.addSubview(textView)
            
            textView.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
            
            NSLayoutConstraint.activate([
                textView.topAnchor.constraint(greaterThanOrEqualTo:button.bottomAnchor, constant: p),
                textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
            ])
            
            let tappableText:[[String: NSNumber]] = [
                ["By tapping \"Submit\" above, you agree to our\n": NSNumber(value:false)],
                ["Terms of Service": NSNumber(value:true)],
                [" and ": NSNumber(value:false)],
                ["Privacy Policy": NSNumber(value:true)],
                [" ": NSNumber(value:false)]
            ]
            
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = textView.textAlignment
            
            let attributes = [ NSFontAttributeName : textView.font!,
                               NSParagraphStyleAttributeName : paragraph ] as [String : Any]
            textView.applyTappableText(tappableText, withAttributes: attributes)
        })()

        ({ _ in
            let expandableView = UIView()
            expandableView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(expandableView)
            
            expandableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
            expandableViewHeightConstraint = NSLayoutConstraint(item: expandableView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
            expandableViewHeightConstraint.isActive = true
        })()
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(resignTextField)))
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        
        textView.delegate = nil
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
            track("Submitted email", properties: ["id" : user.identifier,
                                                  "name" : trimmedName,
                                                  "email": trimmedEmail])
        } else {
            track("Submitted blank email", properties: [ "id" : user.identifier,
                                                         "name" : trimmedName])
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
        guard textField == nameTextField else {
            textField.resignFirstResponder()
            return true
        }
        
        emailTextField.becomeFirstResponder()
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
