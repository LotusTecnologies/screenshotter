//
//  HelperView.swift
//  screenshot
//
//  Created by Corey Werner on 10/22/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit

public class HelperView : UIView {
    private let scrollView = UIScrollView()
    private(set) var titleLabel = UILabel()
    private(set) var subtitleLabel = UILabel()
    private(set) var contentView = NotifySizeChangeView()
    private(set) var controlView = NotifySizeChangeView()
    
    private var scrollContentViewMaxHeightConstraint: NSLayoutConstraint!
    private var imageView: UIImageView?
    
    public var isScrollable = true {
        didSet {
            scrollContentViewMaxHeightConstraint.isActive = !isScrollable
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
//        scrollView.backgroundColor = .red
        addSubview(scrollView)
        scrollView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        let scrollContentView = UIView()
        scrollContentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(scrollContentView)
        scrollContentView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        scrollContentView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        scrollContentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        scrollContentView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        scrollContentView.heightAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.heightAnchor).isActive = true
        scrollContentViewMaxHeightConstraint = scrollContentView.heightAnchor.constraint(equalTo: layoutMarginsGuide.heightAnchor)
        
        var font = UIFont.preferredFont(forTextStyle: .title1)
        
        if let descriptor = font.fontDescriptor.withSymbolicTraits(.traitBold) {
            font = UIFont(descriptor: descriptor, size: 0)
        }
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textAlignment = .center
        titleLabel.textColor = .gray3
//        titleLabel.backgroundColor = .cyan
        titleLabel.font = font
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true
        scrollContentView.addSubview(titleLabel)
        titleLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        titleLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        titleLabel.topAnchor.constraint(equalTo: scrollContentView.topAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: scrollContentView.trailingAnchor).isActive = true
        
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = .gray3
        subtitleLabel.font = UIFont.preferredFont(forTextStyle: .title3)
        subtitleLabel.numberOfLines = 0
        subtitleLabel.adjustsFontForContentSizeCategory = true
//        subtitleLabel.backgroundColor = .yellow
        subtitleLabel.layoutMargins = UIEdgeInsets(top: -.padding, left: 0, bottom: 0, right: 0)
        scrollContentView.addSubview(subtitleLabel)
        subtitleLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        subtitleLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        subtitleLabel.layoutMarginsGuide.topAnchor.constraint(equalTo: titleLabel.bottomAnchor).isActive = true
        subtitleLabel.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor).isActive = true
        subtitleLabel.trailingAnchor.constraint(equalTo: scrollContentView.trailingAnchor).isActive = true
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.layoutMargins = .zero
//        contentView.backgroundColor = .cyan
        contentView.subviewNotification = { count in
            var contentViewLayoutMargins = self.contentView.layoutMargins
            contentViewLayoutMargins.top = count > 0 ? -.extendedPadding : 0
            self.contentView.layoutMargins = contentViewLayoutMargins
        }
        contentView.notification = { size in
            if let image = self.imageView?.image {
                self.contentView.isHidden = image.size.height * 0.3 > self.contentView.bounds.size.height
            }
        }
        scrollContentView.addSubview(contentView)
        contentView.layoutMarginsGuide.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor).isActive = true
        contentView.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: scrollContentView.trailingAnchor).isActive = true
        
        let controlViewNotificationBlock = {
            var controlViewLayoutMargins = self.controlView.layoutMargins
            
            if self.controlView.subviews.count > 0 && self.controlView.bounds.size.height > 0 {
                controlViewLayoutMargins.top = -.extendedPadding
                
            } else {
                controlViewLayoutMargins.top = 0
            }
            
            self.controlView.layoutMargins = controlViewLayoutMargins
        }
        
        controlView.translatesAutoresizingMaskIntoConstraints = false
        controlView.layoutMargins = .zero
//        controlView.backgroundColor = .green
        controlView.subviewNotification = { count in
            controlViewNotificationBlock()
        }
        controlView.notification = { size in
            controlViewNotificationBlock()
        }
        scrollContentView.addSubview(controlView)
        controlView.layoutMarginsGuide.topAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        controlView.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor).isActive = true
        controlView.bottomAnchor.constraint(equalTo: scrollContentView.bottomAnchor).isActive = true
        controlView.trailingAnchor.constraint(equalTo: scrollContentView.trailingAnchor).isActive = true
    }
    
    // Setting this will center an imageView in the contentView
    public var contentImage: UIImage? {
        didSet {
            if let image = contentImage {
                if imageView == nil {
                    let imageView = UIImageView()
                    imageView.translatesAutoresizingMaskIntoConstraints = false
                    imageView.contentMode = .scaleAspectFit
                    contentView.addSubview(imageView)
                    imageView.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .vertical)
                    imageView.topAnchor.constraint(greaterThanOrEqualTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
                    imageView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
                    imageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
                    imageView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
                    imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
                    imageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
                    self.imageView = imageView
                }
                
                imageView?.image = image
                
            } else {
                imageView?.removeFromSuperview()
                imageView = nil
            }
        }
    }
    
    public override var layoutMargins: UIEdgeInsets {
        didSet {
            scrollView.contentInset = layoutMargins
        }
    }
}
