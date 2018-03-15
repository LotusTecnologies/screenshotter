//
//  ShowProduct.swift
//  screenshot
//
//  Created by Jonathan Rose on 3/14/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

extension UIViewController {
    
    @discardableResult func presentProduct(_ product: Product, from:String) -> ProductViewController? {
        AnalyticsTrackers.standard.trackTappedOnProduct(product, onPage: from)
        
        if product.partNumber != nil {
            let productViewController = ProductViewController(productOID: product.objectID)
            productViewController.title = product.displayTitle
            productViewController.setup(with: product)
            navigationController?.pushViewController(productViewController, animated: true)
            return productViewController
        }
        else {
            OpenWebPage.presentProduct(product, fromViewController: self)
        }
        
        return nil
    }
}
