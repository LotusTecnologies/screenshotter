//
//  FavoriteBadgeView.swift
//  screenshot
//
//  Created by Corey Werner on 1/2/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation

class FavoriteBadgeView : UIView {
    fileprivate let imageView = UIImageView()
    fileprivate let image = UIImage(named: "FavoriteGoldHeart")
    private let padding = CGFloat(10)
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        clipsToBounds = true
        isUserInteractionEnabled = false
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = syncedImage()
        addSubview(imageView)
        imageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: padding * 0.1).isActive = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = bounds.size.height / 2
    }
    
    override var intrinsicContentSize: CGSize {
        var size = imageView.image?.size ?? .zero
        size.width += padding
        size.height += padding
        return size
    }
    
    override var tintColor: UIColor! {
        didSet {
            imageView.tintColor = tintColor
            imageView.image = syncedImage()
        }
    }
    
    private func syncedImage() -> UIImage? {
        if tintColor == .clear {
            return image
            
        } else {
            return image?.withRenderingMode(.alwaysTemplate)
        }
    }
}
