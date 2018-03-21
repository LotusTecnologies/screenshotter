//
//  CartItemCountView.swift
//  screenshot
//
//  Created by Corey Werner on 3/5/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class CartItemCountView: UIView {
    fileprivate let itemCountLabel = UILabel()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "cart.header.title".localized
        titleLabel.textColor = .gray3
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: UIFontWeightLight)
        titleLabel.minimumScaleFactor = 0.7
        titleLabel.baselineAdjustment = .alignCenters
        titleLabel.adjustsFontSizeToFitWidth = true
        addSubview(titleLabel)
        titleLabel.topAnchor.constraint(greaterThanOrEqualTo: topAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor).isActive = true
        titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        itemCountLabel.translatesAutoresizingMaskIntoConstraints = false
        itemCountLabel.textColor = .gray3
        addSubview(itemCountLabel)
        itemCountLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)
        itemCountLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        itemCountLabel.firstBaselineAnchor.constraint(equalTo: titleLabel.firstBaselineAnchor).isActive = true
        itemCountLabel.topAnchor.constraint(greaterThanOrEqualTo: topAnchor).isActive = true
        itemCountLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor).isActive = true
        itemCountLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor).isActive = true
        itemCountLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        syncItemCount()
    }
    
    var itemCount = 0 {
        didSet {
            syncItemCount()
        }
    }
    
    fileprivate func syncItemCount() {
        let count = max(0, itemCount)
        let text = "cart.header.item_count".localized(withFormat: count)
        let countRange = NSString(string: text).range(of: "\(count)")
        
        let fontLight = UIFont.systemFont(ofSize: 16, weight: UIFontWeightLight)
        let fontMedium = UIFont.systemFont(ofSize: 16, weight: UIFontWeightMedium)
        
        let attributedString = NSMutableAttributedString(string: text, attributes: [
            NSFontAttributeName: fontMedium
            ])
        attributedString.addAttribute(NSFontAttributeName, value: fontLight, range: countRange)
        
        itemCountLabel.attributedText = attributedString
    }
}
