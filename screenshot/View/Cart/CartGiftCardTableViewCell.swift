//
//  CartGiftCardTableViewCell.swift
//  screenshot
//
//  Created by Corey Werner on 5/9/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class CartGiftCardTableViewCell: UITableViewCell {
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.layoutMargins = UIEdgeInsetsMake(.padding, 20, .padding, 20)
        contentView.backgroundColor = .crazeGreen
        
        let imageView = UIImageView(image: UIImage(named: "giftCard25USD"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        contentView.addSubview(imageView)
        imageView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 90).isActive = true
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "cart.gift_card".localized
        label.textColor = .white
        label.font = UIFont.screenshopFont(.hind, textStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        contentView.addSubview(label)
        label.setContentHuggingPriority(.required, for: .vertical)
        label.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
        label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: .padding).isActive = true
        label.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
        label.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
    }
}
