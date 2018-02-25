//
//  ShadowCollectionViewCell.swift
//  screenshot
//
//  Created by Corey Werner on 11/7/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation
import QuartzCore
import UIKit

class ShadowCollectionViewCell: UICollectionViewCell {
    private let shadowView = NotifyChangeView()
    private(set) var mainView = UIView()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        shadowView.translatesAutoresizingMaskIntoConstraints = false
        shadowView.layoutMargins = Shadow.basic.layoutMargins
        shadowView.notifySizeChange = { size in
            self.shadowView.layer.shadowPath = UIBezierPath(roundedRect: self.shadowView.bounds, cornerRadius: type(of: self).cornerRadius).cgPath
        }
        shadowView.layer.shadowColor = Shadow.basic.color.cgColor
        shadowView.layer.shadowOffset = type(of: self).shadowOffset
        shadowView.layer.shadowRadius = type(of: self).shadowRadius
        shadowView.layer.shadowOpacity = 1
        shadowView.layer.shadowPath = UIBezierPath(roundedRect: Shadow.basic.pathRect(bounds), cornerRadius: type(of: self).cornerRadius).cgPath
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
    
    // MARK: Layout
    
    private static let cornerRadius = CGFloat.defaultCornerRadius
    
    private static let shadowOffset = Shadow.basic.offset
    
    private static let shadowRadius = Shadow.basic.radius
    
    static let shadowInsets = Shadow.basic.insets
}
