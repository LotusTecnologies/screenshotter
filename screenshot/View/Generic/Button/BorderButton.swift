//
//  BorderButton.swift
//  screenshot
//
//  Created by Corey Werner on 3/8/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class BorderButton: UIButton {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setTitleColor(.crazeRed, for: .normal)
        contentEdgeInsets = UIEdgeInsets(top: .padding / 1.8, left: .padding, bottom: .padding / 1.8, right: .padding)
        adjustsImageWhenHighlighted = false
        titleLabel?.font = UIFont(screenshopName: .hindMedium, size: UIFont.buttonFontSize)
        layer.borderWidth = 1
        layer.cornerRadius = .defaultCornerRadius
    }
    
    override func setTitleColor(_ color: UIColor?, for state: UIControlState) {
        super.setTitleColor(color, for: state)
        syncBorderColor()
        
        if state == .normal {
            let darkerColor = color?.darker(by: 14)
            
            super.setTitleColor(darkerColor, for: .highlighted)
            super.setTitleColor(darkerColor, for: [.highlighted, .selected])
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            syncBorderColor()
        }
    }
    
    override var isSelected: Bool {
        didSet {
            syncBorderColor()
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            syncBorderColor()
        }
    }
    
    fileprivate func syncBorderColor() {
        layer.borderColor = titleColor(for: state)?.cgColor
    }
}
