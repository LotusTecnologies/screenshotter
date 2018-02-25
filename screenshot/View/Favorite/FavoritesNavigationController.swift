//
//  FavoritesNavigationController.swift
//  screenshot
//
//  Created by Corey Werner on 12/27/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation
import UIKit

class FavoritesNavigationController : UINavigationController {
    let favoritesViewController = FavoritesViewController()
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        restorationIdentifier = "FavoritesNavigationController"
        
        favoritesViewController.delegate = self
        
        viewControllers = [favoritesViewController]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .background
    }
}

extension FavoritesNavigationController : FavoritesViewControllerDelegate {
    func favoritesViewController(_ viewController: FavoritesViewController, didSelectItemAt indexPath: IndexPath) {
        guard let screenshot = viewController.screenshot(at: indexPath) else {
            return
        }
        
        let favoriteProductsViewController = FavoriteProductsViewController()
        favoriteProductsViewController.products = screenshot.favoritedProducts
        favoriteProductsViewController.hidesBottomBarWhenPushed = true
        pushViewController(favoriteProductsViewController, animated: true)
    }
}
