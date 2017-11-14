//
//  Geometry.swift
//  screenshot
//
//  Created by Jacob Relkin on 10/22/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

extension CGFloat {
    static let padding = CGFloat(16)
    static let extendedPadding = CGFloat(40)
    
    static let halfPoint = CGFloat(UIScreen.main.scale > 1 ? 0.5 : 1)
    
    static let defaultCornerRadius = CGFloat(6)
}

// TODO: remove legacy code after all files are .swift
public class Geometry : NSObject {
    static let padding = CGFloat(16)
    static let extendedPadding = CGFloat(40)
    
    static let halfPoint = CGFloat(UIScreen.main.scale > 1 ? 0.5 : 1)
    
    static let defaultCornerRadius = CGFloat(6)
}
