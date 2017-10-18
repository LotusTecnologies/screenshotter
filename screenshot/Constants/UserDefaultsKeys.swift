//
//  UserDefaultsKeys.swift
//  screenshot
//
//  Created by Jacob Relkin on 9/5/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

class UserDefaultsKeys : NSObject {
    static let email = "Email"
    static let name = "Name"
    static let userID = "UserID"
    static let ambasssadorUsername = "ambasssadorUsername"
    
    static let discoverUrl = "discoverUrl"
    
    static let tutorialCompleted = "TutorialCompleted"
    static let tutorialPresentedScreenshotHelper = "TutorialPresentedScreenshotHelper"
    static let tutorialPresentedProductHelper = "TutorialPresentedProductHelper"
    static let tutorialShouldPresentScreenshotPicker = "TutorialShouldPresentScreenshotPicker"
    static let tutorialScreenshotAssetId = "TutorialScreenshotAssetId" // !!!: Not being used, can be removed.
    static let onboardingPresentedPushAlert = "OnboardingPresentedPushAlert"
    
    static let dateInstalled = "DateInstalled"
    static let dateLastSound = "DateLastSound"
    static let significantEventCount = "SignificantEventCount"
    static let deviceToken = "deviceToken"
    static let versionLastAskedToUpdate = "versionLastAskedToUpdate"
    
    static let gameScore = "GameScore"
}
