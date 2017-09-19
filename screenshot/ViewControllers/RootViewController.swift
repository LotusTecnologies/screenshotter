//
//  RootViewController.swift
//  screenshot
//
//  Created by Jacob Relkin on 9/18/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit

class RootViewController : UIViewController {
    private(set) var childViewController: UIViewController {
        didSet {
            if !childViewControllers.contains(childViewController) {
                addChildViewController(childViewController)
                view.addSubview(childViewController.view)
                childViewController.didMove(toParentViewController: self)
            }
        }
    }
    
    required init(childViewController child:UIViewController) {
        childViewController = child
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func transition(toViewController: UIViewController) {
        let options: UIViewAnimationOptions = [.transitionFlipFromLeft, .allowAnimatedContent, .layoutSubviews]
        UIView.transition(from: childViewController.view,
                          to: toViewController.view,
                          duration: 0.5,
                          options: options) { (finished) in
            self.childViewController.removeFromParentViewController()
            self.childViewController.view.removeFromSuperview()
            self.childViewController = toViewController
        }

    }
}
