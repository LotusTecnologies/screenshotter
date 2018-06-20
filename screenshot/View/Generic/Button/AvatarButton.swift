//
//  AvatarButton.swift
//  screenshot
//
//  Created by Corey Werner on 6/18/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class AvatarButton: RoundButton {
    private let borderColor: UIColor = .gray6
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setBackgroundImage(UIImage(named: "DefaultUser"), for: .selected)
        setBackgroundImage(UIImage(named: "DefaultUser"), for: [.selected, .highlighted])
        setImage(UIImage(named: "UserCamera"), for: .selected)
        setImage(UIImage(named: "UserCamera"), for: [.selected, .highlighted])
        
        adjustsImageWhenHighlighted = false
        layer.borderColor = borderColor.cgColor
        layer.borderWidth = 2
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        layoutIfNeeded()
        subviews.first?.contentMode = .scaleAspectFill
    }
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                layer.borderColor = UIColor.crazeGreen.cgColor
            }
            else {
                layer.borderColor = borderColor.cgColor
            }
        }
    }
}
