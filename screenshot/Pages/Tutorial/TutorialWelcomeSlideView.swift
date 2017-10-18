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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        titleLabel.attributedText = titleLabelAttributedText
        subtitleLabel.text = "Any fashion picture you screenshot becomes shoppable in the app"
        contentImage = UIImage(named: "TutorialWelcomeScreenshopIcon")
        
        let button = MainButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Get Started", for: .normal)
        button.backgroundColor = .crazeGreen
        button.addTarget(self, action: #selector(getStartedButtonWasTapped), for: .touchUpInside)
        contentView.addSubview(button)
        button.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, constant: -Geometry.extendedPadding()).isActive = true
        button.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
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
