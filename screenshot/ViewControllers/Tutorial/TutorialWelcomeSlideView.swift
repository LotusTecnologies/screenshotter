//
//  TutorialWelcomeSlideView.swift
//  screenshot
//
//  Created by Jacob Relkin on 10/17/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

class TutorialWelcomeSlideView : HelperView {
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
        controlView.addSubview(button)
        button.topAnchor.constraint(equalTo: controlView.topAnchor).isActive = true
        button.bottomAnchor.constraint(equalTo: controlView.bottomAnchor, constant: -Geometry.extendedPadding).isActive = true
        button.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
