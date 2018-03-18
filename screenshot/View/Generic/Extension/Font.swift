//
//  Fonts.swift
//  screenshot
//
//  Created by Corey Werner on 3/16/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

extension UIFontTextStyle {
    static let largeTitle: UIFontTextStyle = UIFontTextStyle("UICTFontTextStyleTitle0")
}

extension UIFont {
    enum ScreenshopFamilyName: String {
        case din    = "DIN Condensed"
        case futura = "Futura"
        case hind   = "Hind"
        
        var lineHeightMultiple: CGFloat {
            switch self {
            case .din:
                return 0
            case .futura:
                return 0.9
            case .hind:
                return 0.7
            }
        }
    }
    
    static private var sizeMap: [UIFontTextStyle: CGFloat] {
        return [
            .largeTitle:  38, // Does not adjust for content size category!
            .title1:      34,
            .title2:      28,
            .title3:      22,
            .headline:    20,
            .subheadline: 18,
            .body:        17,
            .callout:     16,
            .footnote:    13,
            .caption1:    12,
            .caption2:    11
        ]
    }
    
    static private func screenshopFont(_ name: String, textStyle: UIFontTextStyle, staticSize: Bool) -> UIFont? {
        if let size = sizeMap[textStyle], let font = UIFont(name: name, size: size) {
            if staticSize {
                return font
            }
            else if #available(iOS 11.0, *) {
                return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: font)
            }
        }
        
        return nil
    }
    
    static func preferredFont(forTextStyle textStyle: UIFontTextStyle, symbolicTraits: UIFontDescriptorSymbolicTraits) -> UIFont {
        var textStyle = textStyle
        
        if #available(iOS 11.0, *) {} else {
            if textStyle == .largeTitle {
                textStyle = .title1
            }
        }
        
        var font = UIFont.preferredFont(forTextStyle: textStyle)
        
        if let descriptor = font.fontDescriptor.withSymbolicTraits(symbolicTraits) {
            font = UIFont(descriptor: descriptor, size: 0)
        }
        
        return font
    }
    
    // MARK: Din
    
    static func dinCondensedBold(forTextStyle textStyle: UIFontTextStyle, staticSize: Bool = false) -> UIFont {
        return screenshopFont("DINCondensed-Bold", textStyle: textStyle, staticSize: staticSize) ?? .preferredFont(forTextStyle: textStyle, symbolicTraits: [.traitBold, .traitCondensed])
    }
    
    // MARK: Futura
    
    static func futura(forTextStyle textStyle: UIFontTextStyle, staticSize: Bool = false) -> UIFont {
        return screenshopFont("Futura", textStyle: textStyle, staticSize: staticSize) ?? .preferredFont(forTextStyle: textStyle)
    }
    
    static func futuraMedium(forTextStyle textStyle: UIFontTextStyle, staticSize: Bool = false) -> UIFont {
        return screenshopFont("Futura-Medium", textStyle: textStyle, staticSize: staticSize) ?? .preferredFont(forTextStyle: textStyle)
    }
    
    static func futuraBold(forTextStyle textStyle: UIFontTextStyle, staticSize: Bool = false) -> UIFont {
        return screenshopFont("Futura-Bold", textStyle: textStyle, staticSize: staticSize) ?? .preferredFont(forTextStyle: textStyle, symbolicTraits: .traitBold)
    }
    
    // MARK: Hind
    
    static func hindLight(forTextStyle textStyle: UIFontTextStyle, staticSize: Bool = false) -> UIFont {
        return screenshopFont("Hind-Light", textStyle: textStyle, staticSize: staticSize) ?? .preferredFont(forTextStyle: textStyle)
    }
    
    static func hind(forTextStyle textStyle: UIFontTextStyle, staticSize: Bool = false) -> UIFont {
        return screenshopFont("Hind-Regular", textStyle: textStyle, staticSize: staticSize) ?? .preferredFont(forTextStyle: textStyle)
    }
    
    static func hindMedium(forTextStyle textStyle: UIFontTextStyle, staticSize: Bool = false) -> UIFont {
        return screenshopFont("Hind-Medium", textStyle: textStyle, staticSize: staticSize) ?? .preferredFont(forTextStyle: textStyle, symbolicTraits: .traitBold)
    }
    
    static func hindSemiBold(forTextStyle textStyle: UIFontTextStyle, staticSize: Bool = false) -> UIFont {
        return screenshopFont("Hind-SemiBold", textStyle: textStyle, staticSize: staticSize) ?? .preferredFont(forTextStyle: textStyle, symbolicTraits: .traitBold)
    }
    
    static func hindBold(forTextStyle textStyle: UIFontTextStyle, staticSize: Bool = false) -> UIFont {
        return screenshopFont("Hind-Bold", textStyle: textStyle, staticSize: staticSize) ?? .preferredFont(forTextStyle: textStyle, symbolicTraits: .traitBold)
    }
}

extension UIFont {
    // TODO: after swift 4 update, change to NSAttributedStringKey
    var attributes: [String: Any] {
        var attributes: [String: Any] = [NSFontAttributeName: self]
        let lineHeightMultiple: CGFloat?
        
        switch familyName {
        case ScreenshopFamilyName.din.rawValue:
            lineHeightMultiple = ScreenshopFamilyName.din.lineHeightMultiple
        case ScreenshopFamilyName.futura.rawValue:
            lineHeightMultiple = ScreenshopFamilyName.futura.lineHeightMultiple
        case ScreenshopFamilyName.hind.rawValue:
            lineHeightMultiple = ScreenshopFamilyName.hind.lineHeightMultiple
        default:
            lineHeightMultiple = nil
        }
        
        if let lineHeightMultiple = lineHeightMultiple {
            let paragraph = NSMutableParagraphStyle()
            paragraph.lineHeightMultiple = lineHeightMultiple
            attributes[NSParagraphStyleAttributeName] = paragraph
        }
        
        return attributes
    }
}
