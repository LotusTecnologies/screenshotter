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
            imageView.layoutMargins = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
            
            productImageView.translatesAutoresizingMaskIntoConstraints = false
            productImageView.contentMode = .scaleAspectFit
            imageView.addSubview(productImageView)
            productImageView.topAnchor.constraint(greaterThanOrEqualTo: imageView.layoutMarginsGuide.topAnchor).isActive = true
            productImageView.leadingAnchor.constraint(greaterThanOrEqualTo: imageView.layoutMarginsGuide.leadingAnchor).isActive = true
            productImageView.bottomAnchor.constraint(lessThanOrEqualTo: imageView.layoutMarginsGuide.bottomAnchor).isActive = true
            productImageView.trailingAnchor.constraint(lessThanOrEqualTo: imageView.layoutMarginsGuide.trailingAnchor).isActive = true
            productImageView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor).isActive = true
            productImageView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor).isActive = true
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
