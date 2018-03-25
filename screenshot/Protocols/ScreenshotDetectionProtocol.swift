//
//  ScreenshotDetectionProtocol.swift
//  screenshot
//
//  Created by Gershon Kagan on 10/31/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

@objc protocol ScreenshotDetectionProtocol: NSObjectProtocol {
    @objc func foregroundScreenshotTaken(assetId: String)
}
