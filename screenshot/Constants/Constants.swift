//
//  Constants.swift
//  screenshot
//
//  Created by Gershon Kagan on 8/27/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

class Constants: NSObject {

    // Local notification constants.
    static let openingScreenKey = "openingScreenKey"
    static let openingScreenValueScreenshot = "openingScreenValueScreenshot"
    static let openingAssetIdKey = "openingAssetIdKey"
    static let tutorialScreenshotAssetId = "tutorialScreenshotAssetId"
    static let uploadedURLStringKey = "uploadedURLStringKey"
    
    // Default UI / UX
    static let defaultAnimationDuration = 0.25
    
    // Syte
    static let syteAccountId = 6677
    static let syteAccountSignature = "GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU="
    static let syteHardcodedAuth = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmaW5nZXIiOiJ2L0NhY3YzREs5K0NxaVFTQXB1ZDFBPT0iLCJ0aW1lc3RhbXAiOjE1MTM3NjEzNzI1OTksInV1aWQiOiJjMTliZmVkNy05M2FmLTVkZjAtYTQ1ZS1kNWQ5ZGVmMjMzMjYifQ.6KtjqtvusixdqoaZjfp3au9b6SU5x-mdyq8WEJJx2U0"
    
    // Keys
#if DEV
    static let appSeeApiKey = "d9010050cea04490b6b9cdd795849dd4"
    static let screenShotLambdaDomain = "https://c3fkst0oq3.execute-api.us-east-1.amazonaws.com/dev/"
    static let intercomAPIKey = "ios_sdk-97795b9b5fdcdb25e81866ff066ffa4869376161"
    static let intercomAppID = "z57orduu"
    static let segmentWriteKey = "54lr3LDCEhRCTa13eEt2xaDTqnaQxbsC"
    static let buildEnvironmentSuffix = "d"
    static let appSettingsDomain = "https://api.craze-dev.com/static/config.json"
#else
    static let appSeeApiKey = "0ece18b50f7d4ef9aae3e473c28030bc"
    static let screenShotLambdaDomain = "https://q598b771ed.execute-api.us-east-1.amazonaws.com/production/"
    static let intercomAPIKey = "ios_sdk-ddb9fad7f09f9b18ee7491740f99b6fd98e2296b"
    static let intercomAppID = "avy9hyuz"
    static let segmentWriteKey = "RWoeJieRzzEBZ4GYG3bflJdTMyXHs5Fn"
    static let buildEnvironmentSuffix = ""
    static let appSettingsDomain = "https://api.craze-api.com/static/config.json"
#endif

}
