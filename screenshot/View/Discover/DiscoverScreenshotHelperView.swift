//
//  DiscoverScreenshotHelperView.swift
//  screenshot
//
//  Created by Corey Werner on 1/14/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import UIKit

class DiscoverScreenshotHelperView : UIView {
    fileprivate let titleLabel = UILabel()
    fileprivate let swipeLeftLabel = UILabel()
    fileprivate let swipeRightLabel = UILabel()
    fileprivate let tapLabel = UILabel()
    
    private class DefinedHeightView : UIView {
        override var intrinsicContentSize: CGSize {
            var size = super.intrinsicContentSize
            size.height = subviews.map{ $0.intrinsicContentSize.height }.max() ?? size.height
            return size
        }
    }
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let padding: CGFloat
        let fontSize: CGFloat
        
        if UIDevice.is480h {
            padding = .padding * 0.5
            fontSize = 13
            
        } else if UIDevice.is568h {
            padding = .padding * 0.8
            fontSize = 16
            
        } else {
            padding = .padding
            fontSize = 20
        }
        
        let attributes = [
            [NSFontAttributeName: UIFont.boldSystemFont(ofSize: fontSize)],
            [NSFontAttributeName: UIFont.systemFont(ofSize: fontSize)]
        ]
        
        backgroundColor = UIColor.crazeRed.withAlphaComponent(0.9)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .white
        titleLabel.text = "discover.screenshot.helper.title".localized
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont(name: "DINCondensed-Bold", size: 34)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.7
        addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        let divider = UIView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.backgroundColor = .white
        addSubview(divider)
        divider.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: padding).isActive = true
        divider.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        let dividerWidthConstraint = divider.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.3)
        dividerWidthConstraint.priority = UILayoutPriorityDefaultHigh
        dividerWidthConstraint.isActive = true
        divider.widthAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true
        divider.heightAnchor.constraint(equalToConstant: .halfPoint).isActive = true
        
        let swipeLabelContainer = DefinedHeightView()
        swipeLabelContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(swipeLabelContainer)
        swipeLabelContainer.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        swipeLabelContainer.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: padding).isActive = true
        swipeLabelContainer.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        swipeLabelContainer.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        swipeLeftLabel.translatesAutoresizingMaskIntoConstraints = false
        swipeLeftLabel.textColor = .white
        swipeLeftLabel.attributedText = NSMutableAttributedString(segmentedString: "discover.screenshot.helper.swipe_left", attributes: attributes)
        swipeLeftLabel.textAlignment = .center
        swipeLeftLabel.adjustsFontSizeToFitWidth = true
        swipeLeftLabel.minimumScaleFactor = 0.7
        swipeLeftLabel.numberOfLines = 0
        swipeLabelContainer.addSubview(swipeLeftLabel)
        swipeLeftLabel.topAnchor.constraint(equalTo: swipeLabelContainer.topAnchor).isActive = true
        swipeLeftLabel.leadingAnchor.constraint(equalTo: swipeLabelContainer.leadingAnchor).isActive = true
        swipeLeftLabel.bottomAnchor.constraint(lessThanOrEqualTo: swipeLabelContainer.bottomAnchor).isActive = true
        swipeLeftLabel.trailingAnchor.constraint(lessThanOrEqualTo: swipeLabelContainer.centerXAnchor).isActive = true
        
        swipeRightLabel.translatesAutoresizingMaskIntoConstraints = false
        swipeRightLabel.textColor = .white
        swipeRightLabel.attributedText = NSMutableAttributedString(segmentedString: "discover.screenshot.helper.swipe_right", attributes: attributes)
        swipeRightLabel.textAlignment = .center
        swipeRightLabel.adjustsFontSizeToFitWidth = true
        swipeRightLabel.minimumScaleFactor = 0.7
        swipeRightLabel.numberOfLines = 0
        swipeLabelContainer.addSubview(swipeRightLabel)
        swipeRightLabel.topAnchor.constraint(equalTo: swipeLabelContainer.topAnchor).isActive = true
        swipeRightLabel.leadingAnchor.constraint(greaterThanOrEqualTo: swipeLabelContainer.centerXAnchor).isActive = true
        swipeRightLabel.leadingAnchor.constraint(equalTo: swipeLeftLabel.trailingAnchor, constant: padding).isActive = true
        swipeRightLabel.bottomAnchor.constraint(lessThanOrEqualTo: swipeLabelContainer.bottomAnchor).isActive = true
        swipeRightLabel.trailingAnchor.constraint(equalTo: swipeLabelContainer.trailingAnchor).isActive = true
        
        let swipeImage = UIImage(named: "DiscoverScreenshotHelperSwipe")

        let leftImageView = UIImageView(image: swipeImage)
        leftImageView.translatesAutoresizingMaskIntoConstraints = false
        leftImageView.contentMode = .scaleAspectFit
        addSubview(leftImageView)
        leftImageView.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .vertical)
        leftImageView.topAnchor.constraint(equalTo: swipeLabelContainer.bottomAnchor, constant: padding).isActive = true
        leftImageView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        leftImageView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor, constant: -padding).isActive = true
        leftImageView.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor, multiplier: 0.196).isActive = true
        
        let rightImageView = UIImageView(image: swipeImage?.withHorizontallyFlippedOrientation())
        rightImageView.translatesAutoresizingMaskIntoConstraints = false
        rightImageView.contentMode = .scaleAspectFit
        addSubview(rightImageView)
        rightImageView.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .vertical)
        rightImageView.topAnchor.constraint(equalTo: leftImageView.topAnchor).isActive = true
        rightImageView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor, constant: padding).isActive = true
        rightImageView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        rightImageView.heightAnchor.constraint(equalTo: leftImageView.heightAnchor).isActive = true
        
        tapLabel.translatesAutoresizingMaskIntoConstraints = false
        tapLabel.textColor = .white
        tapLabel.attributedText = NSMutableAttributedString(segmentedString: "discover.screenshot.helper.tap", attributes: attributes)
        tapLabel.textAlignment = .center
        tapLabel.adjustsFontSizeToFitWidth = true
        tapLabel.minimumScaleFactor = 0.7
        tapLabel.numberOfLines = 0
        swipeLabelContainer.addSubview(tapLabel)
        tapLabel.topAnchor.constraint(greaterThanOrEqualTo: leftImageView.bottomAnchor).isActive = true
        tapLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        tapLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        let tapImageView = UIImageView(image: UIImage(named: "DiscoverScreenshotHelperTap"))
        tapImageView.translatesAutoresizingMaskIntoConstraints = false
        tapImageView.contentMode = .scaleAspectFit
        addSubview(tapImageView)
        tapImageView.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .vertical)
        tapImageView.topAnchor.constraint(equalTo: tapLabel.bottomAnchor, constant: padding).isActive = true
        tapImageView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        tapImageView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        tapImageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        tapImageView.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor, multiplier: 0.3).isActive = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Needed here for iOS 10
        if UIDevice.is480h {
            let padding = .padding * 0.5
            layoutMargins = UIEdgeInsets(top: padding, left: padding, bottom: 0, right: padding)
            
        } else {
            layoutMargins = UIEdgeInsets(top: .padding + 4, left: .padding, bottom: 0, right: .padding)
        }
        
        swipeLeftLabel.superview?.invalidateIntrinsicContentSize()
    }
}
