//
//  FavoritesNavigationController.swift
//  screenshot
//
//  Created by Corey Werner on 12/27/17.
//  Copyright (c) 2017 crazeapp. All rights reserved.
//

import Foundation
import UIKit

class FavoritesNavigationController : UINavigationController {
    let favoritesViewController = FavoriteProductsViewController()
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        restorationIdentifier = "FavoritesNavigationController"
        
        viewControllers = [favoritesViewController]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .background
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        favoritesViewController.clearMarkedAsUnfavorite()
        self.popToRootViewController(animated: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UniversalSearchController.shared.updateInboxBadgeCount()
    }
}

