//
//  ProductWebViewController.swift
//  screenshot
//
//  Created by Corey Werner on 1/25/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import UIKit

class ProductWebViewController : WebViewController {
    static let shared = ProductWebViewController()
    
    fileprivate let favoriteControl = FavoriteControl()
    
    var product: Product? {
        didSet {
            if let product = product {
                favoriteControl.isSelected = product.isFavorite
                
            } else {
                favoriteControl.isSelected = false
            }
        }
    }
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        favoriteControl.sizeToFit()
        favoriteControl.addTarget(self, action: #selector(favoriteAction), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: favoriteControl)
        
        hidesBottomBarWhenPushed = true
        
        addNavigationItemLogo()
        loaderLabelText = "webview.product.loading".localized
    }
    
    @objc fileprivate func favoriteAction() {
        guard let product = product else {
            return
        }
        
        let isFavorited = favoriteControl.isSelected
        
        product.setFavorited(toFavorited: isFavorited)
        if isFavorited {
            Analytics.trackProductFavorited(product: product, page: .productWebView)
        }else{
            Analytics.trackProductUnfavorited(product: product, page: .productWebView)
        }
    }
}
