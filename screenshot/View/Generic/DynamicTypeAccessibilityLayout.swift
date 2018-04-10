//
//  DynamicTypeAccessibilityLayout.swift
//  screenshot
//
//  Created by Corey Werner on 3/28/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

protocol DynamicTypeAccessibilityLayout {
    var fontSizeStandardRangeConstraints: [NSLayoutConstraint] { get set }
    var fontSizeAccessibilityRangeConstraints: [NSLayoutConstraint] { get set }
}

extension DynamicTypeAccessibilityLayout {
    private func adjustConstraints(with isAccessibilityCategory: Bool) {
        if isAccessibilityCategory {
            NSLayoutConstraint.deactivate(fontSizeStandardRangeConstraints)
            NSLayoutConstraint.activate(fontSizeAccessibilityRangeConstraints)
        }
        else {
            NSLayoutConstraint.deactivate(fontSizeAccessibilityRangeConstraints)
            NSLayoutConstraint.activate(fontSizeStandardRangeConstraints)
        }
    }
    
    func adjustDynamicTypeLayout(traitCollection: UITraitCollection, previousTraitCollection: UITraitCollection?) {
        let isAccessibilityCategory = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        
        if let previousContentSizeCategory = previousTraitCollection?.preferredContentSizeCategory {
            if previousContentSizeCategory.isAccessibilityCategory != isAccessibilityCategory {
                adjustConstraints(with: isAccessibilityCategory)
            }
        }
        else {
            adjustConstraints(with: isAccessibilityCategory)
        }
    }
}
