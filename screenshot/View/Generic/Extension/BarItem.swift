//
//  BarItem.swift
//  screenshot
//
//  Created by Corey Werner on 11/1/17.
//  Copyright (c) 2017 crazeapp. All rights reserved.
//

import UIKit

extension UIBarButtonItem {
    static let preferredWidth: CGFloat = 60
    
    convenience init(image: UIImage?, edge: UIRectEdge, target: Any?, action: Selector?) {
        let preferredWidth = UIBarButtonItem.preferredWidth
        let inset: CGFloat = preferredWidth - (image?.size.width ?? 0)
        
        var insets: UIEdgeInsets = .zero
        if edge == .left {
            insets.right = inset
        }
        else if edge == .right {
            insets.left = inset
        }
        
        if #available(iOS 11.0, *) {
            self.init(image: image, style: .plain, target: target, action: action)
            width = preferredWidth
            imageInsets = insets
        }
        else {
            // iOS 10 has issues laying out item using the width and imageInsets properties.
            // Extend the image's width to include the imageInsets. Setting the width is to
            // help reposition the BadgeBarButtonItem.
            
            let originalWidth = image?.size.width ?? 0
            let expandedImage = image?.reposition(withInsets: insets)
            self.init(image: expandedImage, style: .plain, target: target, action: action)
            
            if edge == .left {
                width = originalWidth
            }
        }
    }
  
    convenience init(title: String?, edge: UIRectEdge, target: Any?, action: Selector?) {
        self.init(title: title, style: .plain, target: target, action: action)
    }

    convenience init(barButtonSystemItem systemItem: UIBarButtonSystemItem, edge: UIRectEdge, target: Any?, action: Selector?) {
        self.init(barButtonSystemItem: systemItem, target: target, action: action)
    }
    
    var targetView: UIView? {
        guard let view = value(forKey: "view") as? UIView else {
            return nil
        }
        return view
    }
}

extension UITabBarItem {
    var targetView: UIView? {
        guard let view = value(forKey: "view") as? UIView else {
            return nil
        }
        return view
    }
}
