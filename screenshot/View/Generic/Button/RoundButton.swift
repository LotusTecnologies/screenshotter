//
//  RoundButton.swift
//  screenshot
//
//  Created by Corey Werner on 5/27/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class RoundButton: UIButton {
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.masksToBounds = true
        layer.cornerRadius = bounds.size.height * 0.5
    }
}
