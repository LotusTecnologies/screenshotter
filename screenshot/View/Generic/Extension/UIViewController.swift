//
//  UIViewController.swift
//  screenshot
//
//  Created by Corey Werner on 6/6/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

extension UIViewController {
    static let navigationBarLogoTag = 28
    
    func addNavigationItemLogo() {
        self.navigationItem.titleView = UIImageView(image: UIImage(named: "BrandLogo20h"))
        self.navigationItem.titleView?.tag = UIViewController.navigationBarLogoTag
    }
}
