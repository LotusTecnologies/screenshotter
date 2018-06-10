//
//  ViewControllerTransitioningDelegate.swift
//  screenshot
//
//  Created by Corey Werner on 3/11/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class ViewControllerTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    enum Presentation {
        case none
        case dimmed
        case intrinsicContentSize
    }
    
    enum Transition {
        case none
        case modal
    }
    
    let presentation: Presentation
    let transition: Transition
    
    init(presentation: Presentation = .none, transition: Transition = .none) {
        self.presentation = presentation
        self.transition = transition
        super.init()
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        switch presentation {
        case .none:
            return nil
        case .dimmed:
            return DimmedPresentationController(presentedViewController: presented, presenting: presenting)
        case .intrinsicContentSize:
            return IntrinsicContentSizePresentationController(presentedViewController: presented, presenting: presenting)
        }
    }
    
    func animationController(isPresenting: Bool) -> UIViewControllerAnimatedTransitioning? {
        switch transition {
        case .none:
            return nil
        case .modal:
            return ModalAnimatedTransitioning(presenting: isPresenting)
        }
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return animationController(isPresenting: true)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return animationController(isPresenting: false)
    }
}
