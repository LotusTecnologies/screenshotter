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
        
        let inset: CGFloat = UIDevice.is320w ? .padding * 2 : .padding
        
        backgroundColor = .white
        layoutMargins = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
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
