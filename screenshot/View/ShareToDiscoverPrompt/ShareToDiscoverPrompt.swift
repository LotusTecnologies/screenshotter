//
//  ShareToDiscoverPrompt.swift
//  screenshot
//
//  Created by Jonathan Rose on 3/12/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import UIKit

protocol ShareToDiscoverPromptDelegate {
    func shareToDiscoverPromptDidClose(_ shareToDiscoverPrompt:ShareToDiscoverPrompt)
    func shareToDiscoverPromptPressAdd(_ shareToDiscoverPrompt:ShareToDiscoverPrompt)
}

class ShareToDiscoverPrompt : UIView {
    private let containerView:UIView
    private let closeButton:UIButton
    private let addButton:MainButton
    private let textLabel:UILabel
    
    var delegate:ShareToDiscoverPromptDelegate?
    
    override init(frame: CGRect) {
        
        containerView = UIView()
        closeButton = UIButton.init()
        textLabel = UILabel.init()
        addButton = MainButton.init()
        
        super.init(frame: frame)

        containerView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(containerView)

        containerView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant:20).isActive = true
        containerView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant:-20).isActive = true
        containerView.topAnchor.constraint(equalTo: self.topAnchor, constant:20).isActive = true
        containerView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant:-20).isActive = true

        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = .defaultCornerRadius
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 3
        containerView.layer.shadowOpacity = 0.5
        
        
        
        closeButton.setImage(UIImage.init(named: "Close"), for: .normal)
        self.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.centerXAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        closeButton.centerYAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        closeButton.widthAnchor.constraint(equalToConstant: 40.0).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: 40.0).isActive = true
        closeButton.addTarget(self, action: #selector(didPressClose(_:)), for: .touchUpInside)

        
        textLabel.text = "share_to_discover.text".localized
        textLabel.backgroundColor = .white
        textLabel.textAlignment = .center
        textLabel.numberOfLines = 3
        textLabel.font =  UIFont.preferredFont(forTextStyle: .body)
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(textLabel)
        textLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20).isActive = true
        textLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20).isActive = true
        textLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20).isActive = true
        
        addButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(addButton)
        addButton.setTitle("share_to_discover.add_button".localized, for: .normal)
        addButton.backgroundColor = .crazeRed
        addButton.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.5).isActive = true
        addButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        addButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        addButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20).isActive = true
        let attachToText = addButton.topAnchor.constraint(equalTo: textLabel.bottomAnchor, constant: 20) // if have to break a constrant this is the one to break
        attachToText.priority = UILayoutPriorityDefaultHigh
        attachToText.isActive = true

        addButton.addTarget(self, action: #selector(didPressAdd(_:)), for: .touchUpInside)

    }
    @IBAction func didPressAdd(_ sender:Any) {
        self.delegate?.shareToDiscoverPromptPressAdd(self)
    }
    
    @IBAction func didPressClose(_ sender:Any) {
        self.delegate?.shareToDiscoverPromptDidClose(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        containerView.layer.shadowPath = UIBezierPath.init(roundedRect: containerView.bounds, cornerRadius: containerView.layer.cornerRadius).cgPath
    }
}
