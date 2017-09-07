//
//  Constants.swift
//  screenshot
//
//  Created by Gershon Kagan on 8/27/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit

class Constants: NSObject {

    // Local notification constants.
    static let openingScreenKey = "openingScreenKey"
    static let openingScreenValueScreenshot = "openingScreenValueScreenshot"

#if DEBUG
    static let intercomAPIKey = "ios_sdk-97795b9b5fdcdb25e81866ff066ffa4869376161"
    static let intercomAppID = "z57orduu"
#else
    static let intercomAPIKey = "ios_sdk-ddb9fad7f09f9b18ee7491740f99b6fd98e2296b"
    static let intercomAppID = "avy9hyuz"
#endif
}
