//
//  OnboardingDetailsViewController.swift
//  screenshot
//
//  Created by Corey Werner on 5/24/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

protocol OnboardingDetailsViewControllerDelegate: NSObjectProtocol {
    func onboardingDetailsViewControllerDidSkip(_ viewController: OnboardingDetailsViewController)
    func onboardingDetailsViewControllerDidContinue(_ viewController: OnboardingDetailsViewController)
}

class OnboardingDetailsView: UIView {
    enum Gender: Int {
        case female
        case male
        
        var localized: String {
            switch self {
            case .female:
                return "products.options.gender.female".localized
            case .male:
                return "products.options.gender.male".localized
            }
        }
    }
    
    enum Size: Int {
        case adult
        case child
        case plus
        
        var localized: String {
            switch self {
            case .adult:
                return "products.options.size.adult".localized
            case .child:
                return "products.options.size.child".localized
            case .plus:
                return "products.options.size.plus".localized
            }
        }
    }
    
    let scrollView = UIScrollView()
    let userButton = RoundButton()
    let nameTextField = UnderlineTextField()
    private let preferenceLabel = UILabel()
    let genderControl = SegmentedDropDownControl()
    let sizeControl = SegmentedDropDownControl()
    let continueButton = MainButton()
    let skipButton = UIButton()
    
    var activePreferenceTopOffset: CGFloat {
        let rect = preferenceLabel.superview?.convert(preferenceLabel.frame, to: scrollView)
        let topOffset = (rect?.origin.y ?? 0) - .padding
        
        if #available(iOS 11.0, *) {
            return topOffset - scrollView.adjustedContentInset.top
        }
        else {
            return topOffset - scrollView.contentInset.top
        }
    }
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        if let backgroundImage = UIImage(named: "BrandConfettiFullBackground") {
            scrollView.backgroundColor = UIColor(patternImage: backgroundImage)
        }
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.layoutMargins = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
        addSubview(scrollView)
        scrollView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        let contentView = ContentContainerView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        contentView.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        let defaultUserImage = UIImage(named: "DefaultUser")
        
        userButton.translatesAutoresizingMaskIntoConstraints = false
        userButton.setBackgroundImage(defaultUserImage, for: .selected)
        userButton.setBackgroundImage(defaultUserImage, for: [.selected, .highlighted])
        userButton.setImage(UIImage(named: "UserCamera"), for: .selected)
        userButton.isSelected = true
        userButton.layer.borderColor = UIColor.gray6.cgColor
        userButton.layer.borderWidth = 2
        scrollView.addSubview(userButton)
        userButton.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: .extendedPadding).isActive = true
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
        nameTextField.topAnchor.constraint(equalTo: userButton.bottomAnchor, constant: UIDevice.is320w ? 0 : .padding).isActive = true
        nameTextField.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        nameTextField.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
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
        
        let genderItem = SegmentedDropDownItem(pickerItems: [
            Gender.female.localized,
            Gender.male.localized
            ])
        genderItem.placeholderTitle = "Gender"
        
        let genderItem2 = SegmentedDropDownItem(pickerItems: [
            Gender.female.localized,
            Gender.male.localized
            ])
        genderItem2.placeholderTitle = "Gender 2"
        
        genderControl.translatesAutoresizingMaskIntoConstraints = false
        genderControl.items = [genderItem, genderItem2]
        contentView.addSubview(genderControl)
        genderControl.topAnchor.constraint(equalTo: preferenceLabel.bottomAnchor, constant: .padding).isActive = true
        genderControl.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        genderControl.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        genderControl.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        let sizeItem = SegmentedDropDownItem(pickerItems: [
            Size.child.localized,
            Size.adult.localized,
            Size.plus.localized
            ])
        sizeItem.placeholderTitle = "Size"
        
        sizeControl.translatesAutoresizingMaskIntoConstraints = false
        sizeControl.items = [sizeItem]
        contentView.addSubview(sizeControl)
        sizeControl.topAnchor.constraint(equalTo: genderControl.bottomAnchor, constant: .padding).isActive = true
        sizeControl.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        sizeControl.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.setTitle("generic.save".localized, for: .normal)
        contentView.addSubview(continueButton)
        continueButton.topAnchor.constraint(equalTo: sizeControl.bottomAnchor, constant: .extendedPadding).isActive = true
        continueButton.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        continueButton.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
        continueButton.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        let skipLayoutGuide = UILayoutGuide()
        scrollView.addLayoutGuide(skipLayoutGuide)
        skipLayoutGuide.topAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        
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
        scrollView.addSubview(skipButton)
        skipButton.topAnchor.constraint(equalTo: skipLayoutGuide.bottomAnchor, constant: .padding).isActive = true
        skipButton.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -scrollView.layoutMargins.bottom).isActive = true
        skipButton.centerXAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.centerXAnchor).isActive = true
    }
}

class OnboardingDetailsViewController: UIViewController {
    weak var delegate: OnboardingDetailsViewControllerDelegate?
    
    var name: String? {
        return _view.nameTextField.text
    }
    
    var gender: String? {
        return _view.genderControl.items.first?.selectedPickerItem
    }
    
    var size: String? {
        return _view.sizeControl.items.first?.selectedPickerItem
    }
    
    // MARK: View
    
    private let navigationBar = UINavigationBar()
    
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
        
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        navigationBar.delegate = self
        navigationBar.items = [navigationItem]
        view.addSubview(navigationBar)
        
        if #available(iOS 11.0, *) {
            navigationBar.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor).isActive = true
        }
        else {
            navigationBar.layoutMarginsGuide.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        }
        
        navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        navigationBar.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        
        _view.userButton.addTarget(self, action: #selector(userAction), for: .touchUpInside)
        
        _view.nameTextField.delegate = self
        
        _view.continueButton.addTarget(self, action: #selector(continueAction), for: .touchUpInside)
        _view.skipButton.addTarget(self, action: #selector(skipAction), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        _view.addGestureRecognizer(tapGesture)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        var contentInset = _view.scrollView.contentInset
        var scrollIndicatorInsets = _view.scrollView.scrollIndicatorInsets
        
        if #available(iOS 11.0, *) {
            contentInset.top = navigationBar.bounds.height
            scrollIndicatorInsets.top = navigationBar.bounds.height
        }
        else {
            contentInset.top = navigationBar.frame.maxY
            scrollIndicatorInsets.top = navigationBar.frame.maxY
        }
        
        _view.scrollView.contentInset = contentInset
        _view.scrollView.scrollIndicatorInsets = scrollIndicatorInsets
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Actions
    
    @objc private func userAction() {
        
    }
    
    @objc private func continueAction() {
        delegate?.onboardingDetailsViewControllerDidContinue(self)
    }
    
    @objc private func skipAction() {
        delegate?.onboardingDetailsViewControllerDidSkip(self)
    }
    
    // MARK: Keyboard
    
    @objc private func keyboardWillShowNotification(_ notification: Notification) {
        var contentInset = _view.scrollView.contentInset
        var scrollIndicatorInsets = _view.scrollView.scrollIndicatorInsets
        
        if let keyboardRect = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            contentInset.bottom = keyboardRect.height
            scrollIndicatorInsets.bottom = keyboardRect.height
        }
        
        _view.scrollView.contentInset = contentInset
        _view.scrollView.scrollIndicatorInsets = scrollIndicatorInsets
        
        if _view.genderControl.isFirstResponder || _view.sizeControl.isFirstResponder {
            var contentOffset = _view.scrollView.contentOffset
            contentOffset.y = _view.activePreferenceTopOffset
            _view.scrollView.contentOffset = contentOffset
        }
    }
    
    @objc private func keyboardWillHideNotification(_ notification: Notification) {
        var contentInset = _view.scrollView.contentInset
        contentInset.bottom = 0
        _view.scrollView.contentInset = contentInset
        
        var scrollIndicatorInsets = _view.scrollView.scrollIndicatorInsets
        scrollIndicatorInsets.bottom = 0
        _view.scrollView.scrollIndicatorInsets = scrollIndicatorInsets
    }
    
    @objc fileprivate func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension OnboardingDetailsViewController: UINavigationBarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}

extension OnboardingDetailsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
