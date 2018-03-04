//
//  TapticHelper.swift
//  screenshot
//
//  Created by Corey Werner on 10/25/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation
import AudioToolbox

class TapticHelper {
    /// Weak boom
    static func peek() {
        AudioServicesPlaySystemSound(1519)
    }
    
    /// Strong boom
    static func pop() {
        AudioServicesPlaySystemSound(1520)
    }
    
    /// Series of three weak booms
    static func nope() {
        AudioServicesPlaySystemSound(1521)
    }
}
