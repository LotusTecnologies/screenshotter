//
//  SearchResultTableViewCell.swift
//  Screenshop
//
//  Created by Corey Werner on 8/2/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class SearchResultTableViewCell: UITableViewCell {
    let productImageView = UIImageView()
    let titleLabel = UILabel()
    let descriptionLabel = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let imageViewWidth: CGFloat = 70
        let layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        separatorInset = UIEdgeInsets(top: 0, left: (layoutMargins.left * 2) + imageViewWidth, bottom: 0, right: 0)
        
        productImageView.translatesAutoresizingMaskIntoConstraints = false
        productImageView.contentMode = .scaleAspectFit
        contentView.addSubview(productImageView)
        productImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: layoutMargins.top).isActive = true
        productImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: layoutMargins.left).isActive = true
        productImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -layoutMargins.bottom).isActive = true
        productImageView.widthAnchor.constraint(equalToConstant: imageViewWidth).isActive = true
        productImageView.heightAnchor.constraint(equalToConstant: imageViewWidth).isActive = true
        
        let verticalLabelSpace: CGFloat = 3
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        contentView.addSubview(titleLabel)
        titleLabel.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: layoutMargins.top).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: productImageView.trailingAnchor, constant: layoutMargins.left).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -verticalLabelSpace).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -layoutMargins.right).isActive = true
        
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.font = .systemFont(ofSize: 15, weight: .regular)
        contentView.addSubview(descriptionLabel)
        descriptionLabel.topAnchor.constraint(equalTo: contentView.centerYAnchor, constant: verticalLabelSpace).isActive = true
        descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor).isActive = true
        descriptionLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -layoutMargins.bottom).isActive = true
        descriptionLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
