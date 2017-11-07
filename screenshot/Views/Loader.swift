//
//  Loader.swift
//  screenshot
//
//  Created by Corey Werner on 11/7/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

class Loader: UIView {
    let activityView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        activityView.translatesAutoresizingMaskIntoConstraints = false
        activityView.hidesWhenStopped = false
        activityView.color = .gray6
        addSubview(activityView)
        activityView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        activityView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        activityView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        activityView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }
    
    override var intrinsicContentSize: CGSize {
        return activityView.intrinsicContentSize
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
