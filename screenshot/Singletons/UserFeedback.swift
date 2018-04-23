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
    var screenshotFrcManager:FetchedResultsControllerManager<Screenshot>?
    var timer:Timer?
    init() {

        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: .UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: .UIApplicationDidBecomeActive, object: nil)
    }
    
    func applicationDidFinishLaunching() {
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    @objc func applicationDidBecomeActive(_ notification:Notification){
        scheduleNotifications()
    }
    
    func postNotifcation(){
        if let viewController = AppDelegate.shared.window?.rootViewController {
            let announcement = Announcement(title: "\(String.randomName()) from \(String.randomCity())", subtitle: "Added a screenshot you shared", image: UIImage(named: "ShareToMatchsticksThumbsUp"), duration:10.0, action:{
                //notification was tapped
            })
            Whisper.show(shout: announcement, to: viewController, completion: {
                print("The shout was silent.")
            })
        }
    }
    @objc func applicationDidEnterBackground(_ notification:Notification){
        cancelNotifications()
    }
    
    func scheduleNotifications(){
        self.timer?.invalidate()
        self.timer = nil
        
        DataModel.sharedInstance.performBackgroundTask { (context) in
            let request: NSFetchRequest<Screenshot> = Screenshot.fetchRequest()
            request.predicate = NSPredicate(format: "isHidden == FALSE AND isRecognized == TRUE && submittedDate != nil")
            let now = Date()
            if let results = try? context.fetch(request) {
                var eventsPerHour:Int = 0
                results.forEach({ (s) in
                    if s.submittedFeedbackCountGoal > s.submittedFeedbackCount {
                        if s.submittedFeedbackCountGoalDate == nil {
                            s.submittedFeedbackCountGoalDate = now
                        }
                        if s.submittedFeedbackCountDate == nil {
                            s.submittedFeedbackCountDate = Date.init(timeIntervalSince1970: 0)
                        }
                       
                        if let submittedFeedbackCountDate = s.submittedFeedbackCountDate, let d2 = s.submittedFeedbackCountGoalDate {
                            //if submittedFeedbackCountDate is very old. change it to be equidistant to submittedFeedbackCountGoalDate
                            let d1 = submittedFeedbackCountDate.laterDate(Date.init(timeIntervalSinceNow: -1 * d2.timeIntervalSinceNow))
                            let c2 = max(s.submittedFeedbackCountGoal, s.submittedFeedbackCount)
                            let c1 = s.submittedFeedbackCount
                            
                            s.submittedFeedbackCountDate = now
                            let timePeriod = (d2.timeIntervalSince1970 - d1.timeIntervalSince1970)
                            let percentToShow:Double = {
                                if timePeriod > 0 { // goal has to be in future
                                    return min(1.0, max(0.0, (now.timeIntervalSince1970 - d1.timeIntervalSince1970) / timePeriod))
                                }else{
                                    return 1.0
                                }
                            }()
                            let diff = (c2 - c1)
                            let amountToAdd = Int64( round(Double(diff) * percentToShow))
                            let amountToShowOverTime = diff - amountToAdd
                            s.submittedFeedbackCount = c1 + amountToAdd
                            s.submittedFeedbackCountDate = now
                            if amountToShowOverTime > 0 {
                                let toShowTimePeriod = d2.timeIntervalSinceReferenceDate - now.timeIntervalSinceReferenceDate
                                if toShowTimePeriod > 0 {
                                    eventsPerHour += Int(ceil(  (Double(amountToShowOverTime)*60*60)/toShowTimePeriod   ))
                                }
                            }
                        }
                    }else{
                        s.submittedFeedbackCountDate = now
                    }
                })
                
                if eventsPerHour > 0 {
                    DispatchQueue.main.async {
                        let showAtleast = 60.0*5.0 /// 5 minutes
                        let showAtMost = 30.0 // 30 seconds
                        let timerPeriod = min(showAtleast, max(showAtMost, 60*60/TimeInterval(eventsPerHour)))
                        print("timer period for fake notification \(timerPeriod)");
                        self.timer = Timer.scheduledTimer(timeInterval:timerPeriod, target: self, selector: #selector(self.timerTriggered), userInfo: nil, repeats: true)
                        if timerPeriod > 20 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: {
                                self.timerTriggered()
                            })

                        }
                    }
                }
            }
            
            context.saveIfNeeded()
        }
    }
    
    func cancelNotifications(){
        self.screenshotFrcManager = nil
        self.timer?.invalidate()
        self.timer = nil
        
    }
    
    @objc func timerTriggered(){
        if self.screenshotFrcManager == nil {
            self.screenshotFrcManager = DataModel.sharedInstance.screenshotFrc(delegate: nil)
        }
        
        if let frc = self.screenshotFrcManager{
            
            if let objectId = frc.fetchedObjects.shuffled().first(where: {
                $0.submittedDate != nil &&  $0.submittedFeedbackCountGoal > $0.submittedFeedbackCount
            })?.objectID {
                DataModel.sharedInstance.performBackgroundTask { (context) in
                    if let screenshot = context.screenshotWith(objectId: objectId) {
                        if screenshot.submittedDate != nil &&  screenshot.submittedFeedbackCountGoal > screenshot.submittedFeedbackCount {
                            screenshot.submittedFeedbackCount += 1
                            context.saveIfNeeded()
                            DispatchQueue.main.async {
                                self.postNotifcation()
                            }
                        }
                    }
                }
            }else{
                //none left to notify about.  change timer to be 5 minutes
                self.timer?.invalidate()
                self.timer = Timer.scheduledTimer(timeInterval:5*60.0, target: self, selector: #selector(self.timerTriggered), userInfo: nil, repeats: true)

            }
        }
    }
}



