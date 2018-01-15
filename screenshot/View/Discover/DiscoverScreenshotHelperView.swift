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
        
        backgroundColor = UIColor.crazeRed.withAlphaComponent(0.8)
        layoutMargins = UIEdgeInsets(top: .padding + 4, left: .padding, bottom: 0, right: .padding)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .white
        titleLabel.text = "Discover Fashion"
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
        divider.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: .padding).isActive = true
        divider.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        divider.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.3).isActive = true
        divider.heightAnchor.constraint(equalToConstant: .halfPoint).isActive = true
        
        let swipeLabelContainer = DefinedHeightView()
        swipeLabelContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(swipeLabelContainer)
        swipeLabelContainer.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        swipeLabelContainer.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: .padding).isActive = true
        swipeLabelContainer.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        swipeLabelContainer.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        swipeLeftLabel.translatesAutoresizingMaskIntoConstraints = false
        swipeLeftLabel.textColor = .white
        swipeLeftLabel.attributedText = {
            let text = NSMutableAttributedString(string: "Swipe Left", attributes: [
                NSFontAttributeName: UIFont.boldSystemFont(ofSize: 20)
                ])
            let text2 = NSAttributedString(string: "\nto pass", attributes: [
                NSFontAttributeName: UIFont.systemFont(ofSize: 20)
                ])
            text.append(text2)
            return text
        }()
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
        swipeRightLabel.attributedText = {
            let text = NSMutableAttributedString(string: "Swipe Right", attributes: [
                NSFontAttributeName: UIFont.boldSystemFont(ofSize: 20)
                ])
            let text2 = NSAttributedString(string: "\nto add to your collection", attributes: [
                NSFontAttributeName: UIFont.systemFont(ofSize: 20)
                ])
            text.append(text2)
            return text
        }()
        swipeRightLabel.textAlignment = .center
        swipeRightLabel.adjustsFontSizeToFitWidth = true
        swipeRightLabel.minimumScaleFactor = 0.7
        swipeRightLabel.numberOfLines = 0
        swipeLabelContainer.addSubview(swipeRightLabel)
        swipeRightLabel.topAnchor.constraint(equalTo: swipeLabelContainer.topAnchor).isActive = true
        swipeRightLabel.leadingAnchor.constraint(greaterThanOrEqualTo: swipeLabelContainer.centerXAnchor).isActive = true
        swipeRightLabel.leadingAnchor.constraint(equalTo: swipeLeftLabel.trailingAnchor, constant: .padding).isActive = true
        swipeRightLabel.bottomAnchor.constraint(lessThanOrEqualTo: swipeLabelContainer.bottomAnchor).isActive = true
        swipeRightLabel.trailingAnchor.constraint(equalTo: swipeLabelContainer.trailingAnchor).isActive = true
        
        let swipeImage = UIImage(named: "DiscoverScreenshotHelperSwipe")

        let leftImageView = UIImageView(image: swipeImage)
        leftImageView.translatesAutoresizingMaskIntoConstraints = false
        leftImageView.contentMode = .scaleAspectFit
        addSubview(leftImageView)
        leftImageView.topAnchor.constraint(equalTo: swipeLabelContainer.bottomAnchor, constant: .padding).isActive = true
        leftImageView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        leftImageView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor, constant: -.padding).isActive = true
        
        let rightImageView = UIImageView(image: swipeImage?.withHorizontallyFlippedOrientation())
        rightImageView.translatesAutoresizingMaskIntoConstraints = false
        rightImageView.contentMode = .scaleAspectFit
        addSubview(rightImageView)
        rightImageView.topAnchor.constraint(equalTo: leftImageView.topAnchor).isActive = true
        rightImageView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor, constant: .padding).isActive = true
        rightImageView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        tapLabel.translatesAutoresizingMaskIntoConstraints = false
        tapLabel.textColor = .white
        tapLabel.attributedText = {
            let text = NSMutableAttributedString(string: "Tap", attributes: [
                NSFontAttributeName: UIFont.boldSystemFont(ofSize: 20)
                ])
            let text2 = NSAttributedString(string: " to shop", attributes: [
                NSFontAttributeName: UIFont.systemFont(ofSize: 20)
                ])
            text.append(text2)
            return text
        }()
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
        tapImageView.topAnchor.constraint(equalTo: tapLabel.bottomAnchor, constant: .padding).isActive = true
        tapImageView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        tapImageView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        tapImageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        swipeLeftLabel.superview?.invalidateIntrinsicContentSize()
    }
}
