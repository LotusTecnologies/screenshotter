//
//  UsageStreak.swift
//  screenshot
//
//  Created by Jacob Relkin on 11/23/17.
//  Copyright (c) 2017 crazeapp. All rights reserved.
//

import Foundation
import UIKit

final class UsageStreakManager {
    var observers = [Any]()
    
    init() {
        observers.append(NotificationCenter.default.addObserver(forName: Notification.Name.UIApplicationDidFinishLaunching, object: nil, queue: nil, using: appEntry(with:)))
        observers.append(NotificationCenter.default.addObserver(forName: Notification.Name.UIApplicationWillEnterForeground, object: nil, queue: nil, using: appEntry(with:)))
        observers.append(NotificationCenter.default.addObserver(forName: Notification.Name.UIApplicationWillResignActive, object: nil, queue: nil, using: appExit(with:)))
    }
    
    deinit {
        observers.removeAll()
    }
    
    private func appExit(with notification: Notification) {

        if UserDefaults.standard.bool(forKey: UserDefaultsKeys.onboardingCompleted) {
            updateStreak()
        }
        
        let now = Date()
        UserDefaults.standard.set(now, forKey: UserDefaultsKeys.dateLastAppSession)
    }
    
    private func appEntry(with notification: Notification) {
        if notification.name == Notification.Name.UIApplicationDidFinishLaunching,
            let application = notification.object as? UIApplication,
            application.applicationState == .background {
            // Don't record streaks when we're launched into the background.
            return
        }
        
        if notification.name == Notification.Name.UIApplicationWillEnterForeground, let lastSessionDate = UserDefaults.standard.object(forKey: UserDefaultsKeys.dateLastAppSession) as? Date, abs(lastSessionDate.timeIntervalSinceNow) > 10*60  {
                var sessionCount = UserDefaults.standard.integer(forKey: UserDefaultsKeys.sessionCount)
                sessionCount += 1
                UserDefaults.standard.set(sessionCount, forKey: UserDefaultsKeys.sessionCount)
        }
        
        guard UserDefaults.standard.bool(forKey: UserDefaultsKeys.onboardingCompleted) else {
            // Don't record streaks when we haven't completed onboarding.
            return
        }
        
        updateStreak()
    }
    
    func updateStreakTo(streak:Int) {
        let now = Date()
        UserDefaults.standard.set(streak, forKey: UserDefaultsKeys.dailyStreak)
        UserDefaults.standard.set(now, forKey: UserDefaultsKeys.dateLastAppSession)

        let current = AnalyticsUser.current
        current.sendToServers()
        Analytics.trackUserProperties(analyticsUser: current)
    }
    
    private func updateStreak() {
        if let streakDate = UserDefaults.standard.object(forKey: UserDefaultsKeys.dateLastAppSession) as? Date {
            if Calendar.current.isDateInToday(streakDate) {
                let lastStreak = UserDefaults.standard.integer(forKey: UserDefaultsKeys.dailyStreak)
                if lastStreak == 0 {
                    updateStreakTo(streak: 1)
                }
            }else if Calendar.current.isDateInYesterday(streakDate) {
                // increaement streak
                let lastStreak = UserDefaults.standard.integer(forKey: UserDefaultsKeys.dailyStreak)
                let updatedStreak = lastStreak + 1
                updateStreakTo(streak: updatedStreak)
            }else{
                //Lost streak
                updateStreakTo(streak: 1)
            }
        }else{
            //started streak
            updateStreakTo(streak: 1)
        }
    }
}

