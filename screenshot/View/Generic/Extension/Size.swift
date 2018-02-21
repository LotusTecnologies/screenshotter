//
//  Size.swift
//  screenshot
//
//  Created by Corey Werner on 1/1/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import UIKit

extension CGSize {
    func aspectFitRectInSize(_ size: CGSize) -> CGRect {
        let scale = min(size.width / width, size.height / height)
        let scaledSize = CGSize(width: width * scale, height: height * scale)
        
        var rect = CGRect.zero
        rect.origin.x = round((size.width - scaledSize.width) * 0.5)
        rect.origin.y = round((size.height - scaledSize.height) * 0.5)
        rect.size.width = round(scaledSize.width)
        rect.size.height = round(scaledSize.height)
        return rect
    }
}
