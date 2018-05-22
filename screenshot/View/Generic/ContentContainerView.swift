//
//  ContentContainerView.swift
//  screenshot
//
//  Created by Corey Werner on 5/21/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class ContentContainerView: UIView {
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let insets: UIEdgeInsets
        
        if UIDevice.is320w {
            insets = UIEdgeInsets(top: .padding * 1.5, left: .padding, bottom: .padding * 1.5, right: .padding)
        }
        else {
            insets = UIEdgeInsets(top: .padding * 2, left: .padding * 1.5, bottom: .padding * 2, right: .padding * 1.5)
        }
        
        backgroundColor = .white
        layoutMargins = insets
        layer.shadowOpacity = 1
        layer.cornerRadius = .defaultCornerRadius
        layer.shadowRadius = Shadow.content.radius
        layer.shadowOffset = Shadow.content.offset
        layer.shadowColor = Shadow.content.color.cgColor
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
    }
}
