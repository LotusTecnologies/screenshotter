//
//  MainButton.swift
//  screenshot
//
//  Created by Corey Werner on 9/4/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit

class MainButton: UIButton {
    private var edgePadding = CGFloat(16)
    private var imagePadding = CGFloat(6)
    
    private var backgroundColorStates: [UInt : UIColor] = [:]
    private var isSettingBackgroundColor = false
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .crazeRed
        contentEdgeInsets = UIEdgeInsets(top: edgePadding, left: edgePadding, bottom: edgePadding, right: edgePadding)
        adjustsImageWhenHighlighted = false
        titleLabel?.font = .hindMedium(forTextStyle: .subheadline, staticSize: true)
        layer.cornerRadius = 9
        layer.shadowColor = Shadow.basic.color.cgColor
        layer.shadowOffset = Shadow.basic.offset
        layer.shadowRadius = Shadow.basic.radius
        layer.shadowOpacity = 1
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
    }
    
    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.width = max(size.width, 160)
        return size
    }
    
    // MARK: Interaction
    
    override var isHighlighted: Bool {
        didSet {
            isSettingBackgroundColor = true
            backgroundColor = backgroundColorStates[isHighlighted ? UIControlState.highlighted.rawValue : UIControlState.normal.rawValue]
            isSettingBackgroundColor = false
            
            if isLoading {
                activityIndicator?.backgroundColor = self.backgroundColor
            }
        }
    }
    
    // MARK: Background Color
    
    override var backgroundColor: UIColor? {
        didSet {
            if !isSettingBackgroundColor {
                backgroundColorStates[UIControlState.normal.rawValue] = backgroundColor
                backgroundColorStates[UIControlState.highlighted.rawValue] = backgroundColor?.darker()
            }
        }
    }
    
    // MARK: Image
    
    override func setImage(_ image: UIImage?, for state: UIControlState) {
        super.setImage(image, for: state)
        
        imageEdgeInsets = UIEdgeInsets(top: 0, left: -imagePadding, bottom: 0, right: imagePadding / 2.0)
        titleEdgeInsets = UIEdgeInsets(top: 0, left: imagePadding / 2.0, bottom: 0, right: -imagePadding)
        
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
