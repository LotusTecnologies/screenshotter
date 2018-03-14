//
//  AddToDiscoverActivity.swift
//  screenshot
//
//  Created by Jonathan Rose on 3/14/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import UIKit

class AddToDiscoverActivity : UIActivity {
    private var imageUrlString:String?
    static func addToDiscoverActivity(screenshot:Screenshot) -> AddToDiscoverActivity? {
        if let image = screenshot.uploadedImageURL {
            let toReturn = AddToDiscoverActivity.init()
            toReturn.imageUrlString = image
            return toReturn
        }
        return nil
    }
    override var activityTitle: String? {
        return "Share Publicly"
    }
    override var activityImage: UIImage? {
        return UIImage.init(named: "AppIcon")
    }
    override var activityType: UIActivityType? {
        return UIActivityType.init(AddToDiscoverActivity.activityTypeString)
    }
    static var activityTypeString = "io.crazeapp.screenshot.discover"
    
    public override func perform() {
        if let image = self.imageUrlString {
            NetworkingPromise.sharedInstance.submitToDiscover(image: image, userName: AnalyticsUser.current.name, intercomUserId: AnalyticsUser.current.identifier, email: AnalyticsUser.current.email)
        }
        activityDidFinish(true)
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
    
    override open class var activityCategory: UIActivityCategory {
        return .share
    }
}
