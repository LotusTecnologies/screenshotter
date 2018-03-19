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
    private(set) var titleLabel = Label()
    private(set) var subtitleLabel = Label()
    private(set) var contentView = NotifyChangeView()
    private(set) var controlView = NotifyChangeView()
    
    private var scrollContentViewTopConstraint: NSLayoutConstraint!
    private var scrollContentViewBottomConstraint: NSLayoutConstraint!
    private var scrollContentViewMaxHeightConstraint: NSLayoutConstraint!
    private var imageView: UIImageView?
    
    // MARK: Life Cycle
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        NotificationCenter.default.addObserver(self, selector: #selector(contentSizeCategoryDidChange(_:)), name: .UIContentSizeCategoryDidChange, object: nil)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        scrollView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        let scrollContentView = UIView()
        scrollContentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(scrollContentView)
        scrollContentViewTopConstraint = scrollContentView.topAnchor.constraint(equalTo: scrollView.topAnchor)
        scrollContentViewTopConstraint.isActive = true
        scrollContentView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        scrollContentViewBottomConstraint = scrollContentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        scrollContentViewBottomConstraint.isActive = true
        scrollContentView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        scrollContentView.heightAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.heightAnchor).isActive = true
        scrollContentViewMaxHeightConstraint = scrollContentView.heightAnchor.constraint(equalTo: layoutMarginsGuide.heightAnchor)
        scrollContentViewMaxHeightConstraint.isActive = !isScrollable()
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textAlignment = .center
        titleLabel.textColor = .gray3
        titleLabel.font = .screenshopFont(.dinCondensedBold, textStyle: .title1)
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
        subtitleLabel.font = .screenshopFont(.hindLight, textStyle: .body)
        subtitleLabel.numberOfLines = 0
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.layoutMargins = UIEdgeInsets(top: -.padding, left: 0, bottom: 0, right: 0)
        scrollContentView.addSubview(subtitleLabel)
        subtitleLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        subtitleLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        subtitleLabel.layoutMarginsGuide.topAnchor.constraint(equalTo: titleLabel.bottomAnchor).isActive = true
        subtitleLabel.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor).isActive = true
        subtitleLabel.trailingAnchor.constraint(equalTo: scrollContentView.trailingAnchor).isActive = true
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.layoutMargins = .zero
        contentView.notifySubviewChange = { count in
            var contentViewLayoutMargins = self.contentView.layoutMargins
            contentViewLayoutMargins.top = count > 0 ? -.extendedPadding : 0
            self.contentView.layoutMargins = contentViewLayoutMargins
        }
        contentView.notifySizeChange = { size in
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
        controlView.notifySubviewChange = { count in
            controlViewNotificationBlock()
        }
        controlView.notifySizeChange = { size in
            controlViewNotificationBlock()
        }
        scrollContentView.addSubview(controlView)
        controlView.layoutMarginsGuide.topAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        controlView.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor).isActive = true
        controlView.bottomAnchor.constraint(equalTo: scrollContentView.bottomAnchor).isActive = true
        controlView.trailingAnchor.constraint(equalTo: scrollContentView.trailingAnchor).isActive = true
    }
    
    public override var layoutMargins: UIEdgeInsets {
        didSet {
            // Only vertical is needed, horizontal is managed by the constraint system
            scrollContentViewTopConstraint.constant = layoutMargins.top
            scrollContentViewBottomConstraint.constant = -layoutMargins.bottom
        }
    }
    
    func contentSizeCategoryDidChange(_ notification: Notification) {
        if let userInfo = notification.userInfo, let contentSizeCategoryString = userInfo[UIContentSizeCategoryNewValueKey] as? String {
            let contentSizeCategory = UIContentSizeCategory(rawValue: contentSizeCategoryString)
            scrollContentViewMaxHeightConstraint.isActive = !isScrollable(contentSizeCategory: contentSizeCategory)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Content
    
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
    
    // MARK: Scrolling
    
    var scrollInset: UIEdgeInsets = .zero {
        didSet {
            scrollView.contentInset = scrollInset
            scrollView.scrollIndicatorInsets = scrollView.contentInset
        }
    }
    
    func isScrollable(contentSizeCategory: UIContentSizeCategory = UIApplication.shared.preferredContentSizeCategory) -> Bool {
        return contentSizeCategory.isAccessibilityCategory
    }
}
