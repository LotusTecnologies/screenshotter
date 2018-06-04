//
//  InterViewTransitioning.swift
//  screenshot
//
//  Created by Jonathan Rose on 6/4/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
protocol InterViewAnimatable {
    var interTransitionView: UIView? { get }
}

class InterViewTransitioning: NSObject, UIViewControllerAnimatedTransitioning{
    var transitionDuration: TimeInterval = 0.25
    var isPresenting: Bool = false

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return transitionDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        
        guard
            let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to) else {
                transitionContext.completeTransition(false)
                return
        }
        let _ = fromVC.view
        let _ = toVC.view
        
        guard let fromTargetView = targetView(in: fromVC), let toTargetView = targetView(in: toVC) else {
            transitionContext.completeTransition(false)
            return
        }
        
        guard let fromImage = fromTargetView.caSnapshot(), let toImage = toTargetView.caSnapshot() else {
            transitionContext.completeTransition(false)
            return
        }
        
        let fromImageView = UIImageView(image: fromImage)
        fromImageView.clipsToBounds = true
        
        let toImageView = UIImageView(image: toImage)
        toImageView.clipsToBounds = true
        
        let startFrame = fromTargetView.frameIn(containerView)
        let endFrame = toTargetView.frameIn(containerView)
        
        fromImageView.frame = startFrame
        toImageView.frame = startFrame
        
        let cleanupClosure: () -> Void = {
            fromTargetView.isHidden = false
            toTargetView.isHidden = false
            fromImageView.removeFromSuperview()
            toImageView.removeFromSuperview()
        }
        
        let updateFrameClosure: () -> Void = {
            // https://stackoverflow.com/a/27997678/1418981
            // In order to have proper layout. Seems mostly needed when presenting.
            // For instance during presentation, destination view does'n account navigation bar height.
            toVC.view.setNeedsLayout()
            toVC.view.layoutIfNeeded()
            
            // Workaround wrong origin due ongoing layout process.
            let updatedEndFrame = toTargetView.frameIn(containerView)
            let correctedEndFrame = CGRect(origin: updatedEndFrame.origin, size: endFrame.size)
            fromImageView.frame = correctedEndFrame
            toImageView.frame = correctedEndFrame
        }
        
        let alimationBlock: (() -> Void)
        let completionBlock: ((Bool) -> Void)
        
        fromTargetView.isHidden = true
        toTargetView.isHidden = true
        
        if isPresenting {
            guard let toView = transitionContext.view(forKey: .to) else {
                transitionContext.completeTransition(false)
                return
            }
            [toView, toImageView, fromImageView].forEach{ containerView.addSubview($0)}
            toView.frame = CGRect(origin: .zero, size: containerView.bounds.size)
            toView.alpha = 0
            alimationBlock = {
                toView.alpha = 1
                fromImageView.alpha = 0
                updateFrameClosure()
            }
            completionBlock = { _ in
                let success = !transitionContext.transitionWasCancelled
                if !success {
                    toView.removeFromSuperview()
                }
                cleanupClosure()
                transitionContext.completeTransition(success)
            }
        } else {
            guard let fromView = transitionContext.view(forKey: .from) else {
                transitionContext.completeTransition(false)
                return
            }
            [toImageView, fromImageView].forEach{ containerView.addSubview($0)}
            alimationBlock = {
                fromView.alpha = 0
                fromImageView.alpha = 0
                updateFrameClosure()
            }
            completionBlock = { _ in
                let success = !transitionContext.transitionWasCancelled
                if success {
                    fromView.removeFromSuperview()
                }
                cleanupClosure()
                transitionContext.completeTransition(success)
            }
        }
        
        // TODO: Add more precise animation (i.e. Keyframe)
        if isPresenting {
            UIView.animate(withDuration: transitionDuration, delay: 0, options: .curveEaseIn,
                           animations: alimationBlock, completion: completionBlock)
        } else {
            UIView.animate(withDuration: transitionDuration, delay: 0, options: .curveEaseOut,
                           animations: alimationBlock, completion: completionBlock)
        }
    }
    
    private func targetView(in viewController: UIViewController) -> UIView? {
        if let view = (viewController as? InterViewAnimatable)?.interTransitionView {
            return view
        }
        if let nc = viewController as? UINavigationController, let vc = nc.topViewController,
            let view = (vc as? InterViewAnimatable)?.interTransitionView {
            return view
        }
        return nil
    }
}
fileprivate extension UIView {
    
    // https://medium.com/@joesusnick/a-uiview-extension-that-will-teach-you-an-important-lesson-about-frames-cefe1e4beb0b
     func frameIn(_ view: UIView?) -> CGRect {
        if let superview = superview {
            return superview.convert(frame, to: view)
        }
        return frame
    }
}


fileprivate extension UIView {
    
    /// The method drawViewHierarchyInRect:afterScreenUpdates: performs its operations on the GPU as much as possible
    /// In comparison, the method renderInContext: performs its operations inside of your app’s address space and does
    /// not use the GPU based process for performing the work.
    /// https://stackoverflow.com/a/25704861/1418981
     func caSnapshot(scale: CGFloat = 0, isOpaque: Bool = false) -> UIImage? {
        var isSuccess = false
        UIGraphicsBeginImageContextWithOptions(bounds.size, isOpaque, scale)
        if let context = UIGraphicsGetCurrentContext() {
            layer.render(in: context)
            isSuccess = true
        }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return isSuccess ? image : nil
    }
}
