// STOP!  DO not edit the file below
// only create by auto generting
// created by: Jonathan Rose(rose@screenshopit.com) on computer -jonathanrose
// created on: Tue May  1 15:16:53 IDT 2018
// created from: betterCode -  - 09fea22 
//  Copyright © 2018 crazeapp. All rights reserved.


import Foundation
import FBSDKCoreKit




typealias AnalyticsAcceptedPushPermissions = Analytics
extension AnalyticsAcceptedPushPermissions {
    
  static func trackAcceptedPushPermissions() {
      let key = "Accepted Push Permissions"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsAPNDisabled = Analytics
extension AnalyticsAPNDisabled {
    
  static func trackAPNDisabled(token:String? ) {
      let key = "APN Disabled"
      var properties:[String:Any] = [:]
      if let token = token {
          properties["token"] = token
      }
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsAPNEnabled = Analytics
extension AnalyticsAPNEnabled {
    
  static func trackAPNEnabled(token:String? ) {
      let key = "APN Enabled"
      var properties:[String:Any] = [:]
      if let token = token {
          properties["token"] = token
      }
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsAppOpenedFromLocalNotification = Analytics
extension AnalyticsAppOpenedFromLocalNotification {
    
  static func trackAppOpenedFromLocalNotification() {
      let key = "app opened from local notification"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsAppSentLocalPushNotification = Analytics
extension AnalyticsAppSentLocalPushNotification {
    
  static func trackAppSentLocalPushNotification() {
      let key = "app sent local push notification"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsAutomaticallyExitedTutorialVideo = Analytics
extension AnalyticsAutomaticallyExitedTutorialVideo {
    
  static func trackAutomaticallyExitedTutorialVideo() {
      let key = "Automatically Exited Tutorial Video"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsBypassedClarifaiOnRetry = Analytics
extension AnalyticsBypassedClarifaiOnRetry {
    
  static func trackBypassedClarifaiOnRetry() {
      let key = "bypassed Clarifai on retry"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsCanceledPhotoCreation = Analytics
extension AnalyticsCanceledPhotoCreation {
    
  static func trackCanceledPhotoCreation() {
      let key = "Canceled Photo Creation"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsCreatedPhoto = Analytics
extension AnalyticsCreatedPhoto {
    
  static func trackCreatedPhoto() {
      let key = "Created Photo"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsDailyStreak = Analytics
extension AnalyticsDailyStreak {
    
  static func trackDailyStreak(current:Int? ) {
      let key = "Daily Streak"
      var properties:[String:Any] = [:]
      if let current = current {
          properties["current"] = NSNumber.init(value: current)
      }
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsDeniedPushPermissions = Analytics
extension AnalyticsDeniedPushPermissions {
    
  static func trackDeniedPushPermissions() {
      let key = "Denied Push Permissions"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsBypassedClarifai = Analytics
extension AnalyticsBypassedClarifai {
    
  static func trackBypassedClarifai() {
      let key = "bypassed Clarifai"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsErrImgHang = Analytics
extension AnalyticsErrImgHang {
    
  static func trackErrImgHang(reason:String? ) {
      let key = "err img hang"
      var properties:[String:Any] = [:]
      if let reason = reason {
          properties["reason"] = reason
      }
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsFinishedDownloadingClarifaiModel = Analytics
extension AnalyticsFinishedDownloadingClarifaiModel {
    
  static func trackFinishedDownloadingClarifaiModel() {
      let key = "finished downloading Clarifai model"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsReceivedResponseFromClarifai = Analytics
extension AnalyticsReceivedResponseFromClarifai {
    
  static func trackReceivedResponseFromClarifai(isFashion:Bool,  isFurniture:Bool ) {
      let key = "received response from Clarifai"
      var properties:[String:Any] = [:]
        properties["isFashion"] = NSNumber.init(value: isFashion)
        properties["isFurniture"] = NSNumber.init(value: isFurniture)
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsReceivedResponseFromSyte = Analytics
extension AnalyticsReceivedResponseFromSyte {
    
  static func trackReceivedResponseFromSyte(imageUrl:String?,  segmentCount:Int?,  categories:String? ) {
      let key = "received response from Syte"
      var properties:[String:Any] = [:]
      if let imageUrl = imageUrl {
          properties["imageUrl"] = imageUrl
      }
      if let segmentCount = segmentCount {
          properties["segmentCount"] = NSNumber.init(value: segmentCount)
      }
      if let categories = categories {
          properties["categories"] = categories
      }
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsSentImageToClarifai = Analytics
extension AnalyticsSentImageToClarifai {
    
  static func trackSentImageToClarifai() {
      let key = "sent image to Clarifai"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsTabBarTapped = Analytics
extension AnalyticsTabBarTapped {
    
  static func trackTabBarTapped(tab:String ) {
      let key = "Tab Bar tapped"
      var properties:[String:Any] = [:]
        properties["tab"] = tab
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsUserRetriedScreenshots = Analytics
extension AnalyticsUserRetriedScreenshots {
    
  static func trackUserRetriedScreenshots() {
      let key = "user retried screenshots"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsError = Analytics
extension AnalyticsError {
  enum AnalyticsErrorType : String{
    case `noHardDriveSpace` = "noHardDriveSpace"
    }
    
  static func trackError(type:AnalyticsErrorType?,  domain:String?,  code:Int?,  localizedDescription:String? ) {
      let key = "Error"
      var properties:[String:Any] = [:]
      if let type = type {
          properties["type"] = type.rawValue
      }
      if let domain = domain {
          properties["domain"] = domain
      }
      if let code = code {
          properties["code"] = NSNumber.init(value: code)
      }
      if let localizedDescription = localizedDescription {
          properties["localizedDescription"] = localizedDescription
      }
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsGameScoreIncreased = Analytics
extension AnalyticsGameScoreIncreased {
    
  static func trackGameScoreIncreased() {
      let key = "Game Score Increased"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsGameCollision = Analytics
extension AnalyticsGameCollision {
    
  static func trackGameCollision() {
      let key = "Game Collision"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsGameInterrupted = Analytics
extension AnalyticsGameInterrupted {
  enum AnalyticsGameInterruptedFrom : String{
    case `userNavigating` = "User Navigating"
    case `appBackgrounding` = "App Backgrounding"
    case `pageLoading` = "Page Loading"
    }
    
  static func trackGameInterrupted(from:AnalyticsGameInterruptedFrom ) {
      let key = "Game Interrupted"
      var properties:[String:Any] = [:]
        properties["From"] = from.rawValue
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsGameOpened = Analytics
extension AnalyticsGameOpened {
    
  static func trackGameOpened() {
      let key = "Game Opened"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsGameRestarted = Analytics
extension AnalyticsGameRestarted {
    
  static func trackGameRestarted() {
      let key = "Game Restarted"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsGameResumed = Analytics
extension AnalyticsGameResumed {
  enum AnalyticsGameResumedFrom : String{
    case `userNavigating` = "User Navigating"
    case `appBackgrounding` = "App Backgrounding"
    case `pageLoading` = "Page Loading"
    }
    
  static func trackGameResumed(from:AnalyticsGameResumedFrom? ) {
      let key = "Game Resumed"
      var properties:[String:Any] = [:]
      if let from = from {
          properties["From"] = from.rawValue
      }
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsGameStarted = Analytics
extension AnalyticsGameStarted {
    
  static func trackGameStarted() {
      let key = "Game Started"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsInAppPurchase = Analytics
extension AnalyticsInAppPurchase {
  enum AnalyticsInAppPurchasePurchase : String{
    case `stylists` = "stylists"
    }
  enum AnalyticsInAppPurchaseType : String{
    case `onetime` = "onetime"
    }
    
  static func trackInAppPurchase(purchase:AnalyticsInAppPurchasePurchase,  type:AnalyticsInAppPurchaseType,  price:String ) {
      let key = "InAppPurchase"
      var properties:[String:Any] = [:]
        properties["purchase"] = purchase.rawValue
        properties["type"] = type.rawValue
        properties["price"] = price
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsRequestedCustomStylist = Analytics
extension AnalyticsRequestedCustomStylist {
    
  static func trackRequestedCustomStylist(shoppable:Shoppable? ) {
      let key = "Requested Custom Stylist"
      var properties:[String:Any] = [:]
      if let shoppable = shoppable {
          propertiesFor(shoppable).forEach { properties[$0] = $1 }
      }
            


      // Aliases used to keep reverse compatability
      if let a = properties["screenshot-imageURL"] {
        if properties["screenshotImageURL"] == nil {
            properties["screenshotImageURL"] = a
        }
      }

      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsIgnoredRatingOnAppStore = Analytics
extension AnalyticsIgnoredRatingOnAppStore {
    
  static func trackIgnoredRatingOnAppStore() {
      let key = "Ignored rating on AppStore"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsRatedAppOnAppStore = Analytics
extension AnalyticsRatedAppOnAppStore {
    
  static func trackRatedAppOnAppStore() {
      let key = "Rated app on app store"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsIgnoredRatingInApp = Analytics
extension AnalyticsIgnoredRatingInApp {
    
  static func trackIgnoredRatingInApp() {
      let key = "Ignored rating in app"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsRatedApp = Analytics
extension AnalyticsRatedApp {
    
  static func trackRatedApp(rating:String? ) {
      let key = "Rated app"
      var properties:[String:Any] = [:]
      if let rating = rating {
          properties["rating"] = rating
      }
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsFinishedTutorial = Analytics
extension AnalyticsFinishedTutorial {
    
  static func trackFinishedTutorial() {
      let key = "Finished Tutorial"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava", "branch" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsImportedPhotos = Analytics
extension AnalyticsImportedPhotos {
  enum AnalyticsImportedPhotosSection : String{
    case `screenshots` = "Screenshots"
    case `gallery` = "Gallery"
    }
    
  static func trackImportedPhotos(section:AnalyticsImportedPhotosSection,  count:Int ) {
      let key = "Imported Photos"
      var properties:[String:Any] = [:]
        properties["Section"] = section.rawValue
        properties["Count"] = NSNumber.init(value: count)
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsStartedTutorial = Analytics
extension AnalyticsStartedTutorial {
    
  static func trackStartedTutorial() {
      let key = "Started Tutorial"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsSubmittedBlankEmail = Analytics
extension AnalyticsSubmittedBlankEmail {
    
  static func trackSubmittedBlankEmail() {
      let key = "Submitted blank email"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsSubmittedEmail = Analytics
extension AnalyticsSubmittedEmail {
    
  static func trackSubmittedEmail(email:String? ) {
      let key = "Submitted email"
      var properties:[String:Any] = [:]
      if let email = email {
          properties["email"] = email
      }
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsSkippedTutorial = Analytics
extension AnalyticsSkippedTutorial {
    
  static func trackSkippedTutorial() {
      let key = "Skipped Tutorial"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsCompletedTutorialVideo = Analytics
extension AnalyticsCompletedTutorialVideo {
    
  static func trackCompletedTutorialVideo() {
      let key = "Completed Tutorial Video"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsContinuedTutorialVideo = Analytics
extension AnalyticsContinuedTutorialVideo {
    
  static func trackContinuedTutorialVideo() {
      let key = "Continued Tutorial Video"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsPausedTutorialVideo = Analytics
extension AnalyticsPausedTutorialVideo {
    
  static func trackPausedTutorialVideo() {
      let key = "Paused Tutorial Video"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsReplayedTutorialVideo = Analytics
extension AnalyticsReplayedTutorialVideo {
    
  static func trackReplayedTutorialVideo() {
      let key = "Replayed Tutorial Video"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsStartedTutorialVideo = Analytics
extension AnalyticsStartedTutorialVideo {
    
  static func trackStartedTutorialVideo() {
      let key = "Started Tutorial Video"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsOpenedFiltersView = Analytics
extension AnalyticsOpenedFiltersView {
    
  static func trackOpenedFiltersView() {
      let key = "Opened Filters View"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsOpenedPicker = Analytics
extension AnalyticsOpenedPicker {
    
  static func trackOpenedPicker() {
      let key = "Opened Picker"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsOpenedWithRemoteNotification = Analytics
extension AnalyticsOpenedWithRemoteNotification {
    
  static func trackOpenedWithRemoteNotification(fromIntercom:Bool? ) {
      let key = "Opened with remote notification"
      var properties:[String:Any] = [:]
      if let fromIntercom = fromIntercom {
          properties["fromIntercom"] = fromIntercom.toStringLiteral()
      }
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsReceivedProductsFromSyte = Analytics
extension AnalyticsReceivedProductsFromSyte {
    
  static func trackReceivedProductsFromSyte(productCount:Int?,  optionsMask:Int? ) {
      let key = "received products from Syte"
      var properties:[String:Any] = [:]
      if let productCount = productCount {
          properties["productCount"] = NSNumber.init(value: productCount)
      }
      if let optionsMask = optionsMask {
          properties["optionsMask"] = NSNumber.init(value: optionsMask)
      }
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsReceivedRemoteNotification = Analytics
extension AnalyticsReceivedRemoteNotification {
    
  static func trackReceivedRemoteNotification(fromIntercom:Bool? ) {
      let key = "Received remote notification"
      var properties:[String:Any] = [:]
      if let fromIntercom = fromIntercom {
          properties["fromIntercom"] = fromIntercom.toStringLiteral()
      }
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsRefreshedWebpage = Analytics
extension AnalyticsRefreshedWebpage {
    
  static func trackRefreshedWebpage(url:String? ) {
      let key = "Refreshed webpage"
      var properties:[String:Any] = [:]
      if let url = url {
          properties["url"] = url
      }
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsScreenshotNotificationAccepted = Analytics
extension AnalyticsScreenshotNotificationAccepted {
    
  static func trackScreenshotNotificationAccepted(screenshotCount:Int ) {
      let key = "Screenshot notification accepted"
      var properties:[String:Any] = [:]
        properties["Screenshot count"] = NSNumber.init(value: screenshotCount)
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsScreenshotNotificationCancelled = Analytics
extension AnalyticsScreenshotNotificationCancelled {
    
  static func trackScreenshotNotificationCancelled(screenshotCount:Int ) {
      let key = "Screenshot notification cancelled"
      var properties:[String:Any] = [:]
        properties["Screenshot count"] = NSNumber.init(value: screenshotCount)
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsSentImageToSyte = Analytics
extension AnalyticsSentImageToSyte {
    
  static func trackSentImageToSyte() {
      let key = "sent image to Syte"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsSessionEnded = Analytics
extension AnalyticsSessionEnded {
    
  static func trackSessionEnded() {
      let key = "sessionEnded"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsSessionStarted = Analytics
extension AnalyticsSessionStarted {
    
  static func trackSessionStarted() {
      let key = "sessionStarted"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsSetFiler = Analytics
extension AnalyticsSetFiler {
    
  static func trackSetFiler(name:String,  newValue:String ) {
      let key = "Set \(name) Filter to \(newValue)"
      var properties:[String:Any] = [:]
        properties["name"] = name
        properties["newValue"] = newValue
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsSetGlobalGenderFiler = Analytics
extension AnalyticsSetGlobalGenderFiler {
    
  static func trackSetGlobalGenderFiler(gender:String ) {
      let key = "Set Global Gender Filter to \(gender)"
      var properties:[String:Any] = [:]
        properties["gender"] = gender
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsSetGlobalSizeFiler = Analytics
extension AnalyticsSetGlobalSizeFiler {
    
  static func trackSetGlobalSizeFiler(size:String ) {
      let key = "Set Global Size Filter to \(size)"
      var properties:[String:Any] = [:]
        properties["size"] = size
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsStartedDownloadingClarifaiModel = Analytics
extension AnalyticsStartedDownloadingClarifaiModel {
    
  static func trackStartedDownloadingClarifaiModel() {
      let key = "started downloading Clarifai model"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsTappedOnSegmentedControl = Analytics
extension AnalyticsTappedOnSegmentedControl {
    
  static func trackTappedOnSegmentedControl(selectedSegmentTitle:String ) {
      let key = "Tapped \(selectedSegmentTitle) Picker List"
      var properties:[String:Any] = [:]
        properties["selectedSegmentTitle"] = selectedSegmentTitle
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsTappedOnShoppable = Analytics
extension AnalyticsTappedOnShoppable {
    
  static func trackTappedOnShoppable() {
      let key = "Tapped on shoppable"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsTookScreenshot = Analytics
extension AnalyticsTookScreenshot {
    
  static func trackTookScreenshot() {
      let key = "Took Screenshot"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsTookScreenshotWhileShowingIntercomWindow = Analytics
extension AnalyticsTookScreenshotWhileShowingIntercomWindow {
    
  static func trackTookScreenshotWhileShowingIntercomWindow() {
      let key = "Took Screenshot While Showing Intercom Window"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsUserAge = Analytics
extension AnalyticsUserAge {
    
  static func trackUserAge() {
      let key = "User Age"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsUserExitedTutorialVideo = Analytics
extension AnalyticsUserExitedTutorialVideo {
    
  static func trackUserExitedTutorialVideo(progressInSeconds:Double? ) {
      let key = "User Exited Tutorial Video"
      var properties:[String:Any] = [:]
      if let progressInSeconds = progressInSeconds {
          properties["progressInSeconds"] = NSNumber.init(value: progressInSeconds)
      }
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsUserProperties = Analytics
extension AnalyticsUserProperties {
    
  static func trackUserProperties() {
      let key = "User Properties"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsUserReceivedSharedScreenshots = Analytics
extension AnalyticsUserReceivedSharedScreenshots {
    
  static func trackUserReceivedSharedScreenshots() {
      let key = "user received shared screenshots"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsProductAddedToCart = Analytics
extension AnalyticsProductAddedToCart {
  enum AnalyticsProductAddedToCartPage : String{
    case `favorite` = "Favorite"
    case `productDetail` = "ProductDetail"
    }
    
  static func trackProductAddedToCart(product:Product?,  page:AnalyticsProductAddedToCartPage? ) {
      let key = "Product added to cart"
      var properties:[String:Any] = [:]
      if let product = product {
          propertiesFor(product).forEach { properties[$0] = $1 }
      }
      if let page = page {
          properties["page"] = page.rawValue
      }
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsProductFavorited = Analytics
extension AnalyticsProductFavorited {
  enum AnalyticsProductFavoritedPage : String{
    case `productList` = "productList"
    case `favorites` = "favorites"
    case `productWebView` = "Product Web View"
    case `product` = "product"
    }
    
  static func trackProductFavorited(product:Product?,  page:AnalyticsProductFavoritedPage ) {
      let key = "Product favorited"
      var properties:[String:Any] = [:]
      if let product = product {
          propertiesFor(product).forEach { properties[$0] = $1 }
      }
        properties["page"] = page.rawValue
            
      FBSDKAppEvents.logEvent(FBSDKAppEventNameAddedToWishlist, parameters: [FBSDKAppEventParameterNameSuccess:FBSDKAppEventParameterValueNo ])


      // Aliases used to keep reverse compatability
      if let a = properties["screenshot-imageURL"] {
        if properties["screenshot"] == nil {
            properties["screenshot"] = a
        }
      }
      if let a = properties["product-brand"] {
        if properties["brand"] == nil {
            properties["brand"] = a
        }
      }
      if let a = properties["product-imageURL"] {
        if properties["imageUrl"] == nil {
            properties["imageUrl"] = a
        }
      }
      if let a = properties["product-price"] {
        if properties["price"] == nil {
            properties["price"] = a
        }
      }
      if let a = properties["product-merchant"] {
        if properties["merchant"] == nil {
            properties["merchant"] = a
        }
      }

      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsTappedOnProductByBrand = Analytics
extension AnalyticsTappedOnProductByBrand {
  enum AnalyticsTappedOnProductByBrandBrand : String{
    case `boohoo` = "boohoo"
    case `missguided` = "missguided"
    case `forever21` = "forever 21"
    case `asos` = "asos"
    case `freePeople` = "free people"
    case `urbanOutfitters` = "urban outfitters"
    case `riverIsland` = "river island"
    case `bdg` = "bdg"
    case `tommyHilfiger` = "tommy hilfiger"
    case `nbd` = "nbd"
    case `yooxcom` = "yoox.com"
    case `revolve` = "revolve"
    case `nordstrom` = "nordstrom"
    }
    
  static func trackTappedOnProductByBrand(product:Product?,  brand:AnalyticsTappedOnProductByBrandBrand ) {
      let key = "Tapped on \(brand) product"
      var properties:[String:Any] = [:]
      if let product = product {
          propertiesFor(product).forEach { properties[$0] = $1 }
      }
        properties["brand"] = brand.rawValue
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsProductForEmail = Analytics
extension AnalyticsProductForEmail {
    
  static func trackProductForEmail(product:Product?,  email:String? ) {
      let key = "Product for email"
      var properties:[String:Any] = [:]
      if let product = product {
          propertiesFor(product).forEach { properties[$0] = $1 }
      }
      if let email = email {
          properties["email"] = email
      }
            


      // Aliases used to keep reverse compatability
      if let a = properties["screenshot-imageURL"] {
        if properties["screenshot"] == nil {
            properties["screenshot"] = a
        }
      }
      if let a = properties["product-brand"] {
        if properties["brand"] == nil {
            properties["brand"] = a
        }
      }
      if let a = properties["product-imageURL"] {
        if properties["imageUrl"] == nil {
            properties["imageUrl"] = a
        }
      }
      if let a = properties["product-offerUrl"] {
        if properties["url"] == nil {
            properties["url"] = a
        }
      }
      if let a = properties["product-price"] {
        if properties["price"] == nil {
            properties["price"] = a
        }
      }
      if let a = properties["product-merchant"] {
        if properties["merchant"] == nil {
            properties["merchant"] = a
        }
      }
      if let a = properties["product-brandOrMerchant"] {
        if properties["title"] == nil {
            properties["title"] = a
        }
      }

      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsProductOpened = Analytics
extension AnalyticsProductOpened {
  enum AnalyticsProductOpenedSort : String{
    case `priceHighToLow` = "price high to low"
    case `priceLowToHigh` = "price low to high"
    case `similar` = "similar"
    case `brands` = "brands"
    }
  enum AnalyticsProductOpenedDisplayAs : String{
    case `productPage` = "productPage"
    case `error` = "error"
    case `embededSafari` = "embededSafari"
    case `safari` = "safari"
    case `chrome` = "chrome"
    }
  enum AnalyticsProductOpenedFromPage : String{
    case `favorite` = "Favorite"
    case `products` = "Products"
    case `productBar` = "ProductBar"
    case `productSimilar` = "ProductSimilar"
    }
    
  static func trackProductOpened(product:Product?,  order:Int?,  sort:AnalyticsProductOpenedSort?,  displayAs:AnalyticsProductOpenedDisplayAs?,  fromPage:AnalyticsProductOpenedFromPage? ) {
      let key = "Tapped on product"
      var properties:[String:Any] = [:]
      if let product = product {
          propertiesFor(product).forEach { properties[$0] = $1 }
      }
      if let order = order {
          properties["order"] = NSNumber.init(value: order)
      }
      if let sort = sort {
          properties["sort"] = sort.rawValue
      }
      if let displayAs = displayAs {
          properties["displayAs"] = displayAs.rawValue
      }
      if let fromPage = fromPage {
          properties["page"] = fromPage.rawValue
      }
            
      FBSDKAppEvents.logEvent(FBSDKAppEventNameViewedContent, parameters: [FBSDKAppEventParameterNameContentID:properties[product?.imageURL ?? String()] as Any ])



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsProductUnfavorited = Analytics
extension AnalyticsProductUnfavorited {
  enum AnalyticsProductUnfavoritedPage : String{
    case `productList` = "productList"
    case `favorites` = "favorites"
    case `productWebView` = "Product Web View"
    case `product` = "product"
    }
    
  static func trackProductUnfavorited(product:Product?,  page:AnalyticsProductUnfavoritedPage ) {
      let key = "Product unfavorited"
      var properties:[String:Any] = [:]
      if let product = product {
          propertiesFor(product).forEach { properties[$0] = $1 }
      }
        properties["page"] = page.rawValue
            
      FBSDKAppEvents.logEvent(FBSDKAppEventNameAddedToWishlist, parameters: [FBSDKAppEventParameterNameSuccess:FBSDKAppEventParameterValueNo ])


      // Aliases used to keep reverse compatability
      if let a = properties["screenshot-imageURL"] {
        if properties["screenshot"] == nil {
            properties["screenshot"] = a
        }
      }
      if let a = properties["product-brand"] {
        if properties["brand"] == nil {
            properties["brand"] = a
        }
      }
      if let a = properties["product-imageURL"] {
        if properties["imageUrl"] == nil {
            properties["imageUrl"] = a
        }
      }
      if let a = properties["product-price"] {
        if properties["price"] == nil {
            properties["price"] = a
        }
      }
      if let a = properties["product-merchant"] {
        if properties["merchant"] == nil {
            properties["merchant"] = a
        }
      }

      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsScreenshotDeleted = Analytics
extension AnalyticsScreenshotDeleted {
  enum AnalyticsScreenshotDeletedKind : String{
    case `multi` = "multi"
    case `single` = "single"
    }
    
  static func trackScreenshotDeleted(screenshot:Screenshot?,  kind:AnalyticsScreenshotDeletedKind ) {
      let key = "Removed screenshot"
      var properties:[String:Any] = [:]
      if let screenshot = screenshot {
          propertiesFor(screenshot).forEach { properties[$0] = $1 }
      }
        properties["kind"] = kind.rawValue
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsMatchsticksFlagged = Analytics
extension AnalyticsMatchsticksFlagged {
  enum AnalyticsMatchsticksFlaggedWhy : String{
    case `inappropriate` = "Inappropriate"
    case `copyright` = "Copyright"
    }
    
  static func trackMatchsticksFlagged(matchstick:Matchstick?,  why:AnalyticsMatchsticksFlaggedWhy ) {
      let key = "Matchsticks Flagged"
      var properties:[String:Any] = [:]
      if let matchstick = matchstick {
          propertiesFor(matchstick).forEach { properties[$0] = $1 }
      }
        properties["why"] = why.rawValue
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsMatchsticksSkip = Analytics
extension AnalyticsMatchsticksSkip {
  enum AnalyticsMatchsticksSkipBy : String{
    case `swipe` = "swipe"
    case `tap` = "tap"
    }
    
  static func trackMatchsticksSkip(matchstick:Matchstick?,  by:AnalyticsMatchsticksSkipBy ) {
      let key = "Matchsticks Skip"
      var properties:[String:Any] = [:]
      if let matchstick = matchstick {
          propertiesFor(matchstick).forEach { properties[$0] = $1 }
      }
        properties["by"] = by.rawValue
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsMatchsticksAdd = Analytics
extension AnalyticsMatchsticksAdd {
  enum AnalyticsMatchsticksAddBy : String{
    case `swipe` = "swipe"
    case `tap` = "tap"
    case `open` = "open"
    }
    
  static func trackMatchsticksAdd(matchstick:Matchstick?,  by:AnalyticsMatchsticksAddBy ) {
      let key = "Matchsticks Add"
      var properties:[String:Any] = [:]
      if let matchstick = matchstick {
          propertiesFor(matchstick).forEach { properties[$0] = $1 }
      }
        properties["by"] = by.rawValue
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsScreenshotOpenedWithoutShoppables = Analytics
extension AnalyticsScreenshotOpenedWithoutShoppables {
    
  static func trackScreenshotOpenedWithoutShoppables(screenshot:Screenshot? ) {
      let key = "Screenshot Opened Without Shoppables"
      var properties:[String:Any] = [:]
      if let screenshot = screenshot {
          propertiesFor(screenshot).forEach { properties[$0] = $1 }
      }
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsShareDiscover = Analytics
extension AnalyticsShareDiscover {
    
  static func trackShareDiscover(screenshot:Screenshot? ) {
      let key = "Share Discover"
      var properties:[String:Any] = [:]
      if let screenshot = screenshot {
          propertiesFor(screenshot).forEach { properties[$0] = $1 }
      }
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava", "branch" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsShareIncomplete = Analytics
extension AnalyticsShareIncomplete {
    
  static func trackShareIncomplete(screenshot:Screenshot? ) {
      let key = "Share incomplete"
      var properties:[String:Any] = [:]
      if let screenshot = screenshot {
          propertiesFor(screenshot).forEach { properties[$0] = $1 }
      }
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsShareSocial = Analytics
extension AnalyticsShareSocial {
    
  static func trackShareSocial(screenshot:Screenshot? ) {
      let key = "Share Social"
      var properties:[String:Any] = [:]
      if let screenshot = screenshot {
          propertiesFor(screenshot).forEach { properties[$0] = $1 }
      }
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava", "branch" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsSharedScreenshotStarted = Analytics
extension AnalyticsSharedScreenshotStarted {
    
  static func trackSharedScreenshotStarted(screenshot:Screenshot? ) {
      let key = "Shared screenshot"
      var properties:[String:Any] = [:]
      if let screenshot = screenshot {
          propertiesFor(screenshot).forEach { properties[$0] = $1 }
      }
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsShuffledAScreenshot = Analytics
extension AnalyticsShuffledAScreenshot {
    
  static func trackShuffledAScreenshot(screenshot:Screenshot? ) {
      let key = "Shuffled a screenshot"
      var properties:[String:Any] = [:]
      if let screenshot = screenshot {
          propertiesFor(screenshot).forEach { properties[$0] = $1 }
      }
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsOpenedScreenshot = Analytics
extension AnalyticsOpenedScreenshot {
  enum AnalyticsOpenedScreenshotSource : String{
    case `list` = "list"
    case `discover` = "discover"
    }
    
  static func trackOpenedScreenshot(screenshot:Screenshot?,  source:AnalyticsOpenedScreenshotSource? ) {
      let key = "Tapped on screenshot"
      var properties:[String:Any] = [:]
      if let screenshot = screenshot {
          propertiesFor(screenshot).forEach { properties[$0] = $1 }
      }
      if let source = source {
          properties["source"] = source.rawValue
      }
            


      // Aliases used to keep reverse compatability
      if let a = properties["screenshot-imageURL"] {
        if properties["screenshot"] == nil {
            properties["screenshot"] = a
        }
      }

      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsShoppableScrolledFirstTime = Analytics
extension AnalyticsShoppableScrolledFirstTime {
    
  static func trackShoppableScrolledFirstTime(shoppable:Shoppable?,  rating:String?,  screenshot:String?,  category:String?,  augmentedOffersUrl:String? ) {
      let key = "Shoppable scrolled first time"
      var properties:[String:Any] = [:]
      if let shoppable = shoppable {
          propertiesFor(shoppable).forEach { properties[$0] = $1 }
      }
      if let rating = rating {
          properties["Rating"] = rating
      }
      if let screenshot = screenshot {
          properties["Screenshot"] = screenshot
      }
      if let category = category {
          properties["Category"] = category
      }
      if let augmentedOffersUrl = augmentedOffersUrl {
          properties["AugmentedOffersUrl"] = augmentedOffersUrl
      }
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsShoppableFeedbackNegative = Analytics
extension AnalyticsShoppableFeedbackNegative {
    
  static func trackShoppableFeedbackNegative(shoppable:Shoppable?,  text:String ) {
      let key = "Shoppable Feedback Negative"
      var properties:[String:Any] = [:]
      if let shoppable = shoppable {
          propertiesFor(shoppable).forEach { properties[$0] = $1 }
      }
        properties["text"] = text
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsShoppableRatingNegative = Analytics
extension AnalyticsShoppableRatingNegative {
    
  static func trackShoppableRatingNegative(shoppable:Shoppable? ) {
      let key = "Shoppable rating negative"
      var properties:[String:Any] = [:]
      if let shoppable = shoppable {
          propertiesFor(shoppable).forEach { properties[$0] = $1 }
      }
            

      // these properities are always sent

      properties["Rating"] = 5

      // Aliases used to keep reverse compatability
      if let a = properties["screenshot-imageURL"] {
        if properties["Screenshot"] == nil {
            properties["Screenshot"] = a
        }
      }
      if let a = properties["shoppable-category"] {
        if properties["Category"] == nil {
            properties["Category"] = a
        }
      }
      if let a = properties["shoppable-offerURL"] {
        if properties["AugmentedOffersUrl"] == nil {
            properties["AugmentedOffersUrl"] = a
        }
      }

      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsShoppableRatingPositive = Analytics
extension AnalyticsShoppableRatingPositive {
    
  static func trackShoppableRatingPositive(shoppable:Shoppable? ) {
      let key = "Shoppable rating positive"
      var properties:[String:Any] = [:]
      if let shoppable = shoppable {
          propertiesFor(shoppable).forEach { properties[$0] = $1 }
      }
            

      // these properities are always sent

      properties["Rating"] = 5

      // Aliases used to keep reverse compatability
      if let a = properties["screenshot-imageURL"] {
        if properties["Screenshot"] == nil {
            properties["Screenshot"] = a
        }
      }
      if let a = properties["shoppable-category"] {
        if properties["Category"] == nil {
            properties["Category"] = a
        }
      }
      if let a = properties["shoppable-offerURL"] {
        if properties["AugmentedOffersUrl"] == nil {
            properties["AugmentedOffersUrl"] = a
        }
      }

      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsWebViewInvalidUrl = Analytics
extension AnalyticsWebViewInvalidUrl {
    
  static func trackWebViewInvalidUrl(url:String? ) {
      let key = "WebView invalid url"
      var properties:[String:Any] = [:]
      if let url = url {
          properties["url"] = url
      }
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsWokeFromSilentPush = Analytics
extension AnalyticsWokeFromSilentPush {
    
  static func trackWokeFromSilentPush() {
      let key = "Woke From Silent Push"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      Analytics.debugShowLoggedAnalytics(eventName: key, properties: properties, destinations:["appsee", "segment", "kochava" ])
      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 