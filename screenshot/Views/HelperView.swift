//
//  HelperView.swift
//  screenshot
//
//  Created by Jacob Relkin on 10/22/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit

public class HelperView : UIView {
    public var titleLabel: UILabel!
    public var subtitleLabel: UILabel!
    public var contentView: UIView!

    private var imageView: UIImageView?
    
    //  Setting this will center an imageView in the contentView
    public var contentImage: UIImage? {
        didSet {
            if imageView == nil && contentImage != nil {
                let imageView = UIImageView()
                imageView.translatesAutoresizingMaskIntoConstraints = false
                imageView.contentMode = .scaleAspectFit
                contentView.addSubview(imageView)
                
                NSLayoutConstraint.activate([
                    imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Geometry.extendedPadding),
                    imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
                ])
                
                self.imageView = imageView
            }
            
            imageView?.image = contentImage
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        titleLabel = { _ -> UILabel in
            let label = UILabel()

            let font = UIFont.preferredFont(forTextStyle: .title1)
            guard let descriptor = font.fontDescriptor.withSymbolicTraits(.traitBold) else {
                return label
            }
            
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textAlignment = .center
            label.textColor = .gray3
            label.font = UIFont(descriptor: descriptor, size: 0)
            label.numberOfLines = 0
            label.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: -Geometry.padding, right: 0)
            
            addSubview(label)
            label.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
            
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
                label.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
                label.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor)
            ])
            
            return label
        }()
        
        subtitleLabel = { _ -> UILabel in
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textAlignment = .center
            label.textColor = .gray3
            label.font = UIFont.preferredFont(forTextStyle: .title3)
            label.numberOfLines = 0
            
            addSubview(label)
            label.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
            
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: titleLabel.layoutMarginsGuide.bottomAnchor),
                label.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
                label.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor)
            ])
            
            return label
        }()
        
        contentView = { _ -> UIView in
            let view = UIView()
            addSubview(view)
            view.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: subtitleLabel.layoutMarginsGuide.bottomAnchor),
                view.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
                view.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
                view.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor)
            ])
            
            return view
        }()
    }
}
