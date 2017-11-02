//
//  ApplicationStateModel.swift
//  screenshot
//
//  Created by Gershon Kagan on 11/1/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

// The reason for being of this model, is so background threads can query whether the app is
// active in the foreground, or in the background, without triggering a scary warning on iOS 11.
class ApplicationStateModel {
    
    public static let sharedInstance = ApplicationStateModel()

    public var applicationState: UIApplicationState = .active

    func isActive() -> Bool {
        return applicationState == .active
    }
    
    func isBackground() -> Bool {
        return applicationState != .active
    }

}
