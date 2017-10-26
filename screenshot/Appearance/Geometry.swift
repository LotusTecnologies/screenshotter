//
//  Geometry.swift
//  screenshot
//
//  Created by Jacob Relkin on 10/22/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

public class Geometry : NSObject {
    class var padding: CGFloat {
        return 16
    }
    
    class var extendedPadding: CGFloat {
        return 40
    }
    
    class var halfPoint: CGFloat {
        if UIScreen.main.scale == 1 {
            return 0.5
        }
        
        return 1
    }
}
