//
//  FacebookButton.swift
//  screenshot
//
//  Created by Corey Werner on 5/21/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class FacebookButton: UIButton {
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let backgroundImage = UIImage(named: "OnboardingFacebookButton")?.resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: 49, bottom: 0, right: 49))
        
        setBackgroundImage(backgroundImage, for: .normal)
        setTitleColor(.gray5, for: .highlighted)
        setTitle("facebook.register".localized, for: .normal)
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 48, bottom: 0, right: 40)
        layer.shadowColor = Shadow.basic.color.cgColor
        layer.shadowOffset = Shadow.basic.offset
        layer.shadowRadius = Shadow.basic.radius
        layer.shadowOpacity = 1
        heightAnchor.constraint(equalToConstant: 48).isActive = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 6).cgPath
    }
}
