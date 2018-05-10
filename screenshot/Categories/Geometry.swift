//
//  Geometry.swift
//  screenshot
//
//  Created by Jacob Relkin on 10/22/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit

extension CGFloat {
    static let padding: CGFloat = 16
    static let extendedPadding: CGFloat = UIDevice.is480h ? 20 : 40
    
    static let halfPoint: CGFloat = UIScreen.main.scale > 1 ? 0.5 : 1
    
    static let defaultCornerRadius: CGFloat = 6
}

extension Double {
    public static var goldenRatio:Double {
        get {
            return 1.6180339887498948482
        }
    }
}

extension CGSize {
    var area:CGFloat {
        return self.width * self.height
    }
    
    func rectFrom(relativeSizeRect:CGRect) -> CGRect {
        return CGRect(x: relativeSizeRect.origin.x * self.width, y: relativeSizeRect.origin.y * self.height, width: relativeSizeRect.size.width * self.width, height: relativeSizeRect.size.height * self.height)
    }
    
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

extension CGRect {
    var center:CGPoint {
        return CGPoint.init(x: self.midX, y: self.midY)
    }
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
    static func rectWith(topLeft:CGPoint, bottomRight:CGPoint) -> CGRect {
        let width = bottomRight.x - topLeft.x
        let height = bottomRight.y - topLeft.y
        return CGRect.init(origin: topLeft, size: CGSize.init(width: width, height: height))
    }
    
    static func rectFrom( syteDict:[AnyHashable:Any]) -> CGRect? {
        if let b0 = syteDict["b0"] as? [Double], let b1 = syteDict["b1"] as? [Double], let topLeft = CGPoint.pointFrom(array:b0 ), let bottomRight = CGPoint.pointFrom(array:b1) {
            return CGRect.rectWith(topLeft: topLeft, bottomRight: bottomRight)
        }
        return nil
    }
}
extension CGPoint {
    static func pointFrom(array:[Any]?) -> CGPoint? {
        if let array = array {
            if array.count == 2 {
                if let x = array.first as? Double, let y = array.last as? Double{
                    return CGPoint.init(x: x, y: y)
                }
            }
        }
        return nil
    }
}
extension UIImage {
    static func cropped(image: UIImage, thumbSize:CGSize, relativeSizeCropRect:CGRect) -> UIImage? {
        let cropFrame = image.size.rectFrom(relativeSizeRect: relativeSizeCropRect)
        let imageFrame = CGRect.init(origin: .zero, size: image.size)
        let thumbFrame = CGRect.init(origin: .zero, size: thumbSize)
        let cropFrameWithoutWhiteBars = thumbFrame.aspectFit(around:cropFrame).intersection(imageFrame)
        
        if let imageRef = image.cgImage?.cropping(to: cropFrameWithoutWhiteBars) {
            let croppedImage = UIImage(cgImage: imageRef, scale: UIScreen.main.scale, orientation: .up)
            return croppedImage
        }else{
            return nil
        }
    }
    
}
