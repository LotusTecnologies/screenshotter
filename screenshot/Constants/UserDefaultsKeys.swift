//
//  UserDefaultsKeys.swift
//  screenshot
//
//  Created by Jacob Relkin on 9/5/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

class UserDefaultsKeys : NSObject {
    // User
    static let email = "Email"
    static let name = "Name"
    static let userID = "UserID"
    static let ambasssadorUsername = "AmbasssadorUsername"
    
    // Discover
    static let discoverUrl = "DiscoverUrl"
    
    // Product
    static let productSort = "ProductSort"
    
    // Onboarding
    static let tutorialCompleted = "TutorialCompleted"
    static let tutorialPresentedScreenshotHelper = "TutorialPresentedScreenshotHelper"
    static let tutorialPresentedProductHelper = "TutorialPresentedProductHelper"
    static let tutorialShouldPresentScreenshotPicker = "TutorialShouldPresentScreenshotPicker"
    static let onboardingPresentedPushAlert = "OnboardingPresentedPushAlert"
    
    // Device / Version
    static let dateInstalled = "DateInstalled"
    static let dateLastSound = "DateLastSound"
    static let significantEventCount = "SignificantEventCount"
    static let deviceToken = "deviceToken"
    static let versionLastAskedToUpdate = "versionLastAskedToUpdate"
    
    // Game
    static let gameScore = "GameScore"
}
