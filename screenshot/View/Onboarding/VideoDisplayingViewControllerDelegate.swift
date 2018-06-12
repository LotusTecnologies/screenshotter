//
//  VideoDisplayingViewControllerDelegate.swift
//  screenshot
//
//  Created by Jonathan Rose on 4/18/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import Foundation
import UIKit

protocol VideoDisplayingViewControllerDelegate : class {
    func videoDisplayingViewControllerDidPause(_ viewController:UIViewController)
    func videoDisplayingViewControllerDidPlay(_ viewController:UIViewController)
    func videoDisplayingViewControllerDidEnd(_ viewController:UIViewController)
    
    func videoDisplayingViewControllerDidTapDone(_ viewController:UIViewController)
}

extension VideoDisplayingViewControllerDelegate {
    func videoDisplayingViewControllerDidPause(_ viewController:UIViewController){
        
    }
    func videoDisplayingViewControllerDidPlay(_ viewController:UIViewController){
        
    }
    func videoDisplayingViewControllerDidEnd(_ viewController:UIViewController){
        
    }
    
    func videoDisplayingViewControllerDidTapDone(_ viewController:UIViewController){
        
    }
}
