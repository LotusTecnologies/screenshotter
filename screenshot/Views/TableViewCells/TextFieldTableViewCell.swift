//
//  TextFieldTableViewCell.swift
//  screenshot
//
//  Created by Corey Werner on 12/6/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

class TextFieldTableViewCell : UITableViewCell {
    let textField = UITextField()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.returnKeyType = .done
        textField.font = UIFont.preferredFont(forTextStyle: .body)
        textField.adjustsFontForContentSizeCategory = true
        contentView.addSubview(textField)
        textField.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        textField.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        textField.centerYAnchor.constraint(equalTo: contentView.layoutMarginsGuide.centerYAnchor).isActive = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Needed for adjusting the cell height correctly with dynamic type
        textLabel?.text = " "
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Needed when going from dynamic type accessibility size to normal size
        contentView.bringSubview(toFront: textField)
    }
}
