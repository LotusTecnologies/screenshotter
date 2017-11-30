//
//  UsageStreakHelper.swift
//  screenshot
//
//  Created by Jacob Relkin on 11/23/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

class UsageStreakHelper : NSObject {
    private static var calendar = Calendar.autoupdatingCurrent
    
    static func updateLastSessionDate() {
        UserDefaults.standard.set(Date(), forKey: UserDefaultsKeys.lastAppSessionDate)
    }
    
    static func updateStreak() {
        guard let lastSessionDate = UserDefaults.standard.object(forKey: UserDefaultsKeys.lastAppSessionDate) as? Date else {
            updateLastSessionDate()
            return
        }
        
        let currentDate = Date()
        let timeSince = currentDate.timeIntervalSince(lastSessionDate)
        let interval = 86400.0 // daily
        
        guard timeSince < interval else {
            UserDefaults.standard.set(0, forKey: UserDefaultsKeys.dailyStreak)
            return
        }

        guard calendar.isDate(currentDate, inSameDayAs: lastSessionDate) == false else {
            return
        }
        
        let streak = UserDefaults.standard.integer(forKey: UserDefaultsKeys.dailyStreak)
        UserDefaults.standard.set(streak + 1, forKey: UserDefaultsKeys.dailyStreak)
    }
}
