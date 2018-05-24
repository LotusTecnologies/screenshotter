//
//  NotificationCenterKeys.swift
//  screenshot
//
//  Created by Corey Werner on 11/15/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let fetchedAppSettings = Notification.Name(rawValue: "io.crazeapp.screenshot.FetchedAppSettings")
    static let accumulatorModelDidUpdate = Notification.Name(rawValue: "io.crazeapp.screenshot.AccumulatorModelDidUpdate")
    static let permissionsManagerDidUpdate = Notification.Name(rawValue: "io.crazeapp.screenshot.PermissionsManagerUpdate")
    
    static let applicationDidRegisterForRemoteNotifications = Notification.Name(rawValue: "io.crazeapp.screenshot.RemoteNotifications")
}
