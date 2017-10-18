//
//  TutorialWelcomeSlideView.swift
//  screenshot
//
//  Created by Jacob Relkin on 10/17/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

class TutorialWelcomeSlideView : TutorialBaseSlideView {
    var getStartedButtonTapped: (() -> Void)?
    
    lazy var iconImageView = { _ -> UIImageView in
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "AppIcon60x60")
        return imageView
    }()
    
    lazy var getStartedButton = { _ -> UIButton in
        let button = UIButton()
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Get Started", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: UIFont.buttonFontSize)
        
        button.layer.cornerRadius = 5
        button.layer.masksToBounds = true
        button.backgroundColor = .crazeGreen
        button.addTarget(self, action: #selector(getStartedButtonWasTapped), for: .touchUpInside)
        
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupViews()
    }
    
    // MARK: -
    
    func setupViews() {
        titleLabel.attributedText = titleLabelAttributedText
        subtitleLabel.text = "Any fashion picture you screenshot becomes shoppable in the app"
        
        contentView.addSubview(getStartedButton)
        contentView.addSubview(iconImageView)
        
        NSLayoutConstraint.activate([
            iconImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 75),
            iconImageView.heightAnchor.constraint(equalToConstant: 90),
            iconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 90),
            
            getStartedButton.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 75),
            getStartedButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 0),
            getStartedButton.heightAnchor.constraint(equalToConstant: 60),
            getStartedButton.widthAnchor.constraint(equalToConstant: 240)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func getStartedButtonWasTapped() {
        getStartedButtonTapped?()
    }
    
    // MARK: - Private
    
    private var titleLabelAttributedText: NSAttributedString {
        let attachment = NSTextAttachment()
        attachment.image = UIImage(named: "Logo20h")?.withRenderingMode(.alwaysTemplate)
        
        let prefix = "Welcome to "
        let attachmentString = NSAttributedString(attachment: attachment)
        let attachmentRange = NSMakeRange(prefix.count - 1, attachmentString.length)
        let mutableString = NSMutableAttributedString(string: prefix)
        
        mutableString.append(attachmentString)
        mutableString.addAttributes([ NSForegroundColorAttributeName : UIColor.crazeRed ], range: attachmentRange)
        
        return mutableString
    }
}
