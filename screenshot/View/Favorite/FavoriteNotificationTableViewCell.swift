//
//  FavoriteNotificationTableViewCell.swift
//  screenshot
//
//  Created by Corey Werner on 7/15/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class FavoriteNotificationTableViewCell: UITableViewCell {
    let closeButton = UIButton()
    let continueButton = MainButton()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.backgroundColor = .background
        contentView.layoutMargins = UIEdgeInsets(top: .space1, left: .space2, bottom: .space1, right: .space2)
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(named: "FavoriteX"), for: .normal)
        closeButton.contentEdgeInsets = UIEdgeInsets(top: contentView.layoutMargins.top, left: contentView.layoutMargins.right, bottom: contentView.layoutMargins.top, right: contentView.layoutMargins.right)
        contentView.addSubview(closeButton)
        closeButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        closeButton.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        closeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        
        let imageView = UIImageView(image: UIImage(named: "FavoriteHeartMail"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        contentView.addSubview(imageView)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6).isActive = true
        imageView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Get updated when your favorite items go on sale!"
        label.numberOfLines = 0
        label.textColor = .gray3
        contentView.addSubview(label)
        label.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
        label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: .space1).isActive = true
        label.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor).isActive = true
        
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.backgroundColor = .crazeGreen
        continueButton.setTitle("Turn On Notifications", for: .normal)
        contentView.addSubview(continueButton)
        continueButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: .space1).isActive = true
        continueButton.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
        continueButton.centerXAnchor.constraint(equalTo: contentView.layoutMarginsGuide.centerXAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
