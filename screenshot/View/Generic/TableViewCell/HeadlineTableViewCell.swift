//
//  HeadlineTableViewCell.swift
//  screenshot
//
//  Created by Jonathan Rose on 6/18/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class HeadlineTableViewCell: UITableViewCell {

    let headline = UILabel()
    let byline = UILabel()
    override func awakeFromNib() {
        super.awakeFromNib()
        let background = UIImageView.init(image: UIImage.init(named: "confetti"))
        background.contentMode = .scaleAspectFill
        background.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(background)
        background.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        background.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        background.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        background.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        
        
        headline.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(headline)
        headline.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        headline.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        headline.topAnchor.constraint(equalTo: contentView.topAnchor, constant:.extendedPadding).isActive = true
        
        byline.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(byline)
        byline.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        byline.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        byline.topAnchor.constraint(equalTo: headline.bottomAnchor, constant:.extendedPadding).isActive = true
        byline.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
