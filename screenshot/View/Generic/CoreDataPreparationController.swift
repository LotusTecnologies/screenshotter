//
//  CoreDataPreparationController.swift
//  screenshot
//
//  Created by Corey Werner on 1/31/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation

@objc protocol CoreDataPreparationControllerDelegate : NSObjectProtocol {
    func coreDataPreparationControllerSetup(_ controller: CoreDataPreparationController)
    func coreDataPreparationController(_ controller: CoreDataPreparationController, presentLoader loader: UIView)
    func coreDataPreparationController(_ controller: CoreDataPreparationController, dismissLoader loader: UIView)
}

class CoreDataPreparationController : NSObject {
    weak var delegate: CoreDataPreparationControllerDelegate?
    
    fileprivate var loader: UIView?
    
    override init() {
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(coreDataStackCompleted(_:)), name: NSNotification.Name(NotificationCenterKeys.coreDataStackCompleted), object: nil)
    }
    
    /// Call at the end of the viewController.viewDidLoad()
    func viewDidLoad() {
        if DataModel.sharedInstance.isCoreDataStackReady {
            self.delegate?.coreDataPreparationControllerSetup(self)
        }
        else {
            let loader = UIView()
            loader.backgroundColor = .green
            self.loader = loader
            self.delegate?.coreDataPreparationController(self, presentLoader: loader)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func coreDataStackCompleted(_ notification: Notification) {
        guard notification.userInfo?["error"] == nil else {
            return
        }
        
        self.delegate?.coreDataPreparationControllerSetup(self)
        
        if let loader = loader {
            self.delegate?.coreDataPreparationController(self, dismissLoader: loader)
        }
        
//        loader = nil
    }
}
