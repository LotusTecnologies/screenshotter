//
//  Loader.swift
//  screenshot
//
//  Created by Corey Werner on 11/7/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation
import UIKit

class Loader: UIView {
    private let activityView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    
    private let activityTransform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        activityView.translatesAutoresizingMaskIntoConstraints = false
        activityView.hidesWhenStopped = false
        activityView.color = .gray6
        activityView.transform = activityTransform
        addSubview(activityView)
        activityView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        activityView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        activityView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        activityView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        activityView.widthAnchor.constraint(equalToConstant: intrinsicContentSize.width).isActive = true
        activityView.heightAnchor.constraint(equalToConstant: intrinsicContentSize.height).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    override var intrinsicContentSize: CGSize {
        return activityView.intrinsicContentSize.applying(activityTransform)
    }
    
    var color: UIColor? {
        set {
            activityView.color = newValue
        }
        get {
            return activityView.color
        }
    }
    
    func startAnimation() {
        activityView.startAnimating()
    }
    
    func stopAnimation() {
        activityView.stopAnimating()
    }
    
    var isAnimating: Bool {
        return activityView.isAnimating
    }
}
