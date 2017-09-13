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
        self.placeholderURL = placeholderURL
        super.init(placeholderItem: placeholderURL)
        screenshot.share().then { shareLink -> Void in
            if let returnedURL = URL(string: shareLink) {
                self.shareURL = returnedURL
                self.didSucceed = true
            } else {
                self.didSucceed = false
            }
            self.didComplete = true
            }.catch { error in
                print("ScreenshotActivityItemProvider catch error:\(error)")
                self.didSucceed = false
                self.didComplete = true
        }
    }
    
    override var item: Any {
        get {
            var sleepTimes = 0
            while !didComplete {
                sleepTimes += 1
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
