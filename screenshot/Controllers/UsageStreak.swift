//
//  UsageStreak.swift
//  screenshot
//
//  Created by Jacob Relkin on 11/23/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

fileprivate extension DateComponents {
    func value(for component: Calendar.Component) -> Int? {
        switch component {
        case .day:
            return day
        default:
            return nil
        }
    }
}

final class UsageStreakManager {
    var observers = [Any]()
    
    init() {
        observers.append(NotificationCenter.default.addObserver(forName: Notification.Name.UIApplicationDidFinishLaunching, object: nil, queue: nil, using: appEntry(with:)))
        observers.append(NotificationCenter.default.addObserver(forName: Notification.Name.UIApplicationWillEnterForeground, object: nil, queue: nil, using: appEntry(with:)))
        observers.append(NotificationCenter.default.addObserver(forName: Notification.Name.UIApplicationDidEnterBackground, object: nil, queue: nil, using: appExit(with:)))
    }
    
    deinit {
        observers.removeAll()
    }
    
    // MARK: -
    
    private var dateLastSession: Date? {
        return UserDefaults.standard.object(forKey: UserDefaultsKeys.dateLastAppSession) as? Date
    }
    
    private var lastStreak: Int {
        return UserDefaults.standard.integer(forKey: UserDefaultsKeys.dailyStreak)
    }
    
    private var calendar: Calendar {
        return Calendar.current
    }
    
    // MARK: -
    
    private func appExit(with notification: Notification) {
        updateDateOfLastSession()
    }
    
    private func appEntry(with notification: Notification) {
        if notification.name == Notification.Name.UIApplicationDidFinishLaunching,
            let application = notification.object as? UIApplication,
            application.applicationState == .background {
            // Don't record streaks when we're launched into the background.
            return
        }
        
        guard UserDefaults.standard.bool(forKey: UserDefaultsKeys.onboardingCompleted) else {
            // Don't record streaks when we haven't completed onboarding.
            return
        }
        
        updateStreak()
    }
    
    private func streak(for component:Calendar.Component) -> Int? {
        guard let streakDate = dateLastSession else {
            return 1
        }
        
        let diff = calendar.dateComponents(Set([component]), from: streakDate, to: Date())
        
        guard let value = diff.value(for: component) else {
            return nil
        }
        
        switch value {
        case 1:
            return lastStreak + 1
        case 0:
            return lastStreak
        default:
            return nil
        }
    }
    
    private func updateDateOfLastSession() {
        UserDefaults.standard.set(Date(), forKey: UserDefaultsKeys.dateLastAppSession)
    }
    
    private func updateStreak() {
        if let streak = streak(for: .day) {
            if lastStreak != streak {
                AnalyticsTrackers.standard.track("Daily Streak", properties: ["current": streak])
                UserDefaults.standard.set(streak, forKey: UserDefaultsKeys.dailyStreak)
                updateDateOfLastSession()
            }
        } else {
            UserDefaults.standard.set(1, forKey: UserDefaultsKeys.dailyStreak)
            updateDateOfLastSession()
        }
    }
}

