//
//  ProductView.swift
//  screenshot
//
//  Created by Corey Werner on 12/31/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation
import SDWebImage

class ProductView : UIView {
    fileprivate let imageView = UIImageView()
    fileprivate let placeholderImage = UIImage(named: "DefaultProduct")
    
    var imageURL: String? {
        didSet {
            if let imageString = imageURL {
                imageView.sd_setImage(with: URL(string: imageString), placeholderImage: placeholderImage, options: [.retryFailed, .highPriority], completed: nil)
                
            } else {
                imageView.image = placeholderImage
            }
        }
    }
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layoutMargins = Shadow.basic.layoutMargins
        layer.shadowColor = Shadow.basic.color.cgColor
        layer.shadowOffset = Shadow.basic.offset
        layer.shadowRadius = Shadow.basic.radius
        layer.shadowOpacity = 1
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = .defaultCornerRadius
        addSubview(imageView)
        imageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if layer.shadowOpacity > 0 && !bounds.isEmpty {
            let shadowPathSize = layer.shadowPath?.boundingBox.size
            
            if shadowPathSize == nil || !bounds.size.equalTo(shadowPathSize!) {
                layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: imageView.layer.cornerRadius).cgPath
            }
        }
    }
}
