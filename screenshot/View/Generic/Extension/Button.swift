//
//  Button.swift
//  screenshot
//
//  Created by Corey Werner on 4/12/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

extension UIButton {
    func adjustInsetsForImage(withPadding padding: CGFloat) {
        imageEdgeInsets = UIEdgeInsets(top: 0, left: -padding, bottom: 0, right: padding / 2)
        titleEdgeInsets = UIEdgeInsets(top: 0, left: padding / 2, bottom: 0, right: -padding)
        
        var contentInsets = contentEdgeInsets
        contentInsets.left += imageEdgeInsets.right
        contentInsets.right += titleEdgeInsets.left
        contentEdgeInsets = contentInsets
    }
}
