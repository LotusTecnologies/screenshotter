//
//  DiscoverNavigationController.swift
//  screenshot
//
//  Created by Corey Werner on 1/24/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import Foundation
import UIKit

class DiscoverNavigationController : UINavigationController, ViewControllerLifeCycle {
    let discoverScreenshotViewController = DiscoverScreenshotViewController()
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        restorationIdentifier = String(describing: type(of: self))
        
        discoverScreenshotViewController.delegate = self
        
        viewControllers = [discoverScreenshotViewController]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .background
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UniversalSearchController.shared.updateInboxBadgeCount()
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
            Analytics.trackOpenedScreenshot(screenshot: screenshot, source: .discover)
            let productsViewController = ProductsViewController.init(screenshot: screenshot)
            productsViewController.lifeCycleDelegate = self
            productsViewController.hidesBottomBarWhenPushed = true
            
            self.pushViewController(productsViewController, animated: true)
            
            if screenshot.isNew {
                screenshot.setViewed()
            }
        }
    }
}
