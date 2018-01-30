//
//  ProductWebViewController.swift
//  screenshot
//
//  Created by Corey Werner on 1/25/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation

class ProductWebViewController : WebViewController {
    static let shared = ProductWebViewController()
    
    fileprivate let favoriteButton = FavoriteButton()
    
    var product: Product? {
        didSet {
            if let product = product {
                favoriteButton.isSelected = product.isFavorite
                
            } else {
                favoriteButton.isSelected = false
            }
        }
    }
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        favoriteButton.sizeToFit()
        favoriteButton.addTarget(self, action: #selector(favoriteAction), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: favoriteButton)
        
        hidesBottomBarWhenPushed = true
        
        addNavigationItemLogo()
        loaderLabelText = "webview.product.loading".localized
    }
    
    @objc fileprivate func favoriteAction() {
        guard let product = product else {
            return
        }
        
        let isFavorited = favoriteButton.isSelected
        
        product.setFavorited(toFavorited: isFavorited)
        AnalyticsTrackers.standard.trackFavorited(isFavorited, product: product, onPage: "Product Web View")
    }
}
