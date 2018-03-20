//
//  FavoriteButton.swift
//  screenshot
//
//  Created by Corey Werner on 3/8/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class FavoriteButton: BorderButton {
    fileprivate let favoriteControl = FavoriteControl()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let image = UIImage(color: .clear, size: CGSize(width: 26, height: 26))
        setImage(image, for: .normal)
        
        if let imageView = imageView {
            favoriteControl.translatesAutoresizingMaskIntoConstraints = false
            favoriteControl.isUserInteractionEnabled = false
            addSubview(favoriteControl)
            favoriteControl.centerXAnchor.constraint(equalTo: imageView.centerXAnchor).isActive = true
            favoriteControl.centerYAnchor.constraint(equalTo: imageView.centerYAnchor).isActive = true
        }
        
        addTarget(self, action: #selector(touchUpInsideAction), for: .touchUpInside)
    }
    
    override var isSelected: Bool {
        didSet {
            if favoriteControl.isSelected != isSelected {
                favoriteControl.isSelected = isSelected
            }
        }
    }
    
    @objc fileprivate func touchUpInsideAction() {
        favoriteControl.touchUpInsideAction()
        isSelected = favoriteControl.isSelected
    }
}
