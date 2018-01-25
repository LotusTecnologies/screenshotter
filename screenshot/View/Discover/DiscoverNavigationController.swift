//
//  DiscoverNavigationController.swift
//  screenshot
//
//  Created by Corey Werner on 1/24/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation

class DiscoverNavigationController : UINavigationController, ViewControllerLifeCycle {
    let discoverScreenshotViewController = DiscoverScreenshotViewController()
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        discoverScreenshotViewController.delegate = self
        
        viewControllers = [discoverScreenshotViewController]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .background
    }
    
    func viewController(_ viewController: UIViewController, didDisappear animated: Bool) {
        if viewController.isKind(of: ProductsViewController.self) && topViewController == discoverScreenshotViewController {
            discoverScreenshotViewController.completeDecision()
        }
    }
}

extension DiscoverNavigationController : DiscoverScreenshotViewControllerDelegate {
    func discoverScreenshotViewController(_ viewController: DiscoverScreenshotViewController, didSelectItemAtIndexPath indexPath: IndexPath) {
        discoverScreenshotViewController.decidedToAdd { screenshot in
            let productsViewController = ProductsViewController()
            productsViewController.lifeCycleDelegate = self
            productsViewController.screenshot = screenshot
            productsViewController.hidesBottomBarWhenPushed = true
            
            self.pushViewController(productsViewController, animated: true)
            
            if screenshot.isNew {
                screenshot.setViewed()
            }
        }
    }
}
