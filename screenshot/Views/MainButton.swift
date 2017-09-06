//
//  MainButton.swift
//  screenshot
//
//  Created by Corey Werner on 9/4/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit

class MainButton: UIButton {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.crazeRed
        self.contentEdgeInsets = UIEdgeInsetsMake(16, 16, 16, 16)
        self.layer.cornerRadius = 9
    }
    
    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.width = max(size.width, 160)
        return size
    }
}
