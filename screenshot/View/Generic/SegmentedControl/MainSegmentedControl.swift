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
        let font: UIFont = .screenshopFont(.quicksand, size: 16)
        
        let normalAttributes: [AnyHashable: Any] = [
            NSAttributedStringKey.foregroundColor.rawValue: UIColor.gray8,
            NSAttributedStringKey.font.rawValue: font
        ]
        let selectedAttributes: [AnyHashable: Any] = [
            NSAttributedStringKey.foregroundColor.rawValue: UIColor.gray2,
            NSAttributedStringKey.font.rawValue: font
        ]
        
        setTitleTextAttributes(normalAttributes, for: .normal)
        setTitleTextAttributes(selectedAttributes, for: .selected)
        setTitleTextAttributes(selectedAttributes, for: .highlighted)
        
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
        size.height = min(44, layoutMargins.top + ceil(size.height) + layoutMargins.bottom)
        return size
    }
}
