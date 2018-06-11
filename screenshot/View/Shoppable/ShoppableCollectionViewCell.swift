//
//  ShoppableCollectionViewCell.swift
//  screenshot
//
//  Created by Corey Werner on 11/15/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation
import UIKit

class ShoppableCollectionViewCell : UICollectionViewCell {
    private let imageView = UIImageView()
    private let borderColor = UIColor.gray8
    
    var image: UIImage? {
        set {
            imageView.sd_cancelCurrentImageLoad()
            imageView.image = newValue
        }
        get {
            return imageView.image
        }
    }
    var imageUrl:String? {
        didSet {
            imageView.sd_cancelCurrentImageLoad()
            imageView.image = nil
            if let imageUrl = imageUrl, let url = URL(string:imageUrl) {
                imageView.sd_setImage(with: url, completed: nil)
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.backgroundColor = .white
        layer.borderColor = borderColor.cgColor
        layer.borderWidth = 1.5
        layer.cornerRadius = .defaultCornerRadius
        layer.masksToBounds = true
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        contentView.addSubview(imageView)
        imageView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
    }
    
    override var isSelected: Bool {
        didSet {
            layer.borderColor = isSelected ? UIColor.crazeRed.cgColor : borderColor.cgColor
        }
    }
}
