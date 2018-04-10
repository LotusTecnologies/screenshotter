//
//  UIImage+craze.swift
//  screenshot
//
//  Created by Gershon Kagan on 3/27/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

extension UIImage {
    func downSample(toSize: CGSize) -> UIImage {
        let start = Date()
        // See: http://nshipster.com/image-resizing/
        UIGraphicsBeginImageContextWithOptions(toSize, false, self.scale)
        self.draw(in: CGRect(origin: .zero, size: toSize))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        print("Took \(-start.timeIntervalSinceNow) seconds to downSample from:\(size) to:\(toSize)")
        return scaledImage ?? self
    }
}
