//
//  Geometry.swift
//  screenshot
//
//  Created by Jacob Relkin on 10/22/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation
import UIKit

extension CGFloat {
    static let padding = CGFloat(16)
    static let extendedPadding:CGFloat = CGFloat(UIDevice.is480h ? 20 : 40)
    
    static let halfPoint = CGFloat(UIScreen.main.scale > 1 ? 0.5 : 1)
    
    static let defaultCornerRadius = CGFloat(6)
}

extension CGRect {
    func scaleToAspectFit(in rtarget: CGRect) -> CGFloat {
        // first try to match width
        let s = rtarget.width / self.width;
        // if we scale the height to make the widths equal, does it still fit?
        if self.height * s <= rtarget.height {
            return s
        }
        // no, match height instead
        return rtarget.height / self.height
    }
    
    func aspectFit(in rtarget: CGRect) -> CGRect {
        let s = scaleToAspectFit(in: rtarget)
        let w = width * s
        let h = height * s
        let x = rtarget.midX - w / 2
        let y = rtarget.midY - h / 2
        return CGRect(x: x, y: y, width: w, height: h)
    }
    
    func scaleToAspectFit(around rtarget: CGRect) -> CGFloat {
        // fit in the target inside the rectangle instead, and take the reciprocal
        return 1 / rtarget.scaleToAspectFit(in: self)
    }
    
    func aspectFit(around rtarget: CGRect) -> CGRect {
        let s = scaleToAspectFit(around: rtarget)
        let w = width * s
        let h = height * s
        let x = rtarget.midX - w / 2
        let y = rtarget.midY - h / 2
        return CGRect(x: x, y: y, width: w, height: h)
    }
}
