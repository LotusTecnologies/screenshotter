//
//  RegisterViewController.swift
//  screenshot
//
//  Created by Corey Werner on 5/21/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class RegisterView: AuthorizeContentScrollView {
    let dealsSwitch = UISwitch()
    let skipButton = UIButton()
    let legalTextView = TappableTextView()
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // Force the height to be at least that of the scroll view
        let verticalLayoutView = UIView()
        verticalLayoutView.translatesAutoresizingMaskIntoConstraints = false
        verticalLayoutView.isHidden = true
        addSubview(verticalLayoutView)
        verticalLayoutView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        verticalLayoutView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        verticalLayoutView.heightAnchor.constraint(greaterThanOrEqualTo: heightAnchor).isActive = true
        
        let skipLayoutGuide = UILayoutGuide()
        addLayoutGuide(skipLayoutGuide)
        skipLayoutGuide.topAnchor.constraint(equalTo: contentView.bottomAnchor, constant: .padding).isActive = true
        
        let skipImage = UIImage(named: "OnboardingArrow")
        
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        skipButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: .padding, bottom: 6, right: .padding)
        skipButton.setTitle("generic.skip".localized, for: .normal)
        skipButton.setTitleColor(.gray3, for: .normal)
        skipButton.setTitleColor(.gray5, for: .highlighted)
        skipButton.setImage(skipImage, for: .normal)
        skipButton.setImage(skipImage?.withRenderingMode(.alwaysTemplate), for: .highlighted)
        skipButton.tintColor = skipButton.titleColor(for: .highlighted)
        skipButton.alignImageRight()
        skipButton.adjustInsetsForImage(withPadding: 6)
        addSubview(skipButton)
        skipButton.topAnchor.constraint(greaterThanOrEqualTo: skipLayoutGuide.topAnchor).isActive = true
        skipButton.bottomAnchor.constraint(lessThanOrEqualTo: skipLayoutGuide.bottomAnchor).isActive = true
        skipButton.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor).isActive = true
        skipButton.centerYAnchor.constraint(equalTo: skipLayoutGuide.centerYAnchor).isActive = true
        
        let dealsLayoutGuide = UILayoutGuide()
        addLayoutGuide(dealsLayoutGuide)
        dealsLayoutGuide.centerXAnchor.constraint(equalTo: contentView.layoutMarginsGuide.centerXAnchor).isActive = true
        dealsLayoutGuide.widthAnchor.constraint(lessThanOrEqualToConstant: 320 - (.padding * 2)).isActive = true
        
        let dealsLabel = UILabel()
        dealsLabel.translatesAutoresizingMaskIntoConstraints = false
        dealsLabel.text = "Send me emails about exclusive offers, sales and new features."
        dealsLabel.textColor = .gray3
        dealsLabel.numberOfLines = 0
        dealsLabel.font = .screenshopFont(.hindLight, size: 16)
        addSubview(dealsLabel)
        dealsLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        dealsLabel.topAnchor.constraint(equalTo: skipLayoutGuide.bottomAnchor, constant: .padding).isActive = true
        dealsLabel.leadingAnchor.constraint(equalTo: dealsLayoutGuide.leadingAnchor).isActive = true
        
        dealsSwitch.translatesAutoresizingMaskIntoConstraints = false
        dealsSwitch.isOn = true
        dealsSwitch.onTintColor = .crazeGreen
        addSubview(dealsSwitch)
        dealsSwitch.leadingAnchor.constraint(equalTo: dealsLabel.trailingAnchor, constant: .padding).isActive = true
        dealsSwitch.trailingAnchor.constraint(equalTo: dealsLayoutGuide.trailingAnchor).isActive = true
        dealsSwitch.centerYAnchor.constraint(equalTo: dealsLabel.centerYAnchor).isActive = true
        
        legalTextView.translatesAutoresizingMaskIntoConstraints = false
        legalTextView.backgroundColor = .clear
        legalTextView.adjustsFontForContentSizeCategory = true
        legalTextView.isEditable = false
        legalTextView.isScrollEnabled = false
        legalTextView.scrollsToTop = false
        legalTextView.linkTextAttributes = [
            NSAttributedStringKey.foregroundColor.rawValue: UIColor.crazeGreen,
            NSAttributedStringKey.underlineStyle.rawValue: NSUnderlineStyle.styleSingle.rawValue,
            NSAttributedStringKey.underlineColor.rawValue: UIColor.crazeGreen
        ]
        legalTextView.attributedText = legalAttributedText()
        addSubview(legalTextView)
        legalTextView.setContentCompressionResistancePriority(.required, for: .vertical)
        legalTextView.topAnchor.constraint(equalTo: dealsLabel.lastBaselineAnchor, constant: .padding).isActive = true
        legalTextView.leadingAnchor.constraint(equalTo: dealsLayoutGuide.leadingAnchor).isActive = true
        legalTextView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -_layoutMargins.bottom).isActive = true
        legalTextView.trailingAnchor.constraint(equalTo: dealsLayoutGuide.trailingAnchor).isActive = true
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
        
        // TODO: localized copy needs to say 'Sign up' not 'Submit'
        return NSMutableAttributedString(segmentedString: "tutorial.email.legal", attributes: [
            attributes(),
            attributes(legalLinkTOS),
            attributes(),
            attributes(legalLinkPP),
            attributes()
            ])
    }
}

class RegisterViewController: AuthorizeContentViewController {
    override var classForView: AuthorizeContentScrollView.Type {
        return RegisterView.self
    }
    
    override var _view: RegisterView {
        return view as! RegisterView
    }
    
    var skipButton: UIButton {
        return _view.skipButton
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _view.facebookLoginButton.textCopy = .register
        _view.continueButton.setTitle("Sign Up", for: .normal)
        _view.legalTextView.delegate = self
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
            present(viewController, animated: true, completion: nil)
        }
    }
    
    fileprivate func presentPrivacyPolicy() {
        Analytics.trackOnboardingSubmittedEmailPrivacy()
        
        if let viewController = LegalViewControllerFactory.privacyPolicyViewController() {
            present(viewController, animated: true, completion: nil)
        }
    }
}
