//
//  FloatingActionButton.swift
//  screenshot
//
//  Created by Corey Werner on 9/27/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation
import UIKit

class FloatingActionButton: UIButton {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.showsTouchWhenHighlighted = true
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 3
        layer.shadowOpacity = 0.5
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = bounds.size.width * 0.5
        layer.shadowPath = UIBezierPath(ovalIn: bounds).cgPath
    }
}
