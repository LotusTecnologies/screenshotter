//
//  UIApplication.swift
//  screenshot
//
//  Created by Corey Werner on 3/28/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit

extension UIApplication {
    static func enableSlowAnimations() {
        guard isDev else {
            return
        }
        
        shared.windows.first?.layer.speed = 0.1
    }
    
    static func disableSlowAnimations() {
        guard isDev else {
            return
        }
        
        shared.windows.first?.layer.speed = 1
    }
    
    var statusBarView: UIView? {
        return value(forKey: "statusBar") as? UIView
    }
    
    static func topViewController(startingWith viewController: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = viewController as? UINavigationController {
            return topViewController(startingWith: navigationController.visibleViewController)
        }
        else if let tabBarController = viewController as? UITabBarController {
            if let selectedViewController = tabBarController.selectedViewController {
                return topViewController(startingWith: selectedViewController)
            }
        }
        else if let presentedViewController = viewController?.presentedViewController {
            return topViewController(startingWith: presentedViewController)
        }
        return viewController
    }
}
