//
//  OnboardingDetailsViewController.swift
//  screenshot
//
//  Created by Corey Werner on 5/24/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class OnboardingDetailsView: UIScrollView, UINavigationBarDelegate {
    enum Gender: String {
        case female = "Female"
        case male   = "Male"
    }
    
    enum Size: String {
        case child = "Child"
        case adult = "Adult"
        case plus  = "Plus"
    }
    
    let navigationItem = UINavigationItem()
    let userButton = RoundButton()
    let nameTextField = UnderlineTextField()
    
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
        
        let navigationBar = UINavigationBar()
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        navigationBar.delegate = self
        navigationBar.items = [navigationItem]
        addSubview(navigationBar)
        navigationBar.topAnchor.constraint(equalTo: topAnchor).isActive = true
        navigationBar.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        navigationBar.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        navigationBar.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        
        let contentView = ContentContainerView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        let defaultUserImage = UIImage(named: "DefaultUser")
        
        userButton.translatesAutoresizingMaskIntoConstraints = false
        userButton.setBackgroundImage(defaultUserImage, for: .selected)
        userButton.setBackgroundImage(defaultUserImage, for: [.selected, .highlighted])
        userButton.setImage(UIImage(named: "UserCamera"), for: .selected)
        userButton.isSelected = true
        userButton.layer.borderColor = UIColor.gray6.cgColor
        userButton.layer.borderWidth = 2
        addSubview(userButton)
        userButton.topAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: .extendedPadding).isActive = true
        userButton.widthAnchor.constraint(equalToConstant: 90).isActive = true
        userButton.heightAnchor.constraint(equalTo: userButton.widthAnchor).isActive = true
        userButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        userButton.centerYAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        nameTextField.placeholder = "Your Name" // TODO: localize
        nameTextField.autocorrectionType = .no
        nameTextField.autocapitalizationType = .words
        nameTextField.spellCheckingType = .no
        contentView.addSubview(nameTextField)
        nameTextField.topAnchor.constraint(equalTo: userButton.bottomAnchor, constant: .padding).isActive = true
        nameTextField.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        nameTextField.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        let preferenceLabel = UILabel()
        preferenceLabel.translatesAutoresizingMaskIntoConstraints = false
        preferenceLabel.text = "PREFERENCES"
        preferenceLabel.font = .screenshopFont(.quicksandBold, size: 16)
        preferenceLabel.textColor = .gray1
        preferenceLabel.textAlignment = .center
        preferenceLabel.minimumScaleFactor = 0.7
        preferenceLabel.adjustsFontSizeToFitWidth = true
        preferenceLabel.baselineAdjustment = .alignCenters
        contentView.addSubview(preferenceLabel)
        preferenceLabel.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: .extendedPadding).isActive = true
        preferenceLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        preferenceLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        preferenceLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        
        let genderItems = [Gender.female.rawValue, Gender.male.rawValue]
        
        let genderItem = SegmentedDropDownItem(pickerItems: genderItems)
        genderItem.placeholderTitle = "Gender"
        
        let genderControl = SegmentedDropDownControl()
        genderControl.translatesAutoresizingMaskIntoConstraints = false
        genderControl.items = [genderItem]
        contentView.addSubview(genderControl)
        genderControl.topAnchor.constraint(equalTo: preferenceLabel.bottomAnchor, constant: .padding).isActive = true
        genderControl.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        genderControl.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        genderControl.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layoutMargins = _layoutMargins
    }
    
    // MARK: Navigation Bar
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}

class OnboardingDetailsViewController: UIViewController {
    var classForView: OnboardingDetailsView.Type {
        return OnboardingDetailsView.self
    }
    
    var _view: OnboardingDetailsView {
        return view as! OnboardingDetailsView
    }
    
    override func loadView() {
        view = classForView.self.init()
    }
    
    // MARK: Life Cycle
    
    override var title: String? {
        didSet {
            _view.navigationItem.title = title
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        title = "Your Details"
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShowNotification(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHideNotification(_:)), name: .UIKeyboardWillHide, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _view.nameTextField.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        _view.addGestureRecognizer(tapGesture)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Keyboard
    
    @objc private func keyboardWillShowNotification(_ notification: Notification) {
        var contentInset = _view.contentInset
        var scrollIndicatorInsets = _view.scrollIndicatorInsets
        
        if let keyboardRect = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            contentInset.bottom = keyboardRect.height
            scrollIndicatorInsets.bottom = keyboardRect.height
        }
        
        _view.contentInset = contentInset
        _view.scrollIndicatorInsets = scrollIndicatorInsets
    }
    
    @objc private func keyboardWillHideNotification(_ notification: Notification) {
        var contentInset = _view.contentInset
        contentInset.top = 0
        contentInset.bottom = 0
        _view.contentInset = contentInset
        
        var scrollIndicatorInsets = _view.scrollIndicatorInsets
        scrollIndicatorInsets.bottom = 0
        _view.scrollIndicatorInsets = scrollIndicatorInsets
    }
    
    @objc fileprivate func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension OnboardingDetailsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
