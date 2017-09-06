//
//  FavoriteButton.swift
//  screenshot
//
//  Created by Corey Werner on 9/4/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

class FavoriteButton: UIButton {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let emptyImage = UIImage.init(named: "FavoriteHeartEmpty")
        let filledImage = UIImage.init(named: "FavoriteHeartFilled")
        
        self.setImage(emptyImage, for: .normal)
        self.setImage(filledImage, for: .selected)
        self.setImage(filledImage, for: [.selected, .highlighted])
        
        self.contentEdgeInsets = UIEdgeInsetsMake(6, 6, 6, 6)
        
        self.addTarget(self, action: #selector(touchUpInside), for: .touchUpInside)
    }
    
    func touchUpInside() {
        self.isSelected = !self.isSelected
    }
}
