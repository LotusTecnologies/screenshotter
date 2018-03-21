//
//  MainButton.swift
//  screenshot
//
//  Created by Corey Werner on 9/4/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit

class MainButton: UIButton {
    private var backgroundColorStates: [UInt : UIColor] = [:]
    private var isSettingBackgroundColor = false
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .crazeRed
        contentEdgeInsets = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
        adjustsImageWhenHighlighted = false
        titleLabel?.font = UIFont(screenshopName: .hindMedium, size: UIFont.buttonFontSize)
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
    
    // MARK: States
    
    override var isHighlighted: Bool {
        didSet {
            setBackgroundColor(to: isHighlighted ? .highlighted : state)
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            setBackgroundColor(to: isEnabled ? state : .disabled)
        }
    }
    
    // MARK: Background Color
    
    override var backgroundColor: UIColor? {
        didSet {
            if !isSettingBackgroundColor {
                backgroundColorStates[UIControlState.normal.rawValue] = backgroundColor
                backgroundColorStates[UIControlState.highlighted.rawValue] = backgroundColor?.darker()
                backgroundColorStates[UIControlState.disabled.rawValue] = backgroundColor?.lighter().withAlphaComponent(0.7)
            }
        }
    }
    
    fileprivate func setBackgroundColor(to state: UIControlState) {
        isSettingBackgroundColor = true
        backgroundColor = backgroundColorStates[state.rawValue]
        isSettingBackgroundColor = false
        
        if isLoading {
            activityIndicator?.backgroundColor = backgroundColor
        }
    }
    
    // MARK: Image
    
    override func setImage(_ image: UIImage?, for state: UIControlState) {
        super.setImage(image, for: state)
        
        let imagePadding: CGFloat = 6
        
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
