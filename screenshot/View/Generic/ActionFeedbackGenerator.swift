//
//  ActionFeedbackGenerator.swift
//  screenshot
//
//  Created by Corey Werner on 4/29/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit
import AudioToolbox

enum ActionFeedbackType: Int {
    /// Weak boom
    case peek
    /// Strong boom
    case pop
    /// Series of three weak booms
    case nope
}

class ActionFeedbackGenerator: UIFeedbackGenerator {
    func actionOccurred(_ actionType: ActionFeedbackType) {
        switch actionType {
        case .peek:
            AudioServicesPlaySystemSound(1519)
        case .pop:
            AudioServicesPlaySystemSound(1520)
        case .nope:
            if UIDevice.current.hasTapticEngine {
                AudioServicesPlaySystemSound(1521)
            }
            else {
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            }
        }
    }
}
