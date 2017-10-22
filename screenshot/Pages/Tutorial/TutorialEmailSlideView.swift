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
    var expandableViewHeightConstraint: NSLayoutConstraint
    
    var keyboardFrame: CGRect
    var readyToSubmit: Bool
    
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
        
        emailTextField = { _ -> UITextField in
            let textField = UITextField()
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.delegate = self
            textField.text = UserDefaults.standard.string(forKey: UserDefaultsKeys.email) ?? ""
            textField.placeholder = "yourname@website.com"
            textField.keyboardType = .emailAddress
            textField.backgroundColor = .white
            textField.borderStyle = .roundedRect
            textField.spellCheckingType = .no
            textField.autocorrectionType = .no
            textField.autocapitalizationType = .none
            
            contentView.addSubview(textField)
            textField.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: .vertical)
            
            NSLayoutConstraint.activate([
                textField.topAnchor.constraint(equalTo: emailLabel.layoutMarginsGuide.bottomAnchor),
                textField.leadingAnchor.constraint(equalTo: emailLabel.leadingAnchor),
                textField.trailingAnchor.constraint(equalTo: emailLabel.trailingAnchor),
                textField.heightAnchor.constraint(equalTo: nameTextField.heightAnchor)
            ])
            
            return textField
        }()
        
        button = { _ -> MainButton in
            let p2 = Geometry.extendedPadding

            let button = MainButton(type: .custom)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setTitle("Submit", for: .normal)
            button.addTarget(self, action: #selector(submitEmail), for: .touchUpInside)
            
            contentView.addSubview(button)
            button.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
            
            NSLayoutConstraint.activate([
                button.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: p2),
                button.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor),
                button.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor),
                button.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
            ])
            
            return button
        }()
        
        textView = { _ -> TappableTextView in
            let textView = TappableTextView()
            return textView
            
            /*
 TappableTextView *textView = [[TappableTextView alloc] init];
 textView.delegate = self;
 textView.translatesAutoresizingMaskIntoConstraints = NO;
 textView.backgroundColor = [UIColor clearColor];
 textView.textColor = [UIColor gray6];
 textView.textAlignment = NSTextAlignmentCenter;
 textView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
 textView.editable = NO;
 textView.scrollEnabled = NO;
 textView.scrollsToTop = NO;
 [self.contentView addSubview:textView];
 [textView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
 [textView.topAnchor constraintGreaterThanOrEqualToAnchor:self.button.bottomAnchor constant:p].active = YES;
 [textView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor].active = YES;
 [textView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor].active = YES;
 [textView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor].active = YES;
 
 NSArray *tappableText = @[@{@"By tapping \"Submit\" above, you agree to our\n ": @NO},
 @{@"Terms of Service": @YES},
 @{@" and ": @NO},
 @{@"Privacy Policy": @YES},
 @{@" ": @NO}
 ];
 
 NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
 paragraph.alignment = textView.textAlignment;
 
 NSDictionary *attributes = @{NSFontAttributeName: textView.font,
 NSParagraphStyleAttributeName: paragraph
 };
 
 [textView applyTappableText:tappableText withAttributes:attributes];
 textView;
 });
 */
        }()
        
        /*
 UIView *expandableView = [[UIView alloc] init];
 expandableView.translatesAutoresizingMaskIntoConstraints = NO;
 [self.contentView addSubview:expandableView];
 [expandableView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor].active = YES;
 _expandableViewHeightConstraint = [NSLayoutConstraint constraintWithItem:expandableView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.f constant:0.f];
 self.expandableViewHeightConstraint.active = YES;
 
 [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resignTextField)]];
*/
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
        /*
 self.readyToSubmit = YES;
 
 NSString *trimmedName = [self.nameTextField.text trimWhitespace] ?: @"";
 NSString *trimmedEmail = [self.emailTextField.text isValidEmail] ? [self.emailTextField.text trimWhitespace] : nil;
 
 [[NSUserDefaults standardUserDefaults] setValue:trimmedName forKey:UserDefaultsKeys.name];
 [[NSUserDefaults standardUserDefaults] setValue:trimmedEmail forKey:UserDefaultsKeys.email];
 
 AnalyticsUser *user = [[AnalyticsUser alloc] initWithName:trimmedName email:trimmedEmail];
 [AnalyticsTrackers.standard identify:user];
 [AnalyticsTrackers.branch identify:user];
 
 
 if (trimmedEmail.length > 0) {
 [AnalyticsTrackers.standard track:@"Submitted email" properties:@{ @"id": user.identifier, @"name": trimmedName, @"email": trimmedEmail ?: @"" }];
 } else {
 [AnalyticsTrackers.standard track:@"Submitted blank email" properties:@{ @"id" : user.identifier, @"name": trimmedName }];
 }
 
 NSString *ambassadorUsername = [[NSUserDefaults standardUserDefaults] stringForKey:[UserDefaultsKeys ambasssadorUsername]];
 if (ambassadorUsername != nil) {
 [AnalyticsTrackers.standard track:@"Referring Ambassador" properties:@{ @"username": ambassadorUsername}];
 }
 
 [[NSUserDefaults standardUserDefaults] setValue:user.identifier forKey:UserDefaultsKeys.userID];
 [[NSUserDefaults standardUserDefaults] synchronize];
 
 [self informDelegateOfSubmittedEmailIfPossible];
 [self.emailTextField resignFirstResponder];

         */
        
    }
    
    private func resignTextField() {
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
    
}

extension TutorialEmailSlideView : UITextFieldDelegate {
    public func textFieldDidBeginEditing(_ textField: UITextField) {
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

//extension TutorialEmailSlideView : TappableTextViewDelegate {
    /*
 if (index == 1) {
 [self.delegate tutorialEmailSlideViewDidTapTermsOfService:self];
 
 } else if (index == 3) {
 [self.delegate tutorialEmailSlideViewDidTapPrivacyPolicy:self];
 }
*/
//}

extension TutorialEmailSlideView : TutorialSlideView {
    public func didEnterSlide() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardDidHide, object: nil)
    }
    
    public func willLeaveSlide() {
        NotificationCenter.default.removeObserver(self)
    }
}
