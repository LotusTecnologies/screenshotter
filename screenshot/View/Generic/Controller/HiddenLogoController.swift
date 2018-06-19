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
        imageView.backgroundColor = .red
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
        view.topAnchor.constraint(equalTo: statusBarView.topAnchor).isActive = true
        view.leadingAnchor.constraint(equalTo: statusBarView.leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: statusBarView.trailingAnchor).isActive = true
        view.heightAnchor.constraint(equalToConstant: 10).isActive = true
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
