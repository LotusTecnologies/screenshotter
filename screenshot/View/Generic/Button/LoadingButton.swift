//
//  LoadingButton.swift
//  screenshot
//
//  Created by Corey Werner on 3/21/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class LoadingButton: UIButton {
    var isLoading = Bool() {
        didSet {
            if isLoading {
                imageView?.isHidden = true
                activityIndicator?.isHidden = false
                activityIndicator?.startAnimating()
                syncActivityIndicatorColor()
            }
            else {
                imageView?.isHidden = false
                activityIndicator?.stopAnimating()
                activityIndicator?.isHidden = true
            }
        }
    }
    
    fileprivate lazy var activityIndicator: UIActivityIndicatorView? = {
        guard let imageView = self.imageView else {
            return nil
        }
        
        let activity = UIActivityIndicatorView(activityIndicatorStyle: .white)
        activity.translatesAutoresizingMaskIntoConstraints = false
        activity.isHidden = true
        activity.color = self.titleColor(for: self.state)
        self.addSubview(activity)
        activity.topAnchor.constraint(equalTo: imageView.topAnchor).isActive = true
        activity.leadingAnchor.constraint(equalTo: imageView.leadingAnchor).isActive = true
        activity.bottomAnchor.constraint(equalTo: imageView.bottomAnchor).isActive = true
        activity.trailingAnchor.constraint(equalTo: imageView.trailingAnchor).isActive = true
        return activity
    }()
    
    fileprivate func syncActivityIndicatorColor() {
        activityIndicator?.color = titleColor(for: state)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Force isHidden since UIKit can unset it
        imageView?.isHidden = isLoading
    }
    
    override var isHighlighted: Bool {
        didSet {
            syncActivityIndicatorColor()
        }
    }
    
    override var isSelected: Bool {
        didSet {
            syncActivityIndicatorColor()
        }
    }
}
