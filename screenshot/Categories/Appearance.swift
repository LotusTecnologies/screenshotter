//
//  Appearance.swift
//  screenshot
//
//  Created by Corey Werner on 9/4/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    static let background = UIColor(white: 244.0/255.0, alpha: 1)
    static let border = UIColor.black.withAlphaComponent(0.3)
    
    static let crazeRed = UIColor(red: 237.0/255.0, green: 20.0/255.0, blue: 90.0/255.0, alpha: 1)
    static let crazeGreen = UIColor(red: 32.0/255.0, green: 200.0/255.0, blue: 163.0/255.0, alpha: 1)
        
    static let gray1 = UIColor(white: 0.1, alpha: 1) // 25.5
    static let gray2 = UIColor(white: 0.2, alpha: 1) // 51
    static let gray3 = UIColor(white: 0.3, alpha: 1) // 76.5
    static let gray4 = UIColor(white: 0.4, alpha: 1) // 102
    static let gray5 = UIColor(white: 0.5, alpha: 1) // 127.5
    static let gray6 = UIColor(white: 0.6, alpha: 1) // 153
    static let gray7 = UIColor(white: 0.7, alpha: 1) // 178.5
    static let gray8 = UIColor(white: 0.8, alpha: 1) // 204
    static let gray9 = UIColor(white: 0.9, alpha: 1) // 229.5
    
    func lighter(by percentage: CGFloat = 8) -> UIColor? {
        return adjust(by: abs(percentage))
    }
    
    func darker(by percentage: CGFloat = 8) -> UIColor? {
        return adjust(by: -1 * abs(percentage))
    }
    
    private func adjust(by percentage: CGFloat = 8) -> UIColor? {
        var r = CGFloat(), g = CGFloat(), b = CGFloat(), a = CGFloat()
        
        if getRed(&r, green: &g, blue: &b, alpha: &a) {
            let p = percentage / 100
            return UIColor(red: min(r + p, 1), green: min(g + p, 1), blue: min(b + p, 1), alpha: a)
            
        } else {
            return nil
        }
    }
}

extension TimeInterval {
    static let defaultAnimationDuration = 0.25
}

extension UIContentSizeCategory {
    var isAccessibilityCategory: Bool {
        let isAccessibility: Bool
        
        switch self {
        case .accessibilityMedium,
             .accessibilityLarge,
             .accessibilityExtraLarge,
             .accessibilityExtraExtraLarge,
             .accessibilityExtraExtraExtraLarge:
            isAccessibility = true
            
        default:
            isAccessibility = false
        }
        
        return isAccessibility
    }
}

struct Shadow {
    private(set) var radius: CGFloat
    private(set) var offset: CGSize
    private(set) var color: UIColor
    
    var insets: UIEdgeInsets {
        let inset = radius * 2
        
        var insets = UIEdgeInsets.zero
        insets.top = inset - offset.height
        insets.left = inset
        insets.bottom = inset + offset.height
        insets.right = inset
        return insets
    }
    
    var layoutMargins: UIEdgeInsets {
        var margins = insets
        margins.top = -margins.top
        margins.left = -margins.left
        margins.bottom = -margins.bottom
        margins.right = -margins.right
        return margins
    }
    
    func pathRect(_ bounds: CGRect) -> CGRect {
        var rect = UIEdgeInsetsInsetRect(bounds, insets)
        rect.origin = .zero
        return rect
    }
    
    static let basic = Shadow(radius: 1, offset: CGSize(width: 0, height: 1), color: UIColor.black.withAlphaComponent(0.3))
}

extension UIApplication {
    static func appearanceSetup() {
        let crazeRedColor = UIColor.crazeRed
        
        let futuraFont: (CGFloat) -> UIFont = { fontSize in
            return UIFont(name: "Futura", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
        }
        let futuraMediumFont: (CGFloat) -> UIFont = { fontSize in
            return UIFont(name: "Futura-Medium", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
        }
        
        UINavigationBar.appearance().barTintColor = .white
        UINavigationBar.appearance().tintColor = .gray3
        UINavigationBar.appearance().titleTextAttributes = [
            NSFontAttributeName: futuraMediumFont(20),
            NSForegroundColorAttributeName: UIColor.gray3
        ]
        
        UITabBar.appearance().barTintColor = .white
        UITabBar.appearance().tintColor = crazeRedColor
        UITabBar.appearance().unselectedItemTintColor = .gray3
        
        UIToolbar.appearance().tintColor = crazeRedColor
        
        var barButtonItemTitleTextAttributes: [String:Any] = [NSFontAttributeName: futuraFont(16)]
        let navigationBarButtonItem = UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self])
        navigationBarButtonItem.setTitleTextAttributes(barButtonItemTitleTextAttributes, for: .normal)
        navigationBarButtonItem.setTitleTextAttributes(barButtonItemTitleTextAttributes, for: .highlighted)
        
        barButtonItemTitleTextAttributes[NSForegroundColorAttributeName] = UIColor.gray7
        navigationBarButtonItem.setTitleTextAttributes(barButtonItemTitleTextAttributes, for: .disabled)
        
        barButtonItemTitleTextAttributes = [NSFontAttributeName: futuraFont(12)]
        let toolbarButtonItem = UIBarButtonItem.appearance(whenContainedInInstancesOf: [UIToolbar.self])
        toolbarButtonItem.setTitleTextAttributes(barButtonItemTitleTextAttributes, for: .normal)
        toolbarButtonItem.setTitleTextAttributes(barButtonItemTitleTextAttributes, for: .highlighted)
        toolbarButtonItem.setTitleTextAttributes(barButtonItemTitleTextAttributes, for: .disabled)
        
        UIActivityIndicatorView.appearance(whenContainedInInstancesOf: [UIToolbar.self]).color = crazeRedColor
    }
}
