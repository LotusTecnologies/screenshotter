//
//  UIImage.swift
//  Screenshop
//
//  Created by Corey Werner on 8/1/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

extension UIImage {
    func reposition(withInsets insets: UIEdgeInsets) -> UIImage? {
        let width = size.width + insets.left + insets.right
        let height = size.height + insets.top + insets.bottom
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, scale)
        UIGraphicsGetCurrentContext()
        draw(at: CGPoint(x: insets.left, y: insets.top))
        let imageWithInsets = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return imageWithInsets
    }
}
