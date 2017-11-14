//
//  HelperView.swift
//  screenshot
//
//  Created by Corey Werner on 10/22/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit

public class HelperView : UIView {
    private(set) var titleLabel = UILabel()
    private(set) var subtitleLabel = UILabel()
    private(set) var contentView = UIView()
    private(set) var controlView = NotifySizeChangeView()

    private var imageView: UIImageView?
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        var font = UIFont.preferredFont(forTextStyle: .title1)
        
        if let descriptor = font.fontDescriptor.withSymbolicTraits(.traitBold) {
            font = UIFont(descriptor: descriptor, size: 0)
        }
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textAlignment = .center
        titleLabel.textColor = .gray3
        titleLabel.font = font
        titleLabel.numberOfLines = 0
        titleLabel.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: -.padding, right: 0)
        addSubview(titleLabel)
        titleLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        titleLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        titleLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = .gray3
        subtitleLabel.font = UIFont.preferredFont(forTextStyle: .title3)
        subtitleLabel.numberOfLines = 0
        subtitleLabel.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: -.extendedPadding, right: 0)
        addSubview(subtitleLabel)
        subtitleLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        subtitleLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        subtitleLabel.topAnchor.constraint(equalTo: titleLabel.layoutMarginsGuide.bottomAnchor).isActive = true
        subtitleLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        subtitleLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.layoutMargins = .zero
        addSubview(contentView)
        contentView.topAnchor.constraint(equalTo: subtitleLabel.layoutMarginsGuide.bottomAnchor).isActive = true
        contentView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        controlView.translatesAutoresizingMaskIntoConstraints = false
        controlView.layoutMargins = .zero
        controlView.notification = { size in
            var contentViewLayoutMargins = self.contentView.layoutMargins
            contentViewLayoutMargins.bottom = size.height > 0 ? -.extendedPadding : 0
            self.contentView.layoutMargins = contentViewLayoutMargins
        }
        addSubview(controlView)
        controlView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
        controlView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        controlView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
        controlView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    }
    
    // Setting this will center an imageView in the contentView
    public var contentImage: UIImage? {
        didSet {
            if imageView == nil && contentImage != nil {
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
                
            } else if contentImage == nil {
                imageView?.removeFromSuperview()
                imageView = nil
            }
            
            imageView?.image = contentImage
        }
    }
}
