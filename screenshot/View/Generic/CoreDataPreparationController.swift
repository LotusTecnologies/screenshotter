//
//  CoreDataPreparationController.swift
//  screenshot
//
//  Created by Corey Werner on 1/31/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

protocol CoreDataPreparationControllerDelegate : NSObjectProtocol {
    func coreDataPreparationControllerSetup(_ controller: CoreDataPreparationController)
    func coreDataPreparationController(_ controller: CoreDataPreparationController, presentLoader loader: UIView)
    func coreDataPreparationController(_ controller: CoreDataPreparationController, dismissLoader loader: UIView)
}

class CoreDataPreparationController : NSObject {
    weak var delegate: CoreDataPreparationControllerDelegate?
    
    fileprivate var loader: UIView?
    
    override init() {
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(coreDataStackCompleted(_:)), name: .coreDataStackCompleted, object: nil)
    }
    
    /// Call at the end of the viewController.viewDidLoad()
    func viewDidLoad() {
        if DataModel.sharedInstance.isCoreDataStackReady {
            self.delegate?.coreDataPreparationControllerSetup(self)
        }
        else {
            let loaderContainer = UIView()
            loaderContainer.backgroundColor = .background
            self.loader = loaderContainer
            
            let loader = Loader()
            loader.translatesAutoresizingMaskIntoConstraints = false
            loader.startAnimation()
            loaderContainer.addSubview(loader)
            loader.centerXAnchor.constraint(equalTo: loaderContainer.centerXAnchor).isActive = true
            loader.centerYAnchor.constraint(equalTo: loaderContainer.centerYAnchor).isActive = true
            
            self.delegate?.coreDataPreparationController(self, presentLoader: loaderContainer)
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
            self.loader = nil
        }
    }
}
