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

// TODO: remove legacy code after all files are .swift
public class Geometry : NSObject {
    static let padding = CGFloat.padding
    static let extendedPadding = CGFloat.extendedPadding
    
    static let halfPoint = CGFloat.halfPoint
    
    static let defaultCornerRadius = CGFloat.defaultCornerRadius
}
