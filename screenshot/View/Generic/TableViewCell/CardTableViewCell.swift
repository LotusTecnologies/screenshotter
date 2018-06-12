//
//  CardTableViewCell.swift
//  screenshot
//
//  Created by Corey Werner on 4/10/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit

class CardTableViewCell: TableViewCell {
    fileprivate let checkImageView = UIImageView()
    let cardView = UIView()
    let editButton = UIButton()
    let bottomView = UIView()
    
    private let checkImage = UIImage(named: "CardCellCheck")
    private let checkPlaceholderImage = UIImage(named: "CardCellCheckPlaceholder")
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        var layoutMargins = contentView.layoutMargins
        layoutMargins.top = .padding
        layoutMargins.bottom = .padding
        contentView.layoutMargins = layoutMargins
        
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = .white
        cardView.layoutMargins = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
        cardView.layer.borderColor = UIColor.cellBorder.cgColor
        cardView.layer.borderWidth = 2
        cardView.layer.cornerRadius = 8
        cardView.layer.masksToBounds = true
        contentView.addSubview(cardView)
        cardView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
        cardView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        checkImageView.translatesAutoresizingMaskIntoConstraints = false
        checkImageView.image = checkPlaceholderImage
        checkImageView.contentMode = .scaleAspectFit
        contentView.addSubview(checkImageView)
        checkImageView.setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)
        checkImageView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        checkImageView.trailingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: -.padding).isActive = true
        checkImageView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor).isActive = true
        
        editButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.contentEdgeInsets = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
        editButton.setTitle("generic.edit".localized, for: .normal)
        editButton.setTitleColor(.crazeGreen, for: .normal)
        cardView.addSubview(editButton)
        editButton.setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)
        editButton.setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)
        editButton.topAnchor.constraint(equalTo: cardView.topAnchor).isActive = true
        editButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor).isActive = true
        
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        bottomView.layoutMargins = UIEdgeInsets(top: .padding, left: 0, bottom: 0, right: 0)
        contentView.addSubview(bottomView)
        bottomView.topAnchor.constraint(equalTo: cardView.bottomAnchor).isActive = true
        bottomView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        bottomView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
        bottomView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        checkImageView.image = selected ? checkImage : checkPlaceholderImage
    }
}
