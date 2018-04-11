//
//  UserFeedbackView.swift
//  screenshot
//
//  Created by Jonathan Rose on 4/11/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import CoreData
import Whisper

class UserFeedback  {
    
    public static let shared = UserFeedback()

    
    init() {

        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: .UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: .UIApplicationDidBecomeActive, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    @objc func applicationDidBecomeActive(_ notification:Notification){
        scheduleNotifications()
        
    }
    func postNotifcation(){
        if let viewController = AppDelegate.shared.window?.rootViewController {
            let announcement = Announcement(title: "\(String.randomName()) from \(String.randomCity())", subtitle: "Liked a screenshot you shared", image: UIImage(named: "ShareToMatchsticksThumbsUp"))
            Whisper.show(shout: announcement, to: viewController, completion: {
                print("The shout was silent.")
            })
        }
    }
    @objc func applicationDidEnterBackground(_ notification:Notification){
        cancelNotifications()
    }
    
    func scheduleNotifications(){
        
    }
    
    func cancelNotifications(){
        
    }
    
    func makeNotificationForScreenShotLiked(screenshotObjectId:NSManagedObjectID){
        DataModel.sharedInstance.performBackgroundTask { (context) in
            if let screenshot = context.screenshotWith(objectId: screenshotObjectId) {
                context.saveIfNeeded()
                DispatchQueue.main.async {
                    self.postNotifcation()
                   
                }
            }
            
           
        }
    }

}



