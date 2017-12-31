//
//  FavoritesTableViewCell.swift
//  screenshot
//
//  Created by Corey Werner on 12/27/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

class FavoritesTableViewCell : UITableViewCell {
    fileprivate let screenshotImageView = UIImageView()
    
    var imageData: NSData? {
        didSet {
            if let imageData = imageData as Data? {
                screenshotImageView.image = UIImage(data: imageData)
                
            } else {
                screenshotImageView.image = nil
            }
        }
    }
    
    fileprivate let label = UILabel()
    
    override var textLabel: UILabel? {
        return label
    }
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        // TODO: do math for setting the shadow around the image and not the image view (ie. landscape image)
        screenshotImageView.translatesAutoresizingMaskIntoConstraints = false
        screenshotImageView.contentMode = .scaleAspectFit
        contentView.addSubview(screenshotImageView)
        screenshotImageView.topAnchor.constraint(greaterThanOrEqualTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
        screenshotImageView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        screenshotImageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
        screenshotImageView.widthAnchor.constraint(equalTo: contentView.layoutMarginsGuide.heightAnchor, multiplier: Screenshot.ratio.width).isActive = true
        
        let centerView = UIView()
        centerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(centerView)
        centerView.topAnchor.constraint(greaterThanOrEqualTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
        centerView.leadingAnchor.constraint(equalTo: screenshotImageView.trailingAnchor, constant: .padding).isActive = true
        centerView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
        centerView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        centerView.centerYAnchor.constraint(equalTo: contentView.layoutMarginsGuide.centerYAnchor).isActive = true
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = .green
        contentView.addSubview(label)
        label.topAnchor.constraint(equalTo: centerView.topAnchor).isActive = true
        label.leadingAnchor.constraint(equalTo: centerView.leadingAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: centerView.bottomAnchor).isActive = true
        label.trailingAnchor.constraint(equalTo: centerView.trailingAnchor).isActive = true
    }
}
