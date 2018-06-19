//
//  ButtonTableViewCell.swift
//  screenshot
//
//  Created by Jonathan Rose on 6/18/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class ButtonTableViewCell: UITableViewCell {

    var button = MainButton()
    override func awakeFromNib() {
        super.awakeFromNib()
        button.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(button)
        button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        button.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        button.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        button.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)


    }

}
