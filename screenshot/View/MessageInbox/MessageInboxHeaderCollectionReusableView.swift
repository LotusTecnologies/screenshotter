//
//  MessageInboxHeaderCollectionReusableView.swift
//  Screenshop
//
//  Created by Jonathan Rose on 7/30/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class MessageInboxHeaderCollectionReusableView: UICollectionReusableView {
    
    let textLabel = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.textLabel.textColor = .gray3
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textLabel)
        textLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant:.padding).isActive = true
        textLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -.padding).isActive = true
        textLabel.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        textLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
