//
//  LoadingButton.swift
//  screenshot
//
//  Created by Corey Werner on 3/21/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class LoadingButtonController {
    weak var button:UIButton?

    func setup(button:UIButton){
        self.button = button
    }
    
    var isLoading = Bool() {
        didSet {
            if isLoading {
                self.button?.imageView?.isHidden = true
                self.activityIndicator?.isHidden = false
                self.activityIndicator?.startAnimating()
                self.syncActivityIndicatorColor()
            }
            else {
                self.button?.imageView?.isHidden = false
                self.activityIndicator?.stopAnimating()
                self.activityIndicator?.isHidden = true
            }
        }
    }
    
    private var hasActivityIndicator = false
    
    fileprivate lazy var activityIndicator: UIActivityIndicatorView? = {
        if let button = self.button {
            self.hasActivityIndicator = true
            
            let activity = UIActivityIndicatorView(activityIndicatorStyle: .white)
            activity.translatesAutoresizingMaskIntoConstraints = false
            activity.isHidden = true
            activity.color = button.titleColor(for: button.state)
            
            button.addSubview(activity)
            
            if  let imageView = button.imageView, button.imageView?.image != nil {
                activity.topAnchor.constraint(equalTo: imageView.topAnchor).isActive = true
                activity.leadingAnchor.constraint(equalTo: imageView.leadingAnchor).isActive = true
                activity.bottomAnchor.constraint(equalTo: imageView.bottomAnchor).isActive = true
                activity.trailingAnchor.constraint(equalTo: imageView.trailingAnchor).isActive = true
            }
            else {
                activity.centerXAnchor.constraint(equalTo: button.centerXAnchor).isActive = true
                activity.centerYAnchor.constraint(equalTo: button.centerYAnchor).isActive = true
                
                button.setTitleColor(.clear, for: .disabled)
            }
            
            return activity
        }
        
        return nil
    }()
    func syncActivityIndicatorColor() {
        if let button = self.button {
            guard hasActivityIndicator &&
                button.state != .disabled else {
                    return
            }
            
            self.activityIndicator?.color = button.titleColor(for: button.state)
        }
    }
}

class LoadingButton: UIButton {
   
    let loadingButtonController = LoadingButtonController()
    
    
    var isLoading = Bool() {
        didSet {
            self.loadingButtonController.isLoading = isLoading
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.loadingButtonController.setup(button: self)
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadingButtonController.setup(button: self)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Force isHidden since UIKit can unset it
        imageView?.isHidden = isLoading
    }
    
    override var isHighlighted: Bool {
        didSet {
            loadingButtonController.syncActivityIndicatorColor()
        }
    }
    
    override var isSelected: Bool {
        didSet {
            loadingButtonController.syncActivityIndicatorColor()
        }
    }
}
