//
//  UserDefaultsKeys.swift
//  screenshot
//
//  Created by Jacob Relkin on 9/5/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation
import UIKit

class UserDefaultsKeys  {
    // User
    static let email = "Email"
    static let name = "Name"
    static let userID = "UserID"
    static let referralChannel = "ReferralChannel"
    static let campaign = "Campaign"

    // USC
    static let isUSC = "IsUSC"
    
    // Screenshot
    static let newScreenshotsCount = "NewScreenshotsCount"
    static let newScreenshotsAssetIds = "NewScreenshotsAssetIds"

    // Product
    static let productGender = "ProductGender"
    static let productSize = "ProductSize"
    static let productSale = "ProductSale"
    static let productSort = "ProductSort"
    static let productCurrency = "ProductCurrency"
    static let productCategory = "ProductCategory"
    
    static let openWebPage = "OpenProductPageInSetting"  //open in safari, SFSafiriViewController, chrome, etc
    
    // Onboarding
    static let onboardingCompleted = "OnboardingCompleted"
    static let onboardingPresentedScreenshotHelper = "OnboardingPresentedScreenshotHelper"
    static let onboardingPresentedScreenshotPicker = "OnboardingShouldPresentedScreenshotPicker"
    static let onboardingPresentedPushAlert = "OnboardingPresentedPushAlert"
    static let lastCampaignCompleted = "LastCampaignCompleted"  //in here is stored CampaignCompleted.rawValue
    enum CampaignCompleted : String {
        case campaign_2018_04_20 // Kim video to push users to do purchases
    }
    
    // Device / Version
    static let dateInstalled = "DateInstalled"
    static let dateLastSound = "DateLastSound"
    static let dateLastAppSession = "DateLastAppSession"
    static let significantEventCount = "SignificantEventCount"
    static let deviceToken = "deviceToken"
    static let versionLastAskedToUpdate = "versionLastAskedToUpdate"
    static let persistentVersion = "PersistentVersion"
    static let dailyStreak = "dailyStreak"
    static let processBackgroundImagesForFashionAfterDate = "ProcessBackgroundImagesForFashionAfterDate"

    // DB
    static let lastDbVersionMigrated = "LastDbVersionMigrated"
    
    // Clarifai
    static let isModelDownloaded = "IsModelDownloaded"
    
    // Discover
    static let discoverScreenshotPresentedHelper = "discoverScreenshotPresentedHelper"
    
    // Game
    static let gameScore = "GameScore"
    
    // Silent Push
    static let lastTimeZone = "LastTimeZone"
    static let subscriptionARN = "SubscriptionARN"
    static let enabledSilentPush = "EnabledSilentPush"
    
    // Matchsticks
    static let matchsticksSyncToken = "MatchsticksSyncToken"
    
    //In app Purchase
    static let purchasedProductIdentifier = "PurchasedProductIdentifier"
    
    //Debug
    static let showsDebugAnalyticsUI = "ShowsDebugAnalyticsUI"

}

extension UIApplication {
    static func migrateUserDefaultsKeys() {
        // Version 1.3 keys
        if UserDefaults.standard.bool(forKey: "TutorialCompleted") {
            UserDefaults.standard.set(true, forKey: UserDefaultsKeys.onboardingCompleted)
        }
        if UserDefaults.standard.bool(forKey: "TutorialPresentedScreenshotHelper") {
            UserDefaults.standard.set(true, forKey: UserDefaultsKeys.onboardingPresentedScreenshotHelper)
        }
    }
}
