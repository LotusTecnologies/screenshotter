//
//  TutorialEmailSlideView.swift
//  screenshot
//
//  Created by Corey Werner on 10/22/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit
import Appsee

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
    
    fileprivate let legalLinkTOS = "TOS"
    fileprivate let legalLinkPP = "PP"
    
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
        
        let linkTextColor: UIColor = .crazeGreen
        
        textView.delegate = self
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .clear
        textView.adjustsFontForContentSizeCategory = true
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.scrollsToTop = false
        textView.linkTextAttributes = [
            NSForegroundColorAttributeName: linkTextColor,
            NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue,
            NSUnderlineColorAttributeName: linkTextColor
        ]
        textView.attributedText = {
            let textViewFont: UIFont = .preferredFont(forTextStyle: .footnote)
            
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            
            func attributes(_ link: String? = nil) -> [String : Any] {
                var attributes: [String : Any] = [
                    NSFontAttributeName: textViewFont,
                    NSParagraphStyleAttributeName: paragraph
                ]
                
                if let link = link {
                    attributes[NSLinkAttributeName] = link
                }
                
                return attributes
            }
            
            return NSMutableAttributedString(segmentedString: "tutorial.email.legal", attributes: [
                attributes(),
                attributes(legalLinkTOS),
                attributes(),
                attributes(legalLinkPP),
                attributes()
                ])
        }()
        contentView.addSubview(textView)
        textView.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        textView.topAnchor.constraint(greaterThanOrEqualTo:button.bottomAnchor, constant: .extendedPadding).isActive = true
        textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        
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
        textField.tintColor = .crazeGreen
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
        
        let user = AnalyticsUser(name: name, email: email)
        AnalyticsTrackers.standard.identify(user)
        AnalyticsTrackers.branch.identify(user)
        
        if email.count > 0 {
            AnalyticsTrackers.standard.track(.submittedEmail, properties: user.analyticsProperties)
        }else{
            AnalyticsTrackers.standard.track(.submittedBlankEmail, properties: user.analyticsProperties)

        }

        UserDefaults.standard.set(user.identifier, forKey: UserDefaultsKeys.userID)
        UserDefaults.standard.synchronize()
        
        resignTextField()
        delegate?.tutorialEmailSlideViewDidComplete(self)
    }
    
    @objc private func resignTextField() {
        endEditing(true)
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

extension TutorialEmailSlideView : UITextViewDelegate {
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        
        switch URL.absoluteString {
        case legalLinkTOS:
            delegate?.tutorialEmailSlideViewDidTapTermsOfService(self)
            
        case legalLinkPP:
            delegate?.tutorialEmailSlideViewDidTapPrivacyPolicy(self)
            
        default:
            break
        }
        
        return false
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

extension TutorialEmailSlideView : TutorialSlideViewProtocol {
    func didEnterSlide() {
        Appsee.startScreen("Tutorial Email")
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)
    }
    
    func willLeaveSlide() {
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
