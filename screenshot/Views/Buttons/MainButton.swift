//
//  MainButton.swift
//  screenshot
//
//  Created by Corey Werner on 9/4/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit

class MainButton: UIButton {
    var edgePadding = CGFloat(16)
    var imagePadding = CGFloat(6)
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .crazeRed
        contentEdgeInsets = UIEdgeInsetsMake(edgePadding, edgePadding, edgePadding, edgePadding)
        adjustsImageWhenHighlighted = false
        layer.cornerRadius = 9
    }
    
    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.width = max(size.width, 160)
        return size
    }
    
    override func setImage(_ image: UIImage?, for state: UIControlState) {
        super.setImage(image, for: state)
        
        imageEdgeInsets = UIEdgeInsetsMake(0, -imagePadding, 0, imagePadding / 2.0)
        titleEdgeInsets = UIEdgeInsetsMake(0, imagePadding / 2.0, 0, -imagePadding)
        
        var contentInsets = contentEdgeInsets
        contentInsets.left += imageEdgeInsets.right
        contentInsets.right += titleEdgeInsets.left
        contentEdgeInsets = contentInsets
    }
    
    // MARK: Loader
    
    var isLoading = Bool() {
        didSet {
            if isLoading {
                activityIndicator?.isHidden = false
                activityIndicator?.startAnimating()
                
            } else {
                activityIndicator?.stopAnimating()
                activityIndicator?.isHidden = true
            }
        }
    }
    
    lazy var activityIndicator: UIActivityIndicatorView? = {
        guard let imageView = self.imageView else {
            return nil
        }
        
        let activity = UIActivityIndicatorView(activityIndicatorStyle: .white)
        activity.translatesAutoresizingMaskIntoConstraints = false
        activity.backgroundColor = self.backgroundColor
        activity.isHidden = true
        self.addSubview(activity)
        activity.topAnchor.constraint(equalTo: imageView.topAnchor).isActive = true
        activity.leadingAnchor.constraint(equalTo: imageView.leadingAnchor).isActive = true
        activity.bottomAnchor.constraint(equalTo: imageView.bottomAnchor).isActive = true
        activity.trailingAnchor.constraint(equalTo: imageView.trailingAnchor).isActive = true
        return activity
    }()
}
