//
//  FavoriteControl.swift
//  screenshot
//
//  Created by Corey Werner on 9/4/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit
import Lottie
import Appsee

class FavoriteControl: UIControl {
    fileprivate let heartSwitch = LOTAnimatedSwitch(named: "FavoriteHeart")
    fileprivate var heartSwitchWidthConstraint: NSLayoutConstraint!
    fileprivate var animate = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addTarget(self, action: #selector(touchUpInsideAction), for: .touchUpInside)
        
        // The heart switch animation needs to be a subview since it's
        // view extends beyond the bounds of the desired tappable rect.
        heartSwitch.translatesAutoresizingMaskIntoConstraints = false
        heartSwitch.isUserInteractionEnabled = false
        addSubview(heartSwitch)
        heartSwitch.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        heartSwitch.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        heartSwitchWidthConstraint = heartSwitch.widthAnchor.constraint(equalToConstant: heartWidth(for: intrinsicContentSize.width))
        heartSwitchWidthConstraint.isActive = true
        heartSwitch.heightAnchor.constraint(equalTo: heartSwitch.widthAnchor).isActive = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        heartSwitchWidthConstraint.constant = heartWidth(for: bounds.size.width)
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 36, height: 36)
    }
    
    fileprivate func heartWidth(for width: CGFloat) -> CGFloat {
        return width * 2.28
    }
    
    override var isSelected: Bool {
        didSet {
            heartSwitch.setOn(isSelected, animated: animate)
        }
    }
    
    func touchUpInsideAction() {
        animate = true
        isSelected = !isSelected
        animate = false
        
        TapticHelper.peek()
    }
}
