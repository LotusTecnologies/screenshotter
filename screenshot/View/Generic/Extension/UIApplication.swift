//
//  UIApplication.swift
//  screenshot
//
//  Created by Corey Werner on 3/28/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit

extension UIApplication {
    static func enableSlowAnimations() {
        guard isDev else {
            return
        }
        
        shared.windows.first?.layer.speed = 0.1
    }
    
    static func disableSlowAnimations() {
        guard isDev else {
            return
        }
        
        shared.windows.first?.layer.speed = 1
    }
}
