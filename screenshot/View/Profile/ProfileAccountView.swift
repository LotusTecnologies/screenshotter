//
//  ProfileAccountView.swift
//  screenshot
//
//  Created by Corey Werner on 6/7/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

protocol ProfileAccountViewDelegate: NSObjectProtocol {
    func profileAccountViewWantsToContract(_ view: ProfileAccountView)
    func profileAccountViewWantsToExpand(_ view: ProfileAccountView)
}

class ProfileAccountView: UIView {
    weak var delegate: ProfileAccountViewDelegate?
    
    let contentView = UIView()
    private let loggedInContainerView = UIImageView()
    private let loggedInControl = UIControl()
    private let nameLabel = UILabel()
    private let nameTextField = UnderlineTextField()
    private let emailLabel = UILabel()
    private let emailTextField = UnderlineTextField()
    private let continueButton = MainButton()
    private let loggedOutContainerView = UIImageView()
    
    private var heightConstraint: NSLayoutConstraint?
    private var contentViewHeightConstraint: NSLayoutConstraint?
    private var contractedConstraints: [NSLayoutConstraint] = []
    private var expandedConstraints: [NSLayoutConstraint] = []
    
    var isLoggedIn = false {
        didSet {
            loggedOutContainerView.isHidden = isLoggedIn
            loggedInContainerView.isHidden = !isLoggedIn
        }
    }
    
    var name: String? {
        set {
            nameLabel.text = newValue
            nameTextField.text = newValue
        }
        get {
            return nameTextField.text
        }
    }
    var email: String? {
        set {
            emailLabel.text = newValue
            emailTextField.text = newValue
        }
        get {
            return emailTextField.text
        }
    }
    
    let minHeight: CGFloat = 150
    var maxHeight: CGFloat = 150
    
    var isExpanded = false {
        didSet {
            let constant = isExpanded ? maxHeight : minHeight
            heightConstraint?.constant = constant
            contentViewHeightConstraint?.constant = constant
            
            if isExpanded {
                NSLayoutConstraint.deactivate(contractedConstraints)
                NSLayoutConstraint.activate(expandedConstraints)
                
                loggedInContainerView.sendSubview(toBack: loggedInControl)
            }
            else {
                NSLayoutConstraint.deactivate(expandedConstraints)
                NSLayoutConstraint.activate(contractedConstraints)
                
                loggedInContainerView.bringSubview(toFront: loggedInControl)
            }
            
            let contractedAlpha: CGFloat = isExpanded ? 0 : 1
            nameLabel.alpha = contractedAlpha
            emailLabel.alpha = contractedAlpha
            
            let expandedAlpha: CGFloat = isExpanded ? 1 : 0
            nameTextField.alpha = expandedAlpha
            emailTextField.alpha = expandedAlpha
            continueButton.alpha = expandedAlpha
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        heightConstraint = heightAnchor.constraint(equalToConstant: minHeight)
        heightConstraint?.isActive = true
        
        // The contentView should expand independently so the animation is smooth in a table view
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.clipsToBounds = true
        addSubview(contentView)
        contentView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        contentView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        contentViewHeightConstraint = contentView.heightAnchor.constraint(equalToConstant: minHeight)
        contentViewHeightConstraint?.isActive = true
        
        setupLoggedOutViews()
        setupLoggedInViews()
        
        contentView.addSubview(BorderView(edge: .bottom))
        
        NSLayoutConstraint.activate(contractedConstraints)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLoggedOutViews() {
        loggedOutContainerView.translatesAutoresizingMaskIntoConstraints = false
        loggedOutContainerView.image = UIImage(named: "ProfileHeaderLoggedOut")
        loggedOutContainerView.contentMode = .scaleAspectFill
        loggedOutContainerView.isHidden = isLoggedIn
        loggedOutContainerView.layoutMargins = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
        loggedOutContainerView.isUserInteractionEnabled = true
        contentView.addSubview(loggedOutContainerView)
        loggedOutContainerView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        loggedOutContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        loggedOutContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        loggedOutContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        
        let loggedOutVerticalGuide = UILayoutGuide()
        loggedOutContainerView.addLayoutGuide(loggedOutVerticalGuide)
        loggedOutVerticalGuide.topAnchor.constraint(greaterThanOrEqualTo: loggedOutContainerView.layoutMarginsGuide.topAnchor).isActive = true
        loggedOutVerticalGuide.bottomAnchor.constraint(lessThanOrEqualTo: loggedOutContainerView.layoutMarginsGuide.bottomAnchor).isActive = true
        loggedOutVerticalGuide.centerYAnchor.constraint(equalTo: loggedOutContainerView.layoutMarginsGuide.centerYAnchor).isActive = true
        
        let loggedOutLabel = UILabel()
        loggedOutLabel.translatesAutoresizingMaskIntoConstraints = false
        loggedOutLabel.text = "Log in for exclusive benefits!"
        loggedOutLabel.textColor = .white
        loggedOutLabel.font = .screenshopFont(.hind, size: 22)
        loggedOutContainerView.addSubview(loggedOutLabel)
        loggedOutLabel.topAnchor.constraint(equalTo: loggedOutVerticalGuide.topAnchor).isActive = true
        loggedOutLabel.leadingAnchor.constraint(greaterThanOrEqualTo: loggedOutContainerView.layoutMarginsGuide.leadingAnchor).isActive = true
        loggedOutLabel.trailingAnchor.constraint(lessThanOrEqualTo: loggedOutContainerView.layoutMarginsGuide.trailingAnchor).isActive = true
        loggedOutLabel.centerXAnchor.constraint(equalTo: loggedOutContainerView.layoutMarginsGuide.centerXAnchor).isActive = true
        
        let loggedOutButton = MainButton()
        loggedOutButton.translatesAutoresizingMaskIntoConstraints = false
        loggedOutButton.backgroundColor = .white
        loggedOutButton.setTitle("Log In or Sign Up", for: .normal)
        loggedOutButton.setTitleColor(.gray2, for: .normal)
        loggedOutContainerView.addSubview(loggedOutButton)
        loggedOutButton.topAnchor.constraint(equalTo: loggedOutLabel.bottomAnchor, constant: .padding).isActive = true
        loggedOutButton.bottomAnchor.constraint(equalTo: loggedOutVerticalGuide.bottomAnchor).isActive = true
        loggedOutButton.centerXAnchor.constraint(equalTo: loggedOutContainerView.layoutMarginsGuide.centerXAnchor).isActive = true
    }
    
    private func setupLoggedInViews() {
        loggedInContainerView.translatesAutoresizingMaskIntoConstraints = false
        loggedInContainerView.image = UIImage(named: "ProfileHeaderLoggedIn")
        loggedInContainerView.contentMode = .scaleAspectFill
        loggedInContainerView.backgroundColor = .white
        loggedInContainerView.isHidden = !isLoggedIn
        loggedInContainerView.layoutMargins = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
        loggedInContainerView.isUserInteractionEnabled = true
        contentView.addSubview(loggedInContainerView)
        loggedInContainerView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        loggedInContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        loggedInContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        loggedInContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        
        let hasAvatar = false
        
        let avatarButton = RoundButton()
        avatarButton.translatesAutoresizingMaskIntoConstraints = false
        avatarButton.setBackgroundImage(UIImage(named: "DefaultUser"), for: .selected)
        avatarButton.setBackgroundImage(UIImage(named: "DefaultUser"), for: [.selected, .highlighted])
        avatarButton.setImage(UIImage(named: "UserCamera"), for: .selected)
        avatarButton.setImage(UIImage(named: "UserCamera"), for: [.selected, .highlighted])
        avatarButton.isSelected = !hasAvatar
        avatarButton.layer.borderColor = UIColor.gray6.cgColor
        avatarButton.layer.borderWidth = 2
        loggedInContainerView.addSubview(avatarButton)
        avatarButton.widthAnchor.constraint(equalToConstant: 90).isActive = true
        avatarButton.heightAnchor.constraint(equalTo: avatarButton.widthAnchor).isActive = true
        
        contractedConstraints += [
            avatarButton.topAnchor.constraint(greaterThanOrEqualTo: loggedInContainerView.layoutMarginsGuide.topAnchor),
            avatarButton.leadingAnchor.constraint(equalTo: loggedInContainerView.layoutMarginsGuide.leadingAnchor),
            avatarButton.bottomAnchor.constraint(lessThanOrEqualTo: loggedInContainerView.layoutMarginsGuide.bottomAnchor),
            avatarButton.centerYAnchor.constraint(equalTo: loggedInContainerView.layoutMarginsGuide.centerYAnchor)
        ]
        expandedConstraints += [
            avatarButton.topAnchor.constraint(equalTo: loggedInContainerView.topAnchor, constant: .extendedPadding),
            avatarButton.centerXAnchor.constraint(equalTo: loggedInContainerView.layoutMarginsGuide.centerXAnchor)
        ]
        
        let labelsLayoutGuide = UILayoutGuide()
        loggedInContainerView.addLayoutGuide(labelsLayoutGuide)
        labelsLayoutGuide.topAnchor.constraint(greaterThanOrEqualTo: loggedInContainerView.layoutMarginsGuide.topAnchor).isActive = true
        labelsLayoutGuide.bottomAnchor.constraint(lessThanOrEqualTo: loggedInContainerView.layoutMarginsGuide.bottomAnchor).isActive = true
        labelsLayoutGuide.centerYAnchor.constraint(equalTo: loggedInContainerView.layoutMarginsGuide.centerYAnchor).isActive = true
        
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        nameTextField.placeholder = "Name"
        nameTextField.alpha = 0
        nameTextField.delegate = self
        nameTextField.autocorrectionType = .no
        nameTextField.autocapitalizationType = .words
        nameTextField.spellCheckingType = .no
        loggedInContainerView.addSubview(nameTextField)
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .screenshopFont(.quicksandMedium, size: 22)
        nameLabel.textColor = .gray2
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.5
        nameLabel.baselineAdjustment = .alignCenters
        loggedInContainerView.addSubview(nameLabel)
        
        contractedConstraints += [
            nameTextField.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            nameTextField.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            nameTextField.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            
            nameLabel.topAnchor.constraint(equalTo: labelsLayoutGuide.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: avatarButton.trailingAnchor, constant: .padding),
            nameLabel.trailingAnchor.constraint(equalTo: loggedInContainerView.layoutMarginsGuide.trailingAnchor)
        ]
        expandedConstraints += [
            nameTextField.topAnchor.constraint(equalTo: avatarButton.bottomAnchor, constant: .extendedPadding),
            nameTextField.leadingAnchor.constraint(equalTo: loggedInContainerView.leadingAnchor, constant: .padding * 1.5),
            nameTextField.trailingAnchor.constraint(equalTo: loggedInContainerView.trailingAnchor, constant: -.padding * 1.5),
            
            nameLabel.leadingAnchor.constraint(equalTo: nameTextField.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor),
            nameLabel.centerYAnchor.constraint(equalTo: nameTextField.centerYAnchor),
        ]
        
        emailTextField.translatesAutoresizingMaskIntoConstraints = false
        emailTextField.placeholder = "Email"
        emailTextField.alpha = 0
        emailTextField.delegate = self
        emailTextField.autocorrectionType = .no
        emailTextField.autocapitalizationType = .none
        emailTextField.spellCheckingType = .no
        emailTextField.keyboardType = .emailAddress
        loggedInContainerView.addSubview(emailTextField)
        
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        emailLabel.font = .screenshopFont(.quicksand, size: 18)
        emailLabel.textColor = .gray2
        emailLabel.adjustsFontSizeToFitWidth = true
        emailLabel.minimumScaleFactor = 0.5
        emailLabel.baselineAdjustment = .alignCenters
        loggedInContainerView.addSubview(emailLabel)
        
        contractedConstraints += [
            emailTextField.leadingAnchor.constraint(equalTo: emailLabel.leadingAnchor),
            emailTextField.trailingAnchor.constraint(equalTo: emailLabel.trailingAnchor),
            emailTextField.centerYAnchor.constraint(equalTo: emailLabel.centerYAnchor),
            
            emailLabel.topAnchor.constraint(equalTo: nameLabel.lastBaselineAnchor, constant: .padding / 2),
            emailLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            emailLabel.bottomAnchor.constraint(equalTo: labelsLayoutGuide.bottomAnchor),
            emailLabel.trailingAnchor.constraint(equalTo: loggedInContainerView.layoutMarginsGuide.trailingAnchor)
        ]
        expandedConstraints += [
            emailTextField.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: .padding),
            emailTextField.leadingAnchor.constraint(equalTo: nameTextField.leadingAnchor),
            emailTextField.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor),
            
            emailLabel.leadingAnchor.constraint(equalTo: nameTextField.leadingAnchor),
            emailLabel.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor),
            emailLabel.centerYAnchor.constraint(equalTo: nameTextField.centerYAnchor)
        ]
        
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.backgroundColor = .crazeGreen
        continueButton.alpha = 0
        continueButton.isExclusiveTouch = true
        continueButton.setTitle("Done", for: .normal)
        continueButton.addTarget(self, action: #selector(loggedInContinueAction), for: .touchUpInside)
        loggedInContainerView.addSubview(continueButton)
        continueButton.centerXAnchor.constraint(equalTo: loggedInContainerView.layoutMarginsGuide.centerXAnchor).isActive = true
        
        contractedConstraints += [
            continueButton.bottomAnchor.constraint(equalTo: loggedInContainerView.layoutMarginsGuide.bottomAnchor, constant: 80) // Constant large enough to not show the button
        ]
        expandedConstraints += [
            continueButton.bottomAnchor.constraint(equalTo: loggedInContainerView.bottomAnchor, constant: -.extendedPadding)
        ]
        
        loggedInControl.translatesAutoresizingMaskIntoConstraints = false
        loggedInControl.addTarget(self, action: #selector(loggedInControlAction), for: .touchUpInside)
        loggedInContainerView.addSubview(loggedInControl)
        loggedInControl.topAnchor.constraint(equalTo: loggedInContainerView.topAnchor).isActive = true
        loggedInControl.leadingAnchor.constraint(equalTo: loggedInContainerView.leadingAnchor).isActive = true
        loggedInControl.bottomAnchor.constraint(equalTo: loggedInContainerView.bottomAnchor).isActive = true
        loggedInControl.trailingAnchor.constraint(equalTo: loggedInContainerView.trailingAnchor).isActive = true
    }
    
    @objc private func loggedInContinueAction() {
        delegate?.profileAccountViewWantsToContract(self)
    }
    
    @objc private func loggedInControlAction() {
        if isExpanded {
            loggedInContainerView.endEditing(true)
        }
        else {
            delegate?.profileAccountViewWantsToExpand(self)
        }
    }
}

extension ProfileAccountView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == nameTextField {
            name = textField.text
        }
        else if textField == emailTextField {
            email = textField.text
        }
    }
}
