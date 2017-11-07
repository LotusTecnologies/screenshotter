//
//  ShadowCollectionViewCell.swift
//  screenshot
//
//  Created by Corey Werner on 11/7/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation
import QuartzCore

class ShadowCollectionViewCell: UICollectionViewCell {
    private let shadowView = UIView()
    private(set) var mainView = UIView()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        shadowView.translatesAutoresizingMaskIntoConstraints = false
        shadowView.layoutMargins = {
            var margins = type(of: self).shadowInsets
            margins.top = -margins.top
            margins.left = -margins.left
            margins.bottom = -margins.bottom
            margins.right = -margins.right
            return margins
        }()
        shadowView.layer.shadowColor = Shadow.basic.color.cgColor;
        shadowView.layer.shadowOffset = type(of: self).shadowOffset
        shadowView.layer.shadowRadius = type(of: self).shadowRadius
        shadowView.layer.shadowOpacity = 1
        shadowView.layer.shadowPath = {
            var rect = UIEdgeInsetsInsetRect(bounds, type(of: self).shadowInsets)
            rect.origin = .zero
            return UIBezierPath(roundedRect: rect, cornerRadius: type(of: self).cornerRadius).cgPath
        }()
        contentView.addSubview(shadowView)
        shadowView.layoutMarginsGuide.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        shadowView.layoutMarginsGuide.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        shadowView.layoutMarginsGuide.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        shadowView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        
        mainView.translatesAutoresizingMaskIntoConstraints = false
        mainView.backgroundColor = .white
        mainView.layer.cornerRadius = type(of: self).cornerRadius
        mainView.layer.masksToBounds = true
        contentView.addSubview(mainView)
        mainView.topAnchor.constraint(equalTo: shadowView.topAnchor).isActive = true
        mainView.leadingAnchor.constraint(equalTo: shadowView.leadingAnchor).isActive = true
        mainView.bottomAnchor.constraint(equalTo: shadowView.bottomAnchor).isActive = true
        mainView.trailingAnchor.constraint(equalTo: shadowView.trailingAnchor).isActive = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if !shadowView.bounds.equalTo(.zero),
            let shadowPath = shadowView.layer.shadowPath,
            !shadowPath.boundingBox.size.equalTo(shadowView.bounds.size)
        {
            shadowView.layer.shadowPath = UIBezierPath(roundedRect: shadowView.bounds, cornerRadius: type(of: self).cornerRadius).cgPath
        }
    }
    
    // MARK: Layout
    
    private static let cornerRadius = Geometry.defaultCornerRadius
    
    private static let shadowOffset = Shadow.basic.offset
    
    private static let shadowRadius = Shadow.basic.radius
    
    static var shadowInsets: UIEdgeInsets {
        let shadowInset = shadowRadius * 2
        
        var shadowInsets = UIEdgeInsets.zero
        shadowInsets.top = shadowInset - shadowOffset.height
        shadowInsets.left = shadowInset
        shadowInsets.bottom = shadowInset + shadowOffset.height
        shadowInsets.right = shadowInset
        return shadowInsets
    }
}
