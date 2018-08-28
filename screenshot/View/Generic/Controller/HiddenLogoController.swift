//
//  HiddenLogoController.swift
//  screenshot
//
//  Created by Corey Werner on 6/19/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class HiddenLogoController {
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "BrandLogo20h")
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()
    
    var view: UIView? {
        return UIDevice.current.isIphoneX ? imageView : nil
    }
    
    func addView() {
        guard let statusBarView = UIApplication.shared.statusBarView, let view = view else {
            return
        }
        
        statusBarView.addSubview(view)
        view.leadingAnchor.constraint(greaterThanOrEqualTo: statusBarView.leadingAnchor, constant: 84).isActive = true
        view.bottomAnchor.constraint(equalTo: statusBarView.topAnchor, constant: 30).isActive = true
        view.trailingAnchor.constraint(lessThanOrEqualTo: statusBarView.trailingAnchor, constant: -84).isActive = true
        view.heightAnchor.constraint(equalToConstant: 14).isActive = true
        view.centerXAnchor.constraint(equalTo: statusBarView.centerXAnchor).isActive = true
    }
    
    func removeView() {
        view?.removeFromSuperview()
    }
    
    func syncView() {
        guard let viewController = UIApplication.topViewController() else {
            return
        }
        
        if viewController.navigationItem.titleView?.tag == UIViewController.navigationBarLogoTag {
            removeView()
        }
        else {
            addView()
        }
    }
}
