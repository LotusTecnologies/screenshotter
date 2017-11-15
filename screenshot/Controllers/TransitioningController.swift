//
//  TransitioningController.swift
//  screenshot
//
//  Created by Corey Werner on 11/15/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

class TransitioningController : NSObject, UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return InsetPresentationController(presentedViewController: presented, presenting: presenting)
    }
}
