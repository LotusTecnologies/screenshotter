//
//  ScreenshotActivityItemProvider.swift
//  screenshot
//
//  Created by Gershon Kagan on 9/6/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit

class ScreenshotActivityItemProvider: UIActivityItemProvider {
    
    let placeholderURL: URL!
    var shareURL: URL?
    var didComplete: Bool = false
    var didSucceed: Bool = false
    
    init(screenshot: Screenshot, placeholderURL: URL) {
        NSLog("ScreenshotActivityItemProvider init start")
        self.placeholderURL = placeholderURL
        super.init(placeholderItem: placeholderURL)
        screenshot.share().then { shareLink -> Void in
            if let returnedURL = URL(string: shareLink) {
                NSLog("ScreenshotActivityItemProvider success")
                self.shareURL = returnedURL
                self.didSucceed = true
            } else {
                NSLog("ScreenshotActivityItemProvider false")
                self.didSucceed = false
            }
            self.didComplete = true
            }.catch { error in
                NSLog("ScreenshotActivityItemProvider catch error:\(error)")
                self.didSucceed = false
                self.didComplete = true
        }
        NSLog("ScreenshotActivityItemProvider init end")
    }
    
    override var item: Any {
        get {
            var sleepTimes = 0
            while !didComplete {
                sleepTimes += 1
                NSLog("ScreenshotActivityItemProvider Sleeping for time:\(sleepTimes)")
                Thread.sleep(forTimeInterval: 0.1)
            }
            if didSucceed, let shareURL = shareURL {
                return shareURL
            } else {
                return self.placeholderURL
            }
        }
    }

}
