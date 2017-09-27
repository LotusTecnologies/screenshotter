//
//  FloatingActionButton.swift
//  screenshot
//
//  Created by Corey Werner on 9/27/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

class FloatingActionButton: UIButton {
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = bounds.size.width * 0.5
    }
}
