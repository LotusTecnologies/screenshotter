//
//  ProfileAccountView.swift
//  screenshot
//
//  Created by Corey Werner on 6/7/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class ProfileAccountView: UIView {
    var isLoggedIn = false {
        didSet {
            loggedOutContainerView.isHidden = isLoggedIn
            loggedInContainerView.isHidden = !isLoggedIn
        }
    }
    
    private let loggedInContainerView = UIImageView()
    private let loggedOutContainerView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        loggedOutContainerView.translatesAutoresizingMaskIntoConstraints = false
        loggedOutContainerView.image = UIImage(named: "BrandGradientConfettiSmall")
        loggedOutContainerView.contentMode = .scaleAspectFill
        loggedOutContainerView.isHidden = isLoggedIn
        loggedOutContainerView.layoutMargins = UIEdgeInsetsMake(.padding, .padding, .padding, .padding)
        loggedOutContainerView.isUserInteractionEnabled = true
        addSubview(loggedOutContainerView)
        loggedOutContainerView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        loggedOutContainerView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        loggedOutContainerView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        loggedOutContainerView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
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
        
        loggedInContainerView.translatesAutoresizingMaskIntoConstraints = false
        loggedInContainerView.contentMode = .scaleAspectFill
        loggedInContainerView.backgroundColor = .gray
        loggedInContainerView.isHidden = !isLoggedIn
        loggedInContainerView.layoutMargins = UIEdgeInsetsMake(.padding, .padding, .padding, .padding)
        loggedInContainerView.isUserInteractionEnabled = true
        addSubview(loggedInContainerView)
        loggedInContainerView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        loggedInContainerView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        loggedInContainerView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        loggedInContainerView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
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
        avatarButton.topAnchor.constraint(greaterThanOrEqualTo: loggedInContainerView.layoutMarginsGuide.topAnchor).isActive = true
        avatarButton.leadingAnchor.constraint(equalTo: loggedInContainerView.layoutMarginsGuide.leadingAnchor).isActive = true
        avatarButton.bottomAnchor.constraint(lessThanOrEqualTo: loggedInContainerView.layoutMarginsGuide.bottomAnchor).isActive = true
        avatarButton.centerYAnchor.constraint(equalTo: loggedInContainerView.layoutMarginsGuide.centerYAnchor).isActive = true
        avatarButton.widthAnchor.constraint(equalToConstant: 90).isActive = true
        avatarButton.heightAnchor.constraint(equalTo: avatarButton.widthAnchor).isActive = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
