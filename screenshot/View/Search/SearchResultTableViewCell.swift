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
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        if let imageView = imageView {
            imageView.image = UIImage(named: "SearchResultGuide")
            imageView.contentMode = .scaleAspectFit
            
            productImageView.translatesAutoresizingMaskIntoConstraints = false
            productImageView.contentMode = .scaleAspectFit
            imageView.addSubview(productImageView)
            productImageView.topAnchor.constraint(greaterThanOrEqualTo: imageView.topAnchor, constant: 5).isActive = true
            productImageView.leadingAnchor.constraint(greaterThanOrEqualTo: imageView.leadingAnchor, constant: 5).isActive = true
            productImageView.bottomAnchor.constraint(lessThanOrEqualTo: imageView.bottomAnchor, constant: -5).isActive = true
            productImageView.trailingAnchor.constraint(lessThanOrEqualTo: imageView.trailingAnchor, constant: -5).isActive = true
            productImageView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor).isActive = true
            productImageView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor).isActive = true
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
