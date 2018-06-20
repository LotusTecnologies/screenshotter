//
//  ViewControllerAnimatedTransitioning.swift
//  screenshot
//
//  Created by Corey Werner on 3/11/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit

class ViewControllerAnimatedTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
    let isPresenting: Bool
    
    init(presenting: Bool) {
        isPresenting = presenting
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
    }
}
