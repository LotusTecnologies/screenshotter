//
//  ShareToDiscoverPrompt.swift
//  screenshot
//
//  Created by Jonathan Rose on 3/12/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import UIKit

class ShareToDiscoverPrompt : UIView {
    private let containerView:UIView
    let closeButton:UIButton
    let addButton:MainButton
    private let textLabel:UILabel
    
    override init(frame: CGRect) {
        containerView = UIView()
        closeButton = UIButton.init()
        textLabel = UILabel.init()
        addButton = MainButton.init()
        
        super.init(frame: frame)

        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = .defaultCornerRadius
        containerView.layer.shadowColor = Shadow.presentation.color.cgColor
        containerView.layer.shadowOffset = Shadow.presentation.offset
        containerView.layer.shadowRadius = Shadow.presentation.radius
        containerView.layer.shadowOpacity = 1
        self.addSubview(containerView)
        containerView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant:20).isActive = true
        containerView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant:-20).isActive = true
        containerView.topAnchor.constraint(equalTo: self.topAnchor, constant:20).isActive = true
        containerView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant:-20).isActive = true
        
        let closeImage = UIImage(named: "ShareToMatchsticksClose")
        
        closeButton.setImage(closeImage, for: .normal)
        self.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.centerXAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        closeButton.centerYAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        closeButton.widthAnchor.constraint(equalToConstant: closeImage?.size.width ?? 0).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: closeImage?.size.height ?? 0).isActive = true
        
        let verticalPadding: CGFloat = 22
        
        textLabel.text = "share_to_discover.text".localized
        textLabel.backgroundColor = .white
        textLabel.textAlignment = .center
        textLabel.numberOfLines = 0
        textLabel.font = UIFont.preferredFont(forTextStyle: .body)
        textLabel.adjustsFontForContentSizeCategory = true
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(textLabel)
        textLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: .padding).isActive = true
        textLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -.padding).isActive = true
        textLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: verticalPadding).isActive = true
        
        addButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(addButton)
        addButton.setTitle("share_to_discover.add_button".localized, for: .normal)
        addButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        addButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -verticalPadding).isActive = true
        addButton.topAnchor.constraint(equalTo: textLabel.bottomAnchor, constant: verticalPadding).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        containerView.layer.shadowPath = UIBezierPath.init(roundedRect: containerView.bounds, cornerRadius: containerView.layer.cornerRadius).cgPath
    }
}
