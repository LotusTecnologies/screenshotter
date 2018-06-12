//
//  ModalAnimatedTransitioning.swift
//  screenshot
//
//  Created by Corey Werner on 3/11/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit

class ModalAnimatedTransitioning: ViewControllerAnimatedTransitioning {
    override func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toViewController = transitionContext.viewController(forKey: .to),
            let toView = toViewController.view,
            let fromView = transitionContext.viewController(forKey: .from)?.view
            else {
                return
        }
        
        let containerView = transitionContext.containerView
        let duration = transitionDuration(using: transitionContext)
        
        if isPresenting {
            fromView.isUserInteractionEnabled = false
            
            let viewFinalRect = transitionContext.finalFrame(for: toViewController)
            
            var rect = viewFinalRect
            rect.origin.y = containerView.bounds.size.height
            toView.frame = rect
            
            containerView.addSubview(toView)
            
            UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveLinear, animations: {
                toView.frame = viewFinalRect
                
            }, completion: { finished in
                fromView.isUserInteractionEnabled = true
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
        }
        else {
            toView.isUserInteractionEnabled = true
            
            var rect = fromView.frame
            rect.origin.y = containerView.bounds.size.height
            
            UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveLinear, animations: {
                fromView.frame = rect
                
            }, completion: { finished in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
        }
    }
}
