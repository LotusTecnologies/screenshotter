//
//  InboxMessage+craze.swift
//  Screenshop
//
//  Created by Jonathan Rose on 7/25/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import CoreData

extension InboxMessage {
    static func markAllAsRead(){
        DataModel.sharedInstance.performBackgroundTask { (context) in
            let request: NSFetchRequest<InboxMessage> = InboxMessage.fetchRequest()
            request.predicate = nil
            if let result = try? context.fetch(request) {
                result.forEach({ (m) in
                    if m.isNew {
                        m.isNew = false
                    }
                })
            }
            context.saveIfNeeded()
        }
    }
    
    static func fetchUnreadCount() -> Int{
        if !Thread.isMainThread {
            return 0
        }
        let request: NSFetchRequest<InboxMessage> = InboxMessage.fetchRequest()
        request.predicate = NSPredicate.init(format: "isNew == true")
        let count = try? DataModel.sharedInstance.mainMoc().count(for: request)
        return count ?? 0
        
    }
    func markAsRead(){
        let objId = self.objectID
        DataModel.sharedInstance.performBackgroundTask { (context) in
            if let message = context.inboxMessageWith(objectId: objId) {
                if message.isNew == true {
                    message.isNew = false
                }
            }
            context.saveIfNeeded()
        }
    }
    
    static func updateExpired(completion:(() -> Void)? = nil ){
        DataModel.sharedInstance.performBackgroundTask { (context) in
            let request: NSFetchRequest<InboxMessage> = InboxMessage.fetchRequest()
            request.predicate = nil
            if let result = try? context.fetch(request) {
                result.forEach({ (m) in
                    if let date = m.date, let expire = m.expireDate {
                        let isExpired = date < expire
                        if m.isExpired != isExpired {
                            m.isExpired = isExpired
                        }
                        
                        if expire.timeIntervalSinceNow < -TimeInterval.oneWeek {
                            context.delete(m)
                        }
                        
                    }
                })
            }
            context.saveIfNeeded()
            if let completion = completion {
                DispatchQueue.mainAsyncIfNeeded {
                    completion()
                }
            }
        }
    }
    @objc var sectionHeader:String {
        get {
            if self.isExpired {
                return "inbox.section.expired".localized
            }else if let date = self.date {
                let oneDay = TimeInterval.oneDay
                let mostRecentMidnight = GlobalDateTools.shared.mostRecentMidnight
                let mostRecentJan1 = GlobalDateTools.shared.mostRecentJan1
                
                if date > mostRecentMidnight {
                    return "inbox.section.today".localized
                }else if date > mostRecentMidnight.addingTimeInterval(-1 * oneDay) {
                    return "inbox.section.yesterday".localized
                }else if date > mostRecentMidnight.addingTimeInterval(-2 * oneDay) {
                    return "inbox.section.daysAgo".localized(withFormat: "2")
                }else if date > mostRecentMidnight.addingTimeInterval(-3 * oneDay) {
                    return "inbox.section.daysAgo".localized(withFormat: "3")
                }else if date > mostRecentMidnight.addingTimeInterval(-4 * oneDay) {
                    return "inbox.section.daysAgo".localized(withFormat: "4")
                }else if date > mostRecentMidnight.addingTimeInterval(-5 * oneDay) {
                    return "inbox.section.daysAgo".localized(withFormat: "5")
                }else if date > mostRecentMidnight.addingTimeInterval(-6 * oneDay) {
                    return "inbox.section.daysAgo".localized(withFormat: "6")
                }else if date > mostRecentJan1 {
                    let formatter = GlobalDateTools.shared.shortDateFormatter
                    return formatter.string(from: date)
                }else{
                    let formatter = GlobalDateTools.shared.longDateFormatter
                    return formatter.string(from: date)
                }
            }else{
                 // error?
                return ""
            }
        }
    }
}
