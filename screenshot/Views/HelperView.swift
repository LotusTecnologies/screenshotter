//
//  HelperView.swift
//  screenshot
//
//  Created by Corey Werner on 10/22/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit

public class HelperView : UIView {
    public var titleLabel = UILabel()
    public var subtitleLabel = UILabel()
    public var contentView = UIView()

    private var imageView: UIImageView?
    
    // Setting this will center an imageView in the contentView
    public var contentImage: UIImage? {
        didSet {
            if imageView == nil && contentImage != nil {
                let imageView = UIImageView()
                imageView.translatesAutoresizingMaskIntoConstraints = false
                imageView.contentMode = .scaleAspectFit
                contentView.addSubview(imageView)
                imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Geometry.extendedPadding).isActive = true
                imageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor).isActive = true
                imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
                
                self.imageView = imageView
                
            } else if contentImage == nil {
                imageView?.removeFromSuperview()
                imageView = nil
            }
            
            imageView?.image = contentImage
        }
    }
    
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
        titleLabel.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: -Geometry.padding, right: 0)
        addSubview(titleLabel)
        titleLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        titleLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = .gray3
        subtitleLabel.font = UIFont.preferredFont(forTextStyle: .title3)
        subtitleLabel.numberOfLines = 0
        addSubview(subtitleLabel)
        subtitleLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        subtitleLabel.topAnchor.constraint(equalTo: titleLabel.layoutMarginsGuide.bottomAnchor).isActive = true
        subtitleLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        subtitleLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentView.topAnchor.constraint(equalTo: subtitleLabel.layoutMarginsGuide.bottomAnchor).isActive = true
        contentView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    }
}
