//
//  Fonts.swift
//  screenshot
//
//  Created by Corey Werner on 3/16/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

extension UIFont {
    @available(iOS 11.0, *)
    static private var sizeMap: [UIFontTextStyle: CGFloat] {
        return [
            .largeTitle:  34,
            .title1:      28,
            .title2:      22,
            .title3:      20,
            .headline:    17,
            .subheadline: 15,
            .body:        17,
            .callout:     16,
            .footnote:    13,
            .caption1:    12,
            .caption2:    11
        ]
    }
    
    static private func screenshopFont(_ name: String, forTextStyle textStyle: UIFontTextStyle) -> UIFont? {
        if #available(iOS 11.0, *), let size = sizeMap[textStyle], let font = UIFont(name: name, size: size) {
            return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: font)
        }
        else {
            return nil
        }
    }
    
    static func preferredFont(forTextStyle textStyle: UIFontTextStyle, symbolicTraits: UIFontDescriptorSymbolicTraits) -> UIFont {
        var font = UIFont.preferredFont(forTextStyle: textStyle)
        
        if let descriptor = font.fontDescriptor.withSymbolicTraits(symbolicTraits) {
            font = UIFont(descriptor: descriptor, size: 0)
        }
        
        return font
    }
    
    static func futura(forTextStyle textStyle: UIFontTextStyle) -> UIFont {
        return screenshopFont("Futura", forTextStyle: textStyle) ?? .preferredFont(forTextStyle: textStyle)
    }
    
    static func futuraMedium(forTextStyle textStyle: UIFontTextStyle) -> UIFont {
        return screenshopFont("Futura-Medium", forTextStyle: textStyle) ?? .preferredFont(forTextStyle: textStyle)
    }
    
    static func futuraBold(forTextStyle textStyle: UIFontTextStyle) -> UIFont {
        return screenshopFont("Futura-Bold", forTextStyle: textStyle) ?? .preferredFont(forTextStyle: textStyle, symbolicTraits: .traitBold)
    }
    
    static func dinCondensedBold(forTextStyle textStyle: UIFontTextStyle) -> UIFont {
        return screenshopFont("DINCondensed-Bold", forTextStyle: textStyle) ?? .preferredFont(forTextStyle: textStyle, symbolicTraits: [.traitBold, .traitCondensed])
    }
}
