//
//  ActivityBadgeView.swift
//  screenshot
//
//  Created by Corey Werner on 1/2/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import UIKit

enum ActivityBadge {
    case heart
    case goldHeart
    case clock
}

class ActivityBadgeView: UIView {
    fileprivate let imageView = UIImageView()
    private let padding: CGFloat = 10
    
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
        addSubview(imageView)
        imageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: padding * 0.1).isActive = true
        
        syncBadgeImage()
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
    
    // MARK: Badge
    
    var badge: ActivityBadge = .heart {
        didSet {
            syncBadgeImage()
        }
    }
    
    fileprivate func syncBadgeImage() {
        switch badge {
        case .heart:
            imageView.image = UIImage(named: "ActivityBadgeHeart")
            
        case .goldHeart:
            imageView.image = UIImage(named: "ActivityBadgeGoldHeart")
            
        case .clock:
            imageView.image = UIImage(named: "ActivityBadgeClock")
        }
    }
}
