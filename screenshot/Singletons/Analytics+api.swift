// STOP!  DO not edit the file below
// only create by auto generting
// created by: Jonathan Rose(rose@screenshopit.com) on computer -jonathanrose
<<<<<<< HEAD
// created on: Tue Apr 10 14:23:44 IDT 2018
// created from: codeGeneration -  - 5404e55  WARNING BRANCH WAS DIRTY 
=======
// created on: Tue May  1 12:13:21 IDT 2018
// created from: changes -  - db06ec6  WARNING BRANCH WAS DIRTY 
>>>>>>> analytics2
//  Copyright © 2018 crazeapp. All rights reserved.


import Foundation
<<<<<<< HEAD
=======
import FBSDKCoreKit

>>>>>>> analytics2



typealias AnalyticsAcceptedPushPermissions = Analytics
extension AnalyticsAcceptedPushPermissions {
    
<<<<<<< HEAD
  func trackAcceptedPushPermissions() {
      let key = "Accepted Push Permissions"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
=======
  static func trackAcceptedPushPermissions() {
      let key = "Accepted Push Permissions"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

typealias AnalyticsAPNDisabled = Analytics
extension AnalyticsAPNDisabled {
    
<<<<<<< HEAD
  func trackAPNDisabled() {
      let key = "APN Disabled"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
=======
  static func trackAPNDisabled(token:String? ) {
      let key = "APN Disabled"
      var properties:[String:Any] = [:]
      if let token = token {
          properties["token"] = token
      }
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

typealias AnalyticsAPNEnabled = Analytics
extension AnalyticsAPNEnabled {
    
<<<<<<< HEAD
  func trackAPNEnabled() {
      let key = "APN Enabled"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
=======
  static func trackAPNEnabled(token:String? ) {
      let key = "APN Enabled"
      var properties:[String:Any] = [:]
      if let token = token {
          properties["token"] = token
      }
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

typealias AnalyticsAppOpenedFromLocalNotification = Analytics
extension AnalyticsAppOpenedFromLocalNotification {
    
<<<<<<< HEAD
  func trackAppOpenedFromLocalNotification() {
      let key = "app opened from local notification"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
=======
  static func trackAppOpenedFromLocalNotification() {
      let key = "app opened from local notification"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

typealias AnalyticsAppSentLocalPushNotification = Analytics
extension AnalyticsAppSentLocalPushNotification {
    
<<<<<<< HEAD
  func trackAppSentLocalPushNotification() {
      let key = "app sent local push notification"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
=======
  static func trackAppSentLocalPushNotification() {
      let key = "app sent local push notification"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

typealias AnalyticsAutomaticallyExitedTutorialVideo = Analytics
extension AnalyticsAutomaticallyExitedTutorialVideo {
    
<<<<<<< HEAD
  func trackAutomaticallyExitedTutorialVideo() {
      let key = "Automatically Exited Tutorial Video"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
  }
}

 

typealias AnalyticsBypassedClarifai = Analytics
extension AnalyticsBypassedClarifai {
    
  func trackBypassedClarifai() {
      let key = "bypassed Clarifai"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
=======
  static func trackAutomaticallyExitedTutorialVideo() {
      let key = "Automatically Exited Tutorial Video"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

typealias AnalyticsBypassedClarifaiOnRetry = Analytics
extension AnalyticsBypassedClarifaiOnRetry {
    
<<<<<<< HEAD
  func trackBypassedClarifaiOnRetry() {
      let key = "bypassed Clarifai on retry"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
=======
  static func trackBypassedClarifaiOnRetry() {
      let key = "bypassed Clarifai on retry"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

typealias AnalyticsCanceledPhotoCreation = Analytics
extension AnalyticsCanceledPhotoCreation {
    
<<<<<<< HEAD
  func trackCanceledPhotoCreation() {
      let key = "Canceled Photo Creation"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
  }
}

 

typealias AnalyticsCompletedTutorialVideo = Analytics
extension AnalyticsCompletedTutorialVideo {
    
  func trackCompletedTutorialVideo() {
      let key = "Completed Tutorial Video"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
  }
}

 

typealias AnalyticsContinuedTutorialVideo = Analytics
extension AnalyticsContinuedTutorialVideo {
    
  func trackContinuedTutorialVideo() {
      let key = "Continued Tutorial Video"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
=======
  static func trackCanceledPhotoCreation() {
      let key = "Canceled Photo Creation"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

typealias AnalyticsCreatedPhoto = Analytics
extension AnalyticsCreatedPhoto {
    
<<<<<<< HEAD
  func trackCreatedPhoto() {
      let key = "Created Photo"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
=======
  static func trackCreatedPhoto() {
      let key = "Created Photo"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

typealias AnalyticsDailyStreak = Analytics
extension AnalyticsDailyStreak {
    
<<<<<<< HEAD
  func trackDailyStreak(current:String? ) {
      let key = "Daily Streak"
      var properties:[String:Any] = [:]
      if let current = current {
          properties["current"] = current
      }
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
=======
  static func trackDailyStreak(current:Int? ) {
      let key = "Daily Streak"
      var properties:[String:Any] = [:]
      if let current = current {
          properties["current"] = NSNumber.init(value: current)
      }
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

typealias AnalyticsDeniedPushPermissions = Analytics
extension AnalyticsDeniedPushPermissions {
    
<<<<<<< HEAD
  func trackDeniedPushPermissions() {
      let key = "Denied Push Permissions"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
=======
  static func trackDeniedPushPermissions() {
      let key = "Denied Push Permissions"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

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

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

typealias AnalyticsErrImgHang = Analytics
extension AnalyticsErrImgHang {
    
<<<<<<< HEAD
  func trackErrImgHang(reason:String? ) {
=======
  static func trackErrImgHang(reason:String? ) {
>>>>>>> analytics2
      let key = "err img hang"
      var properties:[String:Any] = [:]
      if let reason = reason {
          properties["reason"] = reason
      }
<<<<<<< HEAD
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
=======
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

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

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
  }
}

 

typealias AnalyticsReceivedResponseFromClarifai = Analytics
extension AnalyticsReceivedResponseFromClarifai {
    
  static func trackReceivedResponseFromClarifai(isFashion:Bool,  isFurniture:Bool ) {
      let key = "received response from Clarifai"
      var properties:[String:Any] = [:]
        properties["isFashion"] = isFashion
        properties["isFurniture"] = isFurniture
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

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

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

typealias AnalyticsError = Analytics
extension AnalyticsError {
  enum AnalyticsErrorType : String{
<<<<<<< HEAD
    case `noHardDriveSpace`
    }
    
  func trackError(type:AnalyticsErrorType?,  domain:String?,  code:String?,  localizedDescription:String? ) {
      let key = "Error"
      var properties:[String:Any] = [:]
      if let type = type {
          properties["type"] = type
=======
    case `noHardDriveSpace` = "noHardDriveSpace"
    }
    
  static func trackError(type:AnalyticsErrorType?,  domain:String?,  code:Int?,  localizedDescription:String? ) {
      let key = "Error"
      var properties:[String:Any] = [:]
      if let type = type {
          properties["type"] = type.rawValue
>>>>>>> analytics2
      }
      if let domain = domain {
          properties["domain"] = domain
      }
      if let code = code {
<<<<<<< HEAD
          properties["code"] = code
=======
          properties["code"] = NSNumber.init(value: code)
>>>>>>> analytics2
      }
      if let localizedDescription = localizedDescription {
          properties["localizedDescription"] = localizedDescription
      }
<<<<<<< HEAD
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
=======
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

<<<<<<< HEAD
typealias AnalyticsFinishedDownloadingClarifaiModel = Analytics
extension AnalyticsFinishedDownloadingClarifaiModel {
    
  func trackFinishedDownloadingClarifaiModel() {
      let key = "finished downloading Clarifai model"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
  }
}

 

typealias AnalyticsFinishedTutorial = Analytics
extension AnalyticsFinishedTutorial {
    
  func trackFinishedTutorial() {
      let key = "Finished Tutorial"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
=======
typealias AnalyticsGameScoreIncreased = Analytics
extension AnalyticsGameScoreIncreased {
    
  static func trackGameScoreIncreased() {
      let key = "Game Score Increased"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

typealias AnalyticsGameCollision = Analytics
extension AnalyticsGameCollision {
    
<<<<<<< HEAD
  func trackGameCollision() {
      let key = "Game Collision"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
=======
  static func trackGameCollision() {
      let key = "Game Collision"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

typealias AnalyticsGameInterrupted = Analytics
extension AnalyticsGameInterrupted {
  enum AnalyticsGameInterruptedFrom : String{
<<<<<<< HEAD
    case `userNavigating`
    case `appBackgrounding`
    case `pageLoading`
    }
    
  func trackGameInterrupted(from:AnalyticsGameInterruptedFrom ) {
      let key = "Game Interrupted"
      var properties:[String:Any] = [:]
      properties["From"] = from
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
=======
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

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

typealias AnalyticsGameOpened = Analytics
extension AnalyticsGameOpened {
    
<<<<<<< HEAD
  func trackGameOpened() {
      let key = "Game Opened"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
=======
  static func trackGameOpened() {
      let key = "Game Opened"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

typealias AnalyticsGameRestarted = Analytics
extension AnalyticsGameRestarted {
    
<<<<<<< HEAD
  func trackGameRestarted() {
      let key = "Game Restarted"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
=======
  static func trackGameRestarted() {
      let key = "Game Restarted"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

typealias AnalyticsGameResumed = Analytics
extension AnalyticsGameResumed {
  enum AnalyticsGameResumedFrom : String{
<<<<<<< HEAD
    case `appBackgrounding`
    }
    
  func trackGameResumed(from:AnalyticsGameResumedFrom? ) {
      let key = "Game Resumed"
      var properties:[String:Any] = [:]
      if let from = from {
          properties["From"] = from
      }
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
=======
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

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

<<<<<<< HEAD
typealias AnalyticsGameScoreIncreased = Analytics
extension AnalyticsGameScoreIncreased {
    
  func trackGameScoreIncreased() {
      let key = "Game Score Increased"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
=======
typealias AnalyticsGameStarted = Analytics
extension AnalyticsGameStarted {
    
  static func trackGameStarted() {
      let key = "Game Started"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

<<<<<<< HEAD
typealias AnalyticsGameStarted = Analytics
extension AnalyticsGameStarted {
    
  func trackGameStarted() {
      let key = "Game Started"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
=======
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

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

<<<<<<< HEAD
typealias AnalyticsIgnoredRatingInApp = Analytics
extension AnalyticsIgnoredRatingInApp {
    
  func trackIgnoredRatingInApp() {
      let key = "Ignored rating in app"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
=======
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

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

typealias AnalyticsIgnoredRatingOnAppStore = Analytics
extension AnalyticsIgnoredRatingOnAppStore {
    
<<<<<<< HEAD
  func trackIgnoredRatingOnAppStore() {
      let key = "Ignored rating on AppStore"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
=======
  static func trackIgnoredRatingOnAppStore() {
      let key = "Ignored rating on AppStore"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

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

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

typealias AnalyticsImportedPhotos = Analytics
extension AnalyticsImportedPhotos {
  enum AnalyticsImportedPhotosSection : String{
<<<<<<< HEAD
    case `screenshots`
    case `gallery`
    }
    
  func trackImportedPhotos(section:AnalyticsImportedPhotosSection,  count:String ) {
      let key = "Imported Photos"
      var properties:[String:Any] = [:]
      properties["Section"] = section
      properties["Count"] = count
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
=======
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

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

<<<<<<< HEAD
typealias AnalyticsInAppPurchase = Analytics
extension AnalyticsInAppPurchase {
  enum AnalyticsInAppPurchasePurchase : String{
    case `stylists`
    }
  enum AnalyticsInAppPurchaseType : String{
    case `onetime`
    }
    
  func trackInAppPurchase(purchase:AnalyticsInAppPurchasePurchase,  type:AnalyticsInAppPurchaseType,  price:String ) {
      let key = "InAppPurchase"
      var properties:[String:Any] = [:]
      properties["purchase"] = purchase
      properties["type"] = type
      properties["price"] = price
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
=======
typealias AnalyticsSubmittedBlankEmail = Analytics
extension AnalyticsSubmittedBlankEmail {
    
  static func trackSubmittedBlankEmail() {
      let key = "Submitted blank email"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

<<<<<<< HEAD
typealias AnalyticsOpenedFiltersView = Analytics
extension AnalyticsOpenedFiltersView {
    
  func trackOpenedFiltersView() {
      let key = "Opened Filters View"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
=======
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

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

<<<<<<< HEAD
typealias AnalyticsOpenedPicker = Analytics
extension AnalyticsOpenedPicker {
    
  func trackOpenedPicker() {
      let key = "Opened Picker"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
=======
typealias AnalyticsSkippedTutorial = Analytics
extension AnalyticsSkippedTutorial {
    
  static func trackSkippedTutorial() {
      let key = "Skipped Tutorial"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

<<<<<<< HEAD
typealias AnalyticsOpenedWithRemoteNotification = Analytics
extension AnalyticsOpenedWithRemoteNotification {
  enum AnalyticsOpenedWithRemoteNotificationFromIntercom : String{
    case `true`
    case `false`
    }
    
  func trackOpenedWithRemoteNotification(fromIntercom:AnalyticsOpenedWithRemoteNotificationFromIntercom? ) {
      let key = "Opened with remote notification"
      var properties:[String:Any] = [:]
      if let fromIntercom = fromIntercom {
          properties["fromIntercom"] = fromIntercom
      }
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
=======
typealias AnalyticsCompletedTutorialVideo = Analytics
extension AnalyticsCompletedTutorialVideo {
    
  static func trackCompletedTutorialVideo() {
      let key = "Completed Tutorial Video"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

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

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

<<<<<<< HEAD
typealias AnalyticsPausedTutorialVideo = Analytics
extension AnalyticsPausedTutorialVideo {
    
  func trackPausedTutorialVideo() {
      let key = "Paused Tutorial Video"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
=======
typealias AnalyticsUserReceivedSharedScreenshots = Analytics
extension AnalyticsUserReceivedSharedScreenshots {
    
  static func trackUserReceivedSharedScreenshots() {
      let key = "user received shared screenshots"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

<<<<<<< HEAD
typealias AnalyticsProductFavorited = Analytics
extension AnalyticsProductFavorited {
  enum AnalyticsProductFavoritedPage : String{
    case `productList`
    case `favorites`
    }
    
  func trackProductFavorited(product:Product,  page:AnalyticsProductFavoritedPage ) {
      let key = "Product favorited"
      var properties:[String:Any] = [:]
      propertiesFor(product).forEach { properties[$0] = $1 }
      properties["page"] = page
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
=======
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

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

typealias AnalyticsTappedOnProduct = Analytics
extension AnalyticsTappedOnProduct {
  enum AnalyticsTappedOnProductSort : String{
<<<<<<< HEAD
    case `priceHighToLow`
    case `priceLowToHigh`
    case `similar`
    case `brands`
    }
  enum AnalyticsTappedOnProductDisplayAs : String{
    case `inAppProduct`
    case `error`
    case `embededSafari`
    case `safari`
    case `chrome`
    }
  enum AnalyticsTappedOnProductPage : String{
    case `favorite`
    case `products`
    case `productBar`
    case `productSimilar`
    }
    
  func trackTappedOnProduct(product:Product,  order:Int?,  sort:AnalyticsTappedOnProductSort?,  displayAs:AnalyticsTappedOnProductDisplayAs?,  page:AnalyticsTappedOnProductPage? ) {
      let key = "Tapped on product"
      var properties:[String:Any] = [:]
      propertiesFor(product).forEach { properties[$0] = $1 }
      if let order = order {
          properties["order"] = order
      }
      if let sort = sort {
          properties["sort"] = sort
      }
      if let displayAs = displayAs {
          properties["displayAs"] = displayAs
      }
      if let page = page {
          properties["page"] = page
      }
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
  }
}

 

typealias AnalyticsProductUnfavorited = Analytics
extension AnalyticsProductUnfavorited {
  enum AnalyticsProductUnfavoritedPage : String{
    case `productList`
    case `favorites`
    }
    
  func trackProductUnfavorited(product:Product,  page:AnalyticsProductUnfavoritedPage ) {
      let key = "Product unfavorited"
      var properties:[String:Any] = [:]
      propertiesFor(product).forEach { properties[$0] = $1 }
      properties["page"] = page
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
=======
    case `priceHighToLow` = "price high to low"
    case `priceLowToHigh` = "price low to high"
    case `similar` = "similar"
    case `brands` = "brands"
    }
  enum AnalyticsTappedOnProductDisplayAs : String{
    case `error` = "error"
    case `embededSafari` = "embededSafari"
    case `safari` = "safari"
    case `chrome` = "chrome"
    }
  enum AnalyticsTappedOnProductPage : String{
    case `favorite` = "Favorite"
    case `products` = "Products"
    case `productBar` = "ProductBar"
    case `productSimilar` = "ProductSimilar"
    }
    
  static func trackTappedOnProduct(product:Product?,  order:Int?,  sort:AnalyticsTappedOnProductSort?,  displayAs:AnalyticsTappedOnProductDisplayAs?,  page:AnalyticsTappedOnProductPage? ) {
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
      if let page = page {
          properties["page"] = page.rawValue
      }
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

<<<<<<< HEAD
typealias AnalyticsProductForEmail = Analytics
extension AnalyticsProductForEmail {
  enum AnalyticsProductForEmailDisplayAs : String{
    case `inAppProduct`
    case `error`
    case `embededSafari`
    case `safari`
    case `chrome`
    }
  enum AnalyticsProductForEmailPage : String{
    case `favorite`
    case `products`
    case `productBar`
    case `productSimilar`
    }
    
  func trackProductForEmail(merchant:String?,  brand:String?,  url:String?,  email:String?,  imageUrl:String?,  screenshot:String?,  price:String?,  title:String?,  displayAs:AnalyticsProductForEmailDisplayAs?,  page:AnalyticsProductForEmailPage? ) {
      let key = "Product for email"
      var properties:[String:Any] = [:]
      if let merchant = merchant {
          properties["merchant"] = merchant
      }
      if let brand = brand {
          properties["brand"] = brand
      }
      if let url = url {
          properties["url"] = url
      }
      if let email = email {
          properties["email"] = email
      }
      if let imageUrl = imageUrl {
          properties["imageUrl"] = imageUrl
      }
      if let screenshot = screenshot {
          properties["screenshot"] = screenshot
      }
      if let price = price {
          properties["price"] = price
      }
      if let title = title {
          properties["title"] = title
      }
      if let displayAs = displayAs {
          properties["displayAs"] = displayAs
      }
      if let page = page {
          properties["page"] = page
      }
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
  }
}

 

typealias AnalyticsRatedApp = Analytics
extension AnalyticsRatedApp {
    
  func trackRatedApp(rating:String? ) {
      let key = "Rated app"
      var properties:[String:Any] = [:]
      if let rating = rating {
          properties["rating"] = rating
      }
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
  }
}

 

typealias AnalyticsRatedAppOnAppStore = Analytics
extension AnalyticsRatedAppOnAppStore {
    
  func trackRatedAppOnAppStore() {
      let key = "Rated app on app store"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
=======
typealias AnalyticsProductDetailPage = Analytics
extension AnalyticsProductDetailPage {
  enum AnalyticsProductDetailPageSort : String{
    case `priceHighToLow` = "price high to low"
    case `priceLowToHigh` = "price low to high"
    case `similar` = "similar"
    case `brands` = "brands"
    }
  enum AnalyticsProductDetailPagePage : String{
    case `favorite` = "Favorite"
    case `products` = "Products"
    case `productBar` = "ProductBar"
    case `productSimilar` = "ProductSimilar"
    }
    
  static func trackProductDetailPage(product:Product?,  order:Int?,  sort:AnalyticsProductDetailPageSort?,  page:AnalyticsProductDetailPagePage? ) {
      let key = "Product detail page"
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
      if let page = page {
          properties["page"] = page.rawValue
      }
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

<<<<<<< HEAD
typealias AnalyticsReceivedProductsFromSyte = Analytics
extension AnalyticsReceivedProductsFromSyte {
    
  func trackReceivedProductsFromSyte(productCount:String?,  optionsMask:String? ) {
      let key = "received products from Syte"
      var properties:[String:Any] = [:]
      if let productCount = productCount {
          properties["productCount"] = productCount
      }
      if let optionsMask = optionsMask {
          properties["optionsMask"] = optionsMask
      }
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
=======
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

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

<<<<<<< HEAD
typealias AnalyticsReceivedRemoteNotification = Analytics
extension AnalyticsReceivedRemoteNotification {
  enum AnalyticsReceivedRemoteNotificationFromIntercom : String{
    case `true`
    case `false`
    }
    
  func trackReceivedRemoteNotification(fromIntercom:AnalyticsReceivedRemoteNotificationFromIntercom? ) {
      let key = "Received remote notification"
      var properties:[String:Any] = [:]
      if let fromIntercom = fromIntercom {
          properties["fromIntercom"] = fromIntercom
      }
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
  }
}

 

typealias AnalyticsReceivedResponseFromClarifai = Analytics
extension AnalyticsReceivedResponseFromClarifai {
    
  func trackReceivedResponseFromClarifai(isFashion:String,  isFurniture:String ) {
      let key = "received response from Clarifai"
      var properties:[String:Any] = [:]
      properties["isFashion"] = isFashion
      properties["isFurniture"] = isFurniture
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
=======
typealias AnalyticsTappedOnProductByBrand = Analytics
extension AnalyticsTappedOnProductByBrand {
    
  static func trackTappedOnProductByBrand(product:Product?,  brand:String ) {
      let key = "Tapped on \(brand) product"
      var properties:[String:Any] = [:]
      if let product = product {
          propertiesFor(product).forEach { properties[$0] = $1 }
      }
        properties["brand"] = brand
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

<<<<<<< HEAD
typealias AnalyticsReceivedResponseFromSyte = Analytics
extension AnalyticsReceivedResponseFromSyte {
    
  func trackReceivedResponseFromSyte(imageUrl:String?,  segmentCount:String?,  categories:String? ) {
      let key = "received response from Syte"
      var properties:[String:Any] = [:]
      if let imageUrl = imageUrl {
          properties["imageUrl"] = imageUrl
      }
      if let segmentCount = segmentCount {
          properties["segmentCount"] = segmentCount
      }
      if let categories = categories {
          properties["categories"] = categories
      }
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
  }
}

 

typealias AnalyticsRefreshedWebpage = Analytics
extension AnalyticsRefreshedWebpage {
    
  func trackRefreshedWebpage(url:String? ) {
      let key = "Refreshed webpage"
      var properties:[String:Any] = [:]
      if let url = url {
          properties["url"] = url
      }
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
  }
}

 

typealias AnalyticsReplayedTutorialVideo = Analytics
extension AnalyticsReplayedTutorialVideo {
    
  func trackReplayedTutorialVideo() {
      let key = "Replayed Tutorial Video"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
=======
typealias AnalyticsProductForEmail = Analytics
extension AnalyticsProductForEmail {
  enum AnalyticsProductForEmailDisplayAs : String{
    case `inAppProduct` = "In app Product"
    case `error` = "error"
    case `embededSafari` = "embededSafari"
    case `safari` = "safari"
    case `chrome` = "chrome"
    }
  enum AnalyticsProductForEmailPage : String{
    case `favorite` = "Favorite"
    case `products` = "Products"
    case `productBar` = "ProductBar"
    case `productSimilar` = "ProductSimilar"
    }
    
  static func trackProductForEmail(product:Product?,  email:String?,  title:String?,  displayAs:AnalyticsProductForEmailDisplayAs?,  page:AnalyticsProductForEmailPage? ) {
      let key = "Product for email"
      var properties:[String:Any] = [:]
      if let product = product {
          propertiesFor(product).forEach { properties[$0] = $1 }
      }
      if let email = email {
          properties["email"] = email
      }
      if let title = title {
          properties["title"] = title
      }
      if let displayAs = displayAs {
          properties["displayAs"] = displayAs.rawValue
      }
      if let page = page {
          properties["page"] = page.rawValue
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

      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

<<<<<<< HEAD
typealias AnalyticsRequestedCustomStylist = Analytics
extension AnalyticsRequestedCustomStylist {
    
  func trackRequestedCustomStylist(screenshotImageURL:String? ) {
      let key = "Requested Custom Stylist"
      var properties:[String:Any] = [:]
      if let screenshotImageURL = screenshotImageURL {
          properties["screenshotImageURL"] = screenshotImageURL
      }
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
=======
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

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

typealias AnalyticsScreenshotDeleted = Analytics
extension AnalyticsScreenshotDeleted {
  enum AnalyticsScreenshotDeletedKind : String{
<<<<<<< HEAD
    case `multi`
    case `single`
    }
    
  func trackScreenshotDeleted(kind:AnalyticsScreenshotDeletedKind ) {
      let key = "Removed screenshot"
      var properties:[String:Any] = [:]
      properties["kind"] = kind
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
=======
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

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

typealias AnalyticsMatchsticksFlagged = Analytics
extension AnalyticsMatchsticksFlagged {
  enum AnalyticsMatchsticksFlaggedWhy : String{
<<<<<<< HEAD
    case `inappropriate`
    case `copyright`
    }
    
  func trackMatchsticksFlagged(matchstick:Matchstick,  why:AnalyticsMatchsticksFlaggedWhy ) {
      let key = "Matchsticks Flagged"
      var properties:[String:Any] = [:]
      propertiesFor(matchstick).forEach { properties[$0] = $1 }
      properties["why"] = why
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
=======
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

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

typealias AnalyticsMatchsticksSkip = Analytics
extension AnalyticsMatchsticksSkip {
  enum AnalyticsMatchsticksSkipBy : String{
<<<<<<< HEAD
    case `swipe`
    case `tap`
    }
    
  func trackMatchsticksSkip(matchstick:Matchstick,  by:AnalyticsMatchsticksSkipBy ) {
      let key = "Matchsticks Skip"
      var properties:[String:Any] = [:]
      propertiesFor(matchstick).forEach { properties[$0] = $1 }
      properties["by"] = by
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
  }
}

 

typealias AnalyticsMatchsticksAdd = Analytics
extension AnalyticsMatchsticksAdd {
  enum AnalyticsMatchsticksAddBy : String{
    case `swipe`
    case `tap`
    case `open`
    }
    
  func trackMatchsticksAdd(matchstick:Matchstick,  by:AnalyticsMatchsticksAddBy ) {
      let key = "Matchsticks Add"
      var properties:[String:Any] = [:]
      propertiesFor(matchstick).forEach { properties[$0] = $1 }
      properties["by"] = by
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
  }
}

 

typealias AnalyticsTappedOnScreenshot = Analytics
extension AnalyticsTappedOnScreenshot {
    
  func trackTappedOnScreenshot(screenshot:String? ) {
      let key = "Tapped on screenshot"
      var properties:[String:Any] = [:]
      if let screenshot = screenshot {
          properties["screenshot"] = screenshot
      }
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
  }
}

 

typealias AnalyticsScreenshotNotificationAccepted = Analytics
extension AnalyticsScreenshotNotificationAccepted {
    
  func trackScreenshotNotificationAccepted(screenshotCount:String ) {
      let key = "Screenshot notification accepted"
      var properties:[String:Any] = [:]
      properties["Screenshot count"] = screenshotCount
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
=======
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

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

<<<<<<< HEAD
typealias AnalyticsScreenshotNotificationCancelled = Analytics
extension AnalyticsScreenshotNotificationCancelled {
    
  func trackScreenshotNotificationCancelled(screenshotCount:String ) {
      let key = "Screenshot notification cancelled"
      var properties:[String:Any] = [:]
      properties["Screenshot count"] = screenshotCount
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
=======
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

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

typealias AnalyticsScreenshotOpenedWithoutShoppables = Analytics
extension AnalyticsScreenshotOpenedWithoutShoppables {
    
<<<<<<< HEAD
  func trackScreenshotOpenedWithoutShoppables() {
      let key = "Screenshot Opened Without Shoppables"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
  }
}

 

typealias AnalyticsSentImageToClarifai = Analytics
extension AnalyticsSentImageToClarifai {
    
  func trackSentImageToClarifai() {
      let key = "sent image to Clarifai"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
  }
}

 

typealias AnalyticsSentImageToSyte = Analytics
extension AnalyticsSentImageToSyte {
    
  func trackSentImageToSyte() {
      let key = "sent image to Syte"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
=======
  static func trackScreenshotOpenedWithoutShoppables(screenshot:Screenshot? ) {
      let key = "Screenshot Opened Without Shoppables"
      var properties:[String:Any] = [:]
      if let screenshot = screenshot {
          propertiesFor(screenshot).forEach { properties[$0] = $1 }
      }
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

<<<<<<< HEAD
typealias AnalyticsSessionEnded = Analytics
extension AnalyticsSessionEnded {
    
  func trackSessionEnded() {
      let key = "sessionEnded"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
  }
}

 

typealias AnalyticsSessionStarted = Analytics
extension AnalyticsSessionStarted {
    
  func trackSessionStarted() {
      let key = "sessionStarted"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
=======
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

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

<<<<<<< HEAD
typealias AnalyticsShareCompleted = Analytics
extension AnalyticsShareCompleted {
    
  func trackShareCompleted() {
      let key = "Share completed"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
=======
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

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

<<<<<<< HEAD
typealias AnalyticsShareIncomplete = Analytics
extension AnalyticsShareIncomplete {
    
  func trackShareIncomplete() {
      let key = "Share incomplete"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
=======
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

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

<<<<<<< HEAD
typealias AnalyticsSharedScreenshot = Analytics
extension AnalyticsSharedScreenshot {
    
  func trackSharedScreenshot() {
      let key = "Shared screenshot"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
=======
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

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

<<<<<<< HEAD
typealias AnalyticsShoppableFeedbackNegative = Analytics
extension AnalyticsShoppableFeedbackNegative {
    
  func trackShoppableFeedbackNegative(shoppable:Shoppable,  text:String ) {
      let key = "Shoppable Feedback Negative"
      var properties:[String:Any] = [:]
      propertiesFor(shoppable).forEach { properties[$0] = $1 }
      properties["text"] = text
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
=======
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

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

<<<<<<< HEAD
typealias AnalyticsShoppableRatingNegative = Analytics
extension AnalyticsShoppableRatingNegative {
    
  func trackShoppableRatingNegative(shoppable:Shoppable,  rating:String?,  screenshot:String?,  category:String?,  augmentedOffersUrl:String? ) {
      let key = "Shoppable rating negative"
      var properties:[String:Any] = [:]
      propertiesFor(shoppable).forEach { properties[$0] = $1 }
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
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
=======
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

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

<<<<<<< HEAD
typealias AnalyticsShoppableRatingPositive = Analytics
extension AnalyticsShoppableRatingPositive {
    
  func trackShoppableRatingPositive(shoppable:Shoppable,  rating:String?,  screenshot:String?,  category:String?,  augmentedOffersUrl:String? ) {
      let key = "Shoppable rating positive"
      var properties:[String:Any] = [:]
      propertiesFor(shoppable).forEach { properties[$0] = $1 }
=======
typealias AnalyticsShoppableScrolledFirstTime = Analytics
extension AnalyticsShoppableScrolledFirstTime {
    
  static func trackShoppableScrolledFirstTime(shoppable:Shoppable?,  rating:String?,  screenshot:String?,  category:String?,  augmentedOffersUrl:String? ) {
      let key = "Shoppable scrolled first time"
      var properties:[String:Any] = [:]
      if let shoppable = shoppable {
          propertiesFor(shoppable).forEach { properties[$0] = $1 }
      }
>>>>>>> analytics2
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
<<<<<<< HEAD
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
  }
}

 

typealias AnalyticsSkippedTutorial = Analytics
extension AnalyticsSkippedTutorial {
    
  func trackSkippedTutorial() {
      let key = "Skipped Tutorial"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
  }
}

 

typealias AnalyticsStartedDownloadingClarifaiModel = Analytics
extension AnalyticsStartedDownloadingClarifaiModel {
    
  func trackStartedDownloadingClarifaiModel() {
      let key = "started downloading Clarifai model"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
  }
}

 

typealias AnalyticsStartedTutorial = Analytics
extension AnalyticsStartedTutorial {
    
  func trackStartedTutorial() {
      let key = "Started Tutorial"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
  }
}

 

typealias AnalyticsStartedTutorialVideo = Analytics
extension AnalyticsStartedTutorialVideo {
    
  func trackStartedTutorialVideo() {
      let key = "Started Tutorial Video"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
=======
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

<<<<<<< HEAD
typealias AnalyticsSubmittedBlankEmail = Analytics
extension AnalyticsSubmittedBlankEmail {
    
  func trackSubmittedBlankEmail() {
      let key = "Submitted blank email"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
  }
}

 

typealias AnalyticsSubmittedEmail = Analytics
extension AnalyticsSubmittedEmail {
    
  func trackSubmittedEmail() {
      let key = "Submitted email"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
  }
}

 

typealias AnalyticsTabBarTapped = Analytics
extension AnalyticsTabBarTapped {
    
  func trackTabBarTapped() {
      let key = "Tab Bar tapped"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
=======
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

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

<<<<<<< HEAD
typealias AnalyticsTappedOnShoppable = Analytics
extension AnalyticsTappedOnShoppable {
    
  func trackTappedOnShoppable() {
      let key = "Tapped on shoppable"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
  }
}

 

typealias AnalyticsTookScreenshot = Analytics
extension AnalyticsTookScreenshot {
    
  func trackTookScreenshot() {
      let key = "Took Screenshot"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
  }
}

 

typealias AnalyticsTookScreenshotWhileShowingIntercomWindow = Analytics
extension AnalyticsTookScreenshotWhileShowingIntercomWindow {
    
  func trackTookScreenshotWhileShowingIntercomWindow() {
      let key = "Took Screenshot While Showing Intercom Window"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
  }
}

 

typealias AnalyticsUserAge = Analytics
extension AnalyticsUserAge {
    
  func trackUserAge() {
      let key = "User Age"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
=======
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

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

<<<<<<< HEAD
typealias AnalyticsUserExitedTutorialVideo = Analytics
extension AnalyticsUserExitedTutorialVideo {
    
  func trackUserExitedTutorialVideo(progressInSeconds:String? ) {
      let key = "User Exited Tutorial Video"
      var properties:[String:Any] = [:]
      if let progressInSeconds = progressInSeconds {
          properties["progressInSeconds"] = progressInSeconds
      }
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
  }
}

 

typealias AnalyticsUserProperties = Analytics
extension AnalyticsUserProperties {
    
  func trackUserProperties() {
      let key = "User Properties"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
  }
}

 

typealias AnalyticsUserReceivedSharedScreenshots = Analytics
extension AnalyticsUserReceivedSharedScreenshots {
    
  func trackUserReceivedSharedScreenshots() {
      let key = "user received shared screenshots"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
  }
}

 

typealias AnalyticsUserRetriedScreenshots = Analytics
extension AnalyticsUserRetriedScreenshots {
    
  func trackUserRetriedScreenshots() {
      let key = "user retried screenshots"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
=======
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

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

typealias AnalyticsWebViewInvalidUrl = Analytics
extension AnalyticsWebViewInvalidUrl {
    
<<<<<<< HEAD
  func trackWebViewInvalidUrl(url:String? ) {
=======
  static func trackWebViewInvalidUrl(url:String? ) {
>>>>>>> analytics2
      let key = "WebView invalid url"
      var properties:[String:Any] = [:]
      if let url = url {
          properties["url"] = url
      }
<<<<<<< HEAD
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
=======
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 

typealias AnalyticsWokeFromSilentPush = Analytics
extension AnalyticsWokeFromSilentPush {
    
<<<<<<< HEAD
  func trackWokeFromSilentPush() {
      let key = "Woke From Silent Push"
      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.intercom.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
      AnalyticsTrackers.branch.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key)
=======
  static func trackWokeFromSilentPush() {
      let key = "Woke From Silent Push"
      var properties:[String:Any] = [:]
            



      AnalyticsTrackers.appsee.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.segment.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)
      AnalyticsTrackers.kochava.trackUsingStringEventhoughtYouReallyKnowYouShouldBeUsingAnAnalyticEvent(key, properties: properties)

      //edit properties after sent them to supress complier warning if unused
      properties["_______"] = ""
  
>>>>>>> analytics2
  }
}

 