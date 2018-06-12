//
//  MainSegmentedControl.swift
//  screenshot
//
//  Created by Corey Werner on 6/10/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class MainSegmentedControl: UISegmentedControl {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    override init(items: [Any]?) {
        super.init(items: items)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        var attributes: [AnyHashable: Any] = [
            NSAttributedStringKey.foregroundColor.rawValue: UIColor.gray7,
            NSAttributedStringKey.font.rawValue: UIFont.screenshopFont(.quicksand, size: 16)
        ]
        setTitleTextAttributes(attributes, for: .normal)
        
        attributes[NSAttributedStringKey.foregroundColor.rawValue] = UIColor.gray4
        setTitleTextAttributes(attributes, for: .highlighted)
        
        attributes[NSAttributedStringKey.foregroundColor.rawValue] = UIColor.gray9
        setTitleTextAttributes(attributes, for: .disabled)
        
        attributes[NSAttributedStringKey.foregroundColor.rawValue] = UIColor.gray2
        attributes[NSAttributedStringKey.font.rawValue] = UIFont.screenshopFont(.quicksandMedium, size: 16)
        setTitleTextAttributes(attributes, for: .selected)
        
        layer.borderColor = UIColor.gray8.cgColor
        layer.borderWidth = 1
        layer.cornerRadius = .defaultCornerRadius
        
        let dividerImage = UIImage(named: "SegmentedControlDivider")
        setDividerImage(dividerImage, forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)
        
        let backgroundImage = UIImage(named: "SegmentedControlBackground")
        setBackgroundImage(backgroundImage, for: .normal, barMetrics: .default)
        
        heightAnchor.constraint(equalToConstant: intrinsicContentSize.height).isActive = true
    }
    
    private let _layoutMargins = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Needed here for iOS 10
        layoutMargins = _layoutMargins
    }
    
    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = .defaultViewHeight
        return size
    }
}
