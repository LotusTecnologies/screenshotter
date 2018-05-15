//
//  BlankHeaderConfettiContentTemplate.swift
//  screenshot
//
//  Created by Corey Werner on 5/15/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class BlankHeaderConfettiContentTemplate: UIView {
    let headerLayoutGuide = UILayoutGuide()
    
    /// Only needed for iOS 10
    var autoAdjustLayoutMarginTop = true
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        
        let topBorderImageView = UIImageView(image: UIImage(named: "BrandGradientBorder"))
        topBorderImageView.translatesAutoresizingMaskIntoConstraints = false
        topBorderImageView.contentMode = .scaleToFill
        addSubview(topBorderImageView)
        topBorderImageView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        topBorderImageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        topBorderImageView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        let verticalLayoutGuide = UILayoutGuide()
        addLayoutGuide(verticalLayoutGuide)
        verticalLayoutGuide.topAnchor.constraint(equalTo: topBorderImageView.topAnchor).isActive = true
        verticalLayoutGuide.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        let contentBackgroundImageView = UIImageView(image: UIImage(named: "BrandConfettiContentBackground"))
        contentBackgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        contentBackgroundImageView.contentMode = .scaleToFill
        addSubview(contentBackgroundImageView)
        contentBackgroundImageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        contentBackgroundImageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        contentBackgroundImageView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        contentBackgroundImageView.heightAnchor.constraint(equalTo: verticalLayoutGuide.heightAnchor, multiplier: 0.69).isActive = true
        
        contentBackgroundImageView.addSubview(BorderView(edge: .top))
        
        addLayoutGuide(headerLayoutGuide)
        headerLayoutGuide.topAnchor.constraint(equalTo: topBorderImageView.bottomAnchor).isActive = true
        headerLayoutGuide.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        headerLayoutGuide.bottomAnchor.constraint(equalTo: contentBackgroundImageView.topAnchor).isActive = true
        headerLayoutGuide.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if autoAdjustLayoutMarginTop {
            var layoutMargins = self.layoutMargins
            
            if layoutMargins.top <= 0 {
                layoutMargins.top = UIApplication.shared.statusBarFrame.height
                self.layoutMargins = layoutMargins
            }
        }
    }
}
