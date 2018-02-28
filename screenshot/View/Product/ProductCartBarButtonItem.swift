//
//  ProductCartBarButtonItem.swift
//  screenshot
//
//  Created by Corey Werner on 2/28/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class ProductCartBarButtonItem: UIBarButtonItem {
    fileprivate let countLabel = UILabel()
    
    convenience init(target: Any?, action: Selector?) {
        let image = UIImage(named: "ProductCart")?.withRenderingMode(.alwaysTemplate)
        
        self.init(image: image, style: .plain, target: target, action: action)
    }
    
    var count: UInt = 0 {
        didSet {
            switch count {
            case 1 ... 99:
                countLabel.text = "\(count)"
                
            case _ where count > 99:
                countLabel.text = "99+"
                
            default:
                countLabel.text = nil
            }
            
            syncImageTintColor()
        }
    }
    
    var view: UIView? {
        didSet {
            guard let view = view else {
                return
            }
            
            countLabel.translatesAutoresizingMaskIntoConstraints = false
            countLabel.textColor = .crazeRed
            countLabel.textAlignment = .right
            countLabel.font = .systemFont(ofSize: 12)
            view.addSubview(countLabel)
            countLabel.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            countLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            countLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            
            syncImageTintColor()
        }
    }
    
    fileprivate func syncImageTintColor() {
        guard let view = view, let tintView = view.subviews.first else {
            return
        }
        
        if count > 0 {
            tintView.tintColor = .crazeRed
        }
        else {
            tintView.tintColor = UINavigationBar.appearance().tintColor
        }
    }
}
