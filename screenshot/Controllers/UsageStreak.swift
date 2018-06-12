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
        observers.append(NotificationCenter.default.addObserver(forName: Notification.Name.UIApplicationDidEnterBackground, object: nil, queue: nil, using: appExit(with:)))
    }
    
    deinit {
        observers.removeAll()
    }
    
    private func appExit(with notification: Notification) {
        guard UserDefaults.standard.bool(forKey: UserDefaultsKeys.onboardingCompleted) else {
            // Don't record streaks when we haven't completed onboarding.
            return
        }
        
        updateStreak()
        
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
                //streak not updated
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

