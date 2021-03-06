//
//  EmbossedView.swift
//  screenshot
//
//  Created by Corey Werner on 12/31/17.
//  Copyright (c) 2017 crazeapp. All rights reserved.
//

import UIKit
import SDWebImage

class EmbossedView : UIView {
    let imageView = UIImageView()
    let contentView = UIView()
    var placeholderImage: UIImage?
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layoutMargins = Shadow.basic.layoutMargins
        layer.shadowColor = Shadow.basic.color.cgColor
        layer.shadowOffset = Shadow.basic.offset
        layer.shadowRadius = Shadow.basic.radius
        layer.shadowOpacity = 1
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.layoutMargins = .zero
        contentView.layer.cornerRadius = .defaultCornerRadius
        contentView.layer.masksToBounds = true
        addSubview(contentView)
        contentView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        contentView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .white
        imageView.contentMode = .scaleAspectFit
        contentView.addSubview(imageView)
        imageView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if layer.shadowOpacity > 0 && !bounds.isEmpty {
            let shadowPathSize = layer.shadowPath?.boundingBox.size
            
            if shadowPathSize == nil || !bounds.size.equalTo(shadowPathSize!) {
                layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: contentView.layer.cornerRadius).cgPath
            }
        }
    }
    
    // MARK: Image
    
    override var contentMode: UIViewContentMode {
        set {
            imageView.contentMode = newValue
        }
        get {
            return imageView.contentMode
        }
    }
    
    var image: UIImage? {
        return imageView.image
    }
    
    func setImage(withURLString urlString: String?) {
        guard let urlString = urlString else {
            imageView.image = placeholderImage
            return
        }
        
        imageView.sd_setImage(with: URL(string: urlString), placeholderImage: placeholderImage, options: [.retryFailed, .highPriority], completed: nil)
    }
    
    func setImage(withData data: Data?) {
        guard let data = data else {
            imageView.image = placeholderImage
            return
        }
        
        imageView.image = UIImage(data: data)
    }
    
    func setImage(withNSData data: NSData?) {
        guard let data = data as Data? else {
            imageView.image = placeholderImage
            return
        }
        
        setImage(withData: data)
    }
}
