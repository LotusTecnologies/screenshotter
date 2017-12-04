//
//  UsageStreakHelper.swift
//  screenshot
//
//  Created by Jacob Relkin on 11/23/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

fileprivate struct StreakContext {
    let calendar: Calendar
    let previousStreakDate: Date?
    let previousStreakCount: Int
}

fileprivate enum StreakInterval {
    case day
    
    var component: Calendar.Component {
        switch self {
        case .day:
            return .day
        }
    }
    
    func value(for components:DateComponents) -> Int? {
        switch self {
        case .day:
            return components.day
        }
    }
}

fileprivate func streak(for interval:StreakInterval, with context: StreakContext) -> Int? {
    guard let streakDate = context.previousStreakDate else {
        return 1
    }
    
    let component = interval.component
    let diff = context.calendar.dateComponents(Set([component]), from: streakDate, to: Date())
    
    switch interval.value(for: diff) {
    case .none:
        return nil
    case .some(let value):
        switch value {
        case 1:
            return context.previousStreakCount + 1
        case 0:
            return context.previousStreakCount
        default:
            return nil
        }
    }
}

class UsageStreakHelper : NSObject {
    static func updateStreak() {
        let lastSessionDate = UserDefaults.standard.object(forKey: UserDefaultsKeys.dateLastAppSession) as? Date
        let lastStreak = UserDefaults.standard.integer(forKey: UserDefaultsKeys.dailyStreak)
        let context = StreakContext(calendar: Calendar.current, previousStreakDate: lastSessionDate, previousStreakCount: lastStreak)
        guard let dayStreak = streak(for: .day, with: context) else {
            UserDefaults.standard.set(1, forKey: UserDefaultsKeys.dailyStreak)
            UserDefaults.standard.set(Date(), forKey: UserDefaultsKeys.dateLastAppSession)
            return
        }
        
        if lastStreak != dayStreak {
            UserDefaults.standard.set(dayStreak, forKey: UserDefaultsKeys.dailyStreak)
            UserDefaults.standard.set(Date(), forKey: UserDefaultsKeys.dateLastAppSession)
        }
    }
}

