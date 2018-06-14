//
//  Constants.swift
//  screenshot
//
//  Created by Gershon Kagan on 8/27/17.
//  Copyright (c) 2017 crazeapp. All rights reserved.
//

import Foundation

class Constants {

    // Product decisions
    static let notificationProductToImportCountLimit = 4
    
    // Local notification constants.
    static let openingScreenKey = "openingScreenKey"
    static let openingScreenValueScreenshot = "openingScreenValueScreenshot"
    static let openingAssetIdKey = "openingAssetIdKey"
    static let tutorialScreenshotAssetId = "tutorialScreenshotAssetId"
    
    // DB
    static let currentMomVersion = 18
    
    // Cart
    static let cartItemMaxQuantity = 10
    
    // Syte
    static let syteAccountId = 6677
    static let syteAccountSignature = "GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU="
    static let syteHardcodedAuth = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmaW5nZXIiOiJ2L0NhY3YzREs5K0NxaVFTQXB1ZDFBPT0iLCJ0aW1lc3RhbXAiOjE1MTM3NjEzNzI1OTksInV1aWQiOiJjMTliZmVkNy05M2FmLTVkZjAtYTQ1ZS1kNWQ5ZGVmMjMzMjYifQ.6KtjqtvusixdqoaZjfp3au9b6SU5x-mdyq8WEJJx2U0"
    
    static let furnitureAccountId = 6722
    static let furnitureAccountSignature = "G51b+lgvD2TO4l1AjvnVI1OxokzFK5FLw5lHBksXP1c="
    static let furnitureHardcodedAuth = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmaW5nZXIiOiJ2L0NhY3YzREs5K0NxaVFTQXB1ZDFBPT0iLCJ0aW1lc3RhbXAiOjE1MTQzNjgxOTYxNzIsInV1aWQiOiI3OWIyNWJkZi1lMWI2LTVkOWEtOGJkZi1iZDMwNDkzZmE4NjYifQ.IUpV_u797rI0Asvog26y7cHG1mIuHMnDiPsJvLnIAc4"
    
    static let syteNonUscFeed = "craze_default"
    
    // Keys
#if DEV
    static let appSeeApiKey = "d9010050cea04490b6b9cdd795849dd4"
    static let screenShotLambdaDomain = "https://c3fkst0oq3.execute-api.us-east-1.amazonaws.com/dev/"
    static let amplitudeApiKey = "1e8c1c66e73368665d6e3cc486104c7e"
    static let buildEnvironmentSuffix = "d"
    static let appSettingsDomain = "https://api.craze-dev.com/static/config.json"
    static let whatsNewDomain = "https://api.craze-dev.com/static/whatsnew"
    // Shoppable and Syte should point to prod until they fix their staging environment.
    static let shoppableDomain = "https://api.shoppable.com/v3" //"https://api.shoppable.co/v3"
    static let shoppableHosted = "https://secure.shoppable.com" //"https://secure.shoppable.co"
    static let shoppableToken = "F81iFWJ93by99pqC22c422189db74b52" //"gD1GV3cVFGC9hk8W5927b13e5e"
    static let syteUscFeed = "shoppable_production" //"shoppable"
    static let kocchavaGUIDKey = "koscreenshot-ios-dev-wiwhb"
#else
    static let appSeeApiKey = "0ece18b50f7d4ef9aae3e473c28030bc"
    static let screenShotLambdaDomain = "https://q598b771ed.execute-api.us-east-1.amazonaws.com/production/"
    static let amplitudeApiKey = "22f09c1b641be78951bc3cc2e21024f9"
    static let buildEnvironmentSuffix = ""
    static let appSettingsDomain = "https://api.craze-api.com/static/config.json"
    static let whatsNewDomain = "https://api.craze-api.com/static/whatsnew"
    static let shoppableDomain = "https://api.shoppable.com/v3"
    static let shoppableHosted = "https://secure.shoppable.com"
    static let shoppableToken = "F81iFWJ93by99pqC22c422189db74b52"
    static let syteUscFeed = "shoppable_production"
    static let kocchavaGUIDKey = "koscreenshot-cq8h4"
#endif

}
