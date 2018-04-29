//
//  TutorialEmailSlideView.swift
//  screenshot
//
//  Created by Corey Werner on 10/22/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit
import Appsee

protocol TutorialEmailSlideViewControllerDelegate : class {
    func tutorialEmailSlideViewDidComplete(_ slideView: TutorialEmailSlideViewController)
    func tutorialEmailSlideViewDidTapTermsOfService(_ slideView: TutorialEmailSlideViewController)
    func tutorialEmailSlideViewDidTapPrivacyPolicy(_ slideView: TutorialEmailSlideViewController)
}

public class TutorialEmailSlideViewController : UIViewController {
    weak var delegate: TutorialEmailSlideViewControllerDelegate?
    fileprivate let helperView = HelperView()

    fileprivate let nameTextField = TutorialEmailSlideTextField()
    fileprivate let emailTextField = TutorialEmailSlideTextField()
    fileprivate let textView = TappableTextView()
    fileprivate let button = MainButton()
    
    fileprivate let legalLinkTOS = "TOS"
    fileprivate let legalLinkPP = "PP"
    
    // MARK: Life Cycle
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        helperView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(helperView)
        helperView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        helperView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        helperView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        helperView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true

        helperView.layoutMargins = {
            var extraTop = CGFloat(0)
            var extraBottom = CGFloat(0)
            
            if !UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory {
                if UIDevice.is812h || UIDevice.is736h {
                    extraTop = .extendedPadding
                    extraBottom = .extendedPadding
                    
                } else if UIDevice.is667h {
                    extraTop = .padding
                    extraBottom = .padding
                }
            }
            
            let paddingX: CGFloat = .padding
            
            
            return UIEdgeInsets(top: .padding + extraTop, left: paddingX, bottom: .padding + extraBottom, right: paddingX)
        }()
        
        let contentView = helperView.contentView
        
        helperView.titleLabel.text = "tutorial.email.title".localized
        helperView.subtitleLabel.text = "tutorial.email.detail".localized
        
        let paddingView1 = UIView()
        paddingView1.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(paddingView1)
        paddingView1.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        let paddingView1HeightConstraint = paddingView1.heightAnchor.constraint(equalToConstant: .extendedPadding)
        paddingView1HeightConstraint.priority = UILayoutPriority.defaultLow
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
        paddingView2HeightConstraint.priority = UILayoutPriority.defaultLow
        paddingView2HeightConstraint.isActive = true
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("generic.submit".localized, for: .normal)
        button.addTarget(self, action: #selector(submitEmail), for: .touchUpInside)
        contentView.addSubview(button)
        button.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        button.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
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
            NSAttributedStringKey.foregroundColor.rawValue: linkTextColor,
            NSAttributedStringKey.underlineStyle.rawValue: NSUnderlineStyle.styleSingle.rawValue,
            NSAttributedStringKey.underlineColor.rawValue: linkTextColor
        ]
        textView.attributedText = {
            let textViewFont: UIFont = .preferredFont(forTextStyle: .footnote)
            
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            
            func attributes(_ link: String? = nil) -> [NSAttributedStringKey : Any] {
                var attributes: [NSAttributedStringKey : Any] = [
                    NSAttributedStringKey.font: textViewFont,
                    NSAttributedStringKey.paragraphStyle: paragraph
                ]
                
                if let link = link {
                    attributes[NSAttributedStringKey.link] = link
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
        textView.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        textView.topAnchor.constraint(greaterThanOrEqualTo:button.bottomAnchor, constant: .extendedPadding).isActive = true
        textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        
        helperView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(resignTextField)))
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
        textField.setContentHuggingPriority(UILayoutPriority.defaultLow, for: .vertical)
        textField.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        
        textField.addSubview(BorderView(edge: .bottom))
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
        self.view.endEditing(true)
    }
    
    // MARK: Keyboard
    
    @objc func keyboardWillShow(_ notification: NSNotification) {
        guard self.view.window != nil, let value = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        
        self.helperView.scrollInset = UIEdgeInsets(top: 0, left: 0, bottom: value.cgRectValue.size.height, right: 0)
    }
    
    @objc func keyboardWillHide(_ notification: NSNotification) {
        guard self.view.window != nil else {
            return
        }
        
        if let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber {
            UIView.animate(withDuration: duration.doubleValue) {
                self.helperView.scrollInset = .zero
            }
            
        } else {
            self.helperView.scrollInset = .zero
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Appsee.startScreen("Tutorial Email")
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)

    }
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
      
    }
}

extension TutorialEmailSlideViewController : UITextViewDelegate {
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

extension TutorialEmailSlideViewController : UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameTextField {
            emailTextField.becomeFirstResponder()
            
        } else {
            textField.resignFirstResponder()
        }
        
        return true
    }
}


private class TutorialEmailSlideTextField : UITextField {
    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height *= 1.5
        return size
    }
}
