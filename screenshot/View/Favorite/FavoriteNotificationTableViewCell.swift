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
        
        contentView.backgroundColor = .gray6
        contentView.layoutMargins = UIEdgeInsets(top: .marginY, left: .containerPaddingX, bottom: .marginY, right: .containerPaddingX)
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setTitle("X", for: .normal)
        contentView.addSubview(closeButton)
        closeButton.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
        closeButton.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        let imageView = UIImageView(image: UIImage(named: ""))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        contentView.addSubview(imageView)
        imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4).isActive = true
        imageView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Get updated when your favorite items go on sale!"
        label.numberOfLines = 0
        label.textColor = .gray3
        contentView.addSubview(label)
        label.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
        label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: .padding).isActive = true
        label.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: .padding).isActive = true
        
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.backgroundColor = .crazeGreen
        continueButton.setTitle("Turn On Notifications", for: .normal)
        contentView.addSubview(continueButton)
        continueButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: .padding).isActive = true
        continueButton.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
        continueButton.centerXAnchor.constraint(equalTo: contentView.layoutMarginsGuide.centerXAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
