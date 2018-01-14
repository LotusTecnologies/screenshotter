//
//  DiscoverScreenshotHelperView.swift
//  screenshot
//
//  Created by Corey Werner on 1/14/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation

class DiscoverScreenshotHelperView : UIView {
    fileprivate let titleLabel = UILabel()
    fileprivate let swipeLeftLabel = UILabel()
    fileprivate let swipeRightLabel = UILabel()
    fileprivate let tapLabel = UILabel()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.crazeRed.withAlphaComponent(0.8)
        layoutMargins = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .white
        titleLabel.text = "Discover Fashion"
        titleLabel.textAlignment = .center
        addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        let divider = UIView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.backgroundColor = .white
        addSubview(divider)
        divider.topAnchor.constraint(equalTo: titleLabel.bottomAnchor).isActive = true
        divider.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        divider.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.3).isActive = true
        divider.heightAnchor.constraint(equalToConstant: .halfPoint).isActive = true
    }
}
