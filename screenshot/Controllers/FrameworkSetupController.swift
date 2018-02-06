//
//  FrameworkSetupController.swift
//  screenshot
//
//  Created by Corey Werner on 2/4/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation

protocol FrameworkSetupControllerDelegate : NSObjectProtocol {
    /// Called when the application first launches.
    func frameworkSetupControllerImmediate(_ controller: FrameworkSetupController)
    
    /// Called only for the first view controller to appear.
    func frameworkSetupControllerInitialViewDidAppear(_ controller: FrameworkSetupController)
    
    /// Called whenever the root view controller changes and appears.
    func frameworkSetupControllerRootViewDidAppear(_ controller: FrameworkSetupController)
}

class FrameworkSetupController : NSObject {
    weak var delegate: FrameworkSetupControllerDelegate?
    
    private var didCallInitialViewDidAppear = false
    
    private var isWaitingForRootViewController = false
    
    /// Call when a new view controller becomes the windows root.
    func setIsWaitingForRootViewController() {
        isWaitingForRootViewController = true
    }
    
    private(set) var launchOptions: [UIApplicationLaunchOptionsKey : Any]?
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) {
        self.launchOptions = launchOptions
        delegate?.frameworkSetupControllerImmediate(self)
    }
    
    func viewController(_ viewController: UIViewController, didAppear animated: Bool) {
        if !didCallInitialViewDidAppear {
            didCallInitialViewDidAppear = true
            delegate?.frameworkSetupControllerInitialViewDidAppear(self)
        }
        
        if isWaitingForRootViewController {
            isWaitingForRootViewController = false
            delegate?.frameworkSetupControllerRootViewDidAppear(self)
        }
    }
}
