//
//  FavoritesNavigationController.swift
//  screenshot
//
//  Created by Corey Werner on 12/27/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

class FavoritesNavigationController : UINavigationController, ViewControllerLifeCycle {
    let favoritesViewController = FavoritesViewController()
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        favoritesViewController.delegate = self
        
        viewControllers = [favoritesViewController]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .background
    }
    
    func viewController(_ viewController: UIViewController, willDisappear animated: Bool) {
        if let favoriteProductsViewController = viewController as? FavoriteProductsViewController {
//            favoriteProductsViewController.removeUnfavorited()
//            favoritesViewController.
        }
    }
}

extension FavoritesNavigationController : FavoritesViewControllerDelegate {
    func favoritesViewController(_ viewController: FavoritesViewController, didSelectItemAt indexPath: IndexPath) {
        guard let screenshot = viewController.screenshot(at: indexPath) else {
            return
        }
        
        let favoriteProductsViewController = FavoriteProductsViewController()
        favoriteProductsViewController.lifeCycleDelegate = self
        favoriteProductsViewController.products = viewController.products(for: screenshot)
        favoriteProductsViewController.hidesBottomBarWhenPushed = true
        pushViewController(favoriteProductsViewController, animated: true)
    }
}
