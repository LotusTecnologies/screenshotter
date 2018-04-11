//
//  CheckoutShippingTableViewCell.swift
//  screenshot
//
//  Created by Corey Werner on 4/11/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class CheckoutShippingTableViewCell: CardTableViewCell {
    let nameLabel = UILabel()
    let addressLabel = UILabel()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.textColor = .gray3
        nameLabel.font = .screenshopFont(.hindLight, size: 16)
        cardView.addSubview(nameLabel)
        nameLabel.topAnchor.constraint(equalTo: cardView.layoutMarginsGuide.topAnchor).isActive = true
        nameLabel.leadingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.leadingAnchor).isActive = true
        nameLabel.trailingAnchor.constraint(equalTo: editButton.leadingAnchor).isActive = true
        
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        addressLabel.textColor = .gray3
        addressLabel.font = .screenshopFont(.hindLight, size: 16)
        addressLabel.numberOfLines = 0
        cardView.addSubview(addressLabel)
        addressLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor).isActive = true
        addressLabel.leadingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.leadingAnchor).isActive = true
        addressLabel.bottomAnchor.constraint(equalTo: cardView.layoutMarginsGuide.bottomAnchor).isActive = true
        addressLabel.trailingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.trailingAnchor).isActive = true
    }
}
