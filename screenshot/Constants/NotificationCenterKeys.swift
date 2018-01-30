//
//  NotificationCenterKeys.swift
//  screenshot
//
//  Created by Corey Werner on 11/15/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

class NotificationCenterKeys : NSObject {
    static let fetchedAppSettings = "FetchedAppSettings"
    
    /// Will be called from a background thread.
    static let coreDataStackCompleted = "CoreDataStackCompleted"
}
