//
//  Constants.swift
//  screenshot
//
//  Created by Gershon Kagan on 8/27/17.
//  Copyright (c) 2017 crazeapp. All rights reserved.
//

import Foundation

extension TimeInterval {
    static var oneHour:TimeInterval = 60*60
    static var oneDay:TimeInterval  = 86400
    static var oneWeek: TimeInterval = 60*60*24*7
}

class Constants {
    // iTunes
    static let itunesConnectApp = "itms-apps://itunes.apple.com/app/id1254964391"
    static let itunesConnect = "https://itunes.apple.com/us/app/screenshop-by-craze/id1254964391"

    // Product decisions
    static let notificationProductToImportCountLimit = 4
    
    // Local notification constants.
    static let openingScreenKey = "openingScreenKey"
    static let openingScreenValueScreenshot = "openingScreenValueScreenshot"
    static let openingScreenValueDiscover = "openingScreenValueDiscover"
    static let openingScreenValueInbox = "openingScreenValueInbox"
    static let openingAssetIdKey = "openingAssetIdKey"
    static let tutorialScreenshotAssetId = "tutorialScreenshotAssetId"
    static let openingProductKey = "openingProductKey"
    
    // DB
    static let currentMomVersion = 27

    // Syte
    static let syteAccountId = 6677
    static let syteAccountSignature = "GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU="
    static let syteHardcodedAuth = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmaW5nZXIiOiJ2L0NhY3YzREs5K0NxaVFTQXB1ZDFBPT0iLCJ0aW1lc3RhbXAiOjE1MTM3NjEzNzI1OTksInV1aWQiOiJjMTliZmVkNy05M2FmLTVkZjAtYTQ1ZS1kNWQ5ZGVmMjMzMjYifQ.6KtjqtvusixdqoaZjfp3au9b6SU5x-mdyq8WEJJx2U0"
    
    static let furnitureAccountId = 6722
    static let furnitureAccountSignature = "G51b+lgvD2TO4l1AjvnVI1OxokzFK5FLw5lHBksXP1c="
    static let furnitureHardcodedAuth = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmaW5nZXIiOiJ2L0NhY3YzREs5K0NxaVFTQXB1ZDFBPT0iLCJ0aW1lc3RhbXAiOjE1MTQzNjgxOTYxNzIsInV1aWQiOiI3OWIyNWJkZi1lMWI2LTVkOWEtOGJkZi1iZDMwNDkzZmE4NjYifQ.IUpV_u797rI0Asvog26y7cHG1mIuHMnDiPsJvLnIAc4"
    
    static let syteFeed = "craze_default"
    
    
    //Discover
    static let discoverTotal = 36514
    
    
    static let notificationsApiEndpointProd = "https://0n4jo7cgbk.execute-api.us-east-1.amazonaws.com/production"
    static let notificationsApiEndpointDev = "https://aen2f0owb9.execute-api.us-east-1.amazonaws.com/dev"

    // Keys
#if DEV
    static let appSeeApiKey = "d9010050cea04490b6b9cdd795849dd4"
    static let screenShotLambdaDomain = "https://c3fkst0oq3.execute-api.us-east-1.amazonaws.com/dev/"
    static let notificationsApiEndpoint = notificationsApiEndpointDev
    static let amplitudeApiKey = "1e8c1c66e73368665d6e3cc486104c7e"
    static let buildEnvironmentSuffix = "d"
    static let appSettingsDomain = "https://api.craze-dev.com/static/config.json"
    static let whatsNewDomain = "https://api.craze-dev.com/static/whatsnew"
    static let searchCategoriesDomain = "https://s3.amazonaws.com/search-bar/search_en.json"
#else
    static let appSeeApiKey = "0ece18b50f7d4ef9aae3e473c28030bc"
    static let screenShotLambdaDomain = "https://q598b771ed.execute-api.us-east-1.amazonaws.com/production/"
    static let notificationsApiEndpoint = notificationsApiEndpointProd
    static let amplitudeApiKey = "22f09c1b641be78951bc3cc2e21024f9"
    static let buildEnvironmentSuffix = ""
    static let appSettingsDomain = "https://api.craze-api.com/static/config.json"
    static let whatsNewDomain = "https://api.craze-api.com/static/whatsnew"
    static let searchCategoriesDomain = "https://s3.amazonaws.com/search-bar/search_en.json"
#endif

}
