//
//  LoadingButton.swift
//  screenshot
//
//  Created by Corey Werner on 3/21/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit

class LoadingButton: UIButton {
    var isLoading = false {
        didSet {
            if isLoading {
                imageView?.isHidden = true
                activityIndicator.isHidden = false
                activityIndicator.startAnimating()
                syncActivityIndicatorColor()
            }
            else {
                imageView?.isHidden = false
                activityIndicator.stopAnimating()
                activityIndicator.isHidden = true
            }
        }
    }
    
    private var hasActivityIndicator = false
    
    fileprivate lazy var activityIndicator: UIActivityIndicatorView = {
        self.hasActivityIndicator = true
        
        let activity = UIActivityIndicatorView(activityIndicatorStyle: .white)
        activity.translatesAutoresizingMaskIntoConstraints = false
        activity.isHidden = true
        activity.color = self.titleColor(for: self.state)
        self.addSubview(activity)
        
        if let imageView = self.imageView, imageView.image != nil {
            activity.topAnchor.constraint(equalTo: imageView.topAnchor).isActive = true
            activity.leadingAnchor.constraint(equalTo: imageView.leadingAnchor).isActive = true
            activity.bottomAnchor.constraint(equalTo: imageView.bottomAnchor).isActive = true
            activity.trailingAnchor.constraint(equalTo: imageView.trailingAnchor).isActive = true
        }
        else {
            activity.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
            activity.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
            
            self.setTitleColor(.clear, for: .disabled)
        }
        
        return activity
    }()
    
    fileprivate func syncActivityIndicatorColor() {
        guard hasActivityIndicator &&
            state != .disabled else {
                return
        }
        
        activityIndicator.color = titleColor(for: state)
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
