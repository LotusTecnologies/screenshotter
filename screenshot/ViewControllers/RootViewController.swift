//
//  RootViewController.swift
//  screenshot
//
//  Created by Jacob Relkin on 9/18/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit

class RootViewController : UIViewController {
    var containedViewController: UIViewController? {
        didSet {
            guard let cvc = containedViewController else {
                return
            }
            
            self.addChildViewController(cvc)
            self.view.addSubview(cvc.view)
        }
    }
    
    func transition(toViewController: UIViewController) {
        let options: UIViewAnimationOptions = [.transitionFlipFromLeft, .allowAnimatedContent, .layoutSubviews]
        if let fromView = containedViewController?.view {
            UIView.transition(from: fromView, to: toViewController.view, duration: 0.5, options: options) { (finished) in
                self.containedViewController?.removeFromParentViewController()
                self.containedViewController?.view.removeFromSuperview()
                self.containedViewController = toViewController
            }
        }

    }
}
