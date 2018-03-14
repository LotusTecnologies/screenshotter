//
//  DimmedPresentationController.swift
//  screenshot
//
//  Created by Corey Werner on 3/11/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class DimmedPresentationController: UIPresentationController {
    lazy var dimmedView: UIView = {
        let view = UIView()
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        return view
    }()
    
    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        
        guard let containerView = containerView, let presentedView = presentedView else {
            return
        }
        
        dimmedView.frame = containerView.bounds
        dimmedView.alpha = 0
        
        containerView.addSubview(dimmedView)
        containerView.addSubview(presentedView)
        
        presentingViewController.transitionCoordinator?.animate(alongsideTransition: { context in
            self.dimmedView.alpha = 1
        })
    }
    
    override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        
        if !completed {
            dimmedView.removeFromSuperview()
        }
    }
    
    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        
        presentingViewController.transitionCoordinator?.animate(alongsideTransition: { context in
            self.dimmedView.alpha = 0
        })
    }
    
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
        
        if completed {
            dimmedView.removeFromSuperview()
        }
    }
}
