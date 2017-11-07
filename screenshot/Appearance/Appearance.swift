//
//  Appearance.swift
//  screenshot
//
//  Created by Corey Werner on 9/4/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

extension UIColor {
    static let background = UIColor(white: 244.0/255.0, alpha: 1)
    
    static let crazeRed = UIColor(red: 237.0/255.0, green: 20.0/255.0, blue: 90.0/255.0, alpha: 1)
    static let crazeGreen = UIColor(red: 32.0/255.0, green: 200.0/255.0, blue: 163.0/255.0, alpha: 1)
        
    static let gray1 = UIColor(white: 0.1, alpha: 1.0) // 25.5
    static let gray2 = UIColor(white: 0.2, alpha: 1.0) // 51
    static let gray3 = UIColor(white: 0.3, alpha: 1.0) // 76.5
    static let gray4 = UIColor(white: 0.4, alpha: 1.0) // 102
    static let gray5 = UIColor(white: 0.5, alpha: 1.0) // 127.5
    static let gray6 = UIColor(white: 0.6, alpha: 1.0) // 153
    static let gray7 = UIColor(white: 0.7, alpha: 1.0) // 178.5
    static let gray8 = UIColor(white: 0.8, alpha: 1.0) // 204
    static let gray9 = UIColor(white: 0.9, alpha: 1.0) // 229.5
}

struct Shadow {
    private(set) var radius: CGFloat;
    private(set) var offset: CGSize;
    private(set) var color: UIColor;
    
    static let basic = Shadow(radius: 1, offset: CGSize(width: 0, height: 1), color: UIColor.black.withAlphaComponent(0.3))
}

// TODO: objc can access struct. remove this class one files are converted to swift
class _Shadow: NSObject {
    static let radius = Shadow.basic.radius
    static let offset = Shadow.basic.offset
    static let color = Shadow.basic.color
}

