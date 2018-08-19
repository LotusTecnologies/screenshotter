//
//  UIScrollView.swift
//  Screenshop
//
//  Created by Corey Werner on 8/15/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

extension UIScrollView {
    func resetContentOffset() {
        var offset: CGPoint = .zero
        
        if #available(iOS 11.0, *) {
            offset.y = -safeAreaInsets.top
        }
        else {
            offset.y = -contentInset.top
        }
        
        contentOffset = offset
    }
}
