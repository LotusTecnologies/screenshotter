//
//  TapticHelper.swift
//  screenshot
//
//  Created by Corey Werner on 10/25/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation
import AudioToolbox

class TapticHelper: NSObject {
    static func peek() {
        AudioServicesPlaySystemSound(1519) // weak boom
    }
    
    static func pop() {
        AudioServicesPlaySystemSound(1520) // strong boom
    }
    
    static func nope() {
        AudioServicesPlaySystemSound(1521) // series of three weak booms
    }
}
