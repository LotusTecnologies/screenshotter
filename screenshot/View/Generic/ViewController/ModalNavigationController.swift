//
//  ModalNavigationController.swift
//  screenshot
//
//  Created by Corey Werner on 2/28/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class ModalNavigationController: UINavigationController {
    let dismissBarButtonItem = UIBarButtonItem(title: "generic.cancel".localized, style: .plain, target: nil, action: nil)
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        // Needed for init.rootViewController
    }
    
    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        connectDismissBarButtonItem()
    }
    
    override var viewControllers: [UIViewController] {
        didSet {
            connectDismissBarButtonItem()
        }
    }
    
    private func connectDismissBarButtonItem() {
        guard let viewController = viewControllers.first else {
            return
        }
        
        dismissBarButtonItem.target = self
        dismissBarButtonItem.action = #selector(dismissViewController)
        viewController.navigationItem.leftBarButtonItem = dismissBarButtonItem
    }
    
    @objc private func dismissViewController() {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
}
