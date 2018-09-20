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
    enum ActionType : String {
        case link
        case screenshot
        case product
        case similarLooks
        case campaign
    }
    static func deletePendingMessage(in context:NSManagedObjectContext) {
        let fetchRequest:NSFetchRequest<InboxMessage> = InboxMessage.fetchRequest()
        fetchRequest.predicate = NSPredicate.init(format: "showAfterDate > %@", NSDate())
        do{
            let result = try context.fetch(fetchRequest)
            result.forEach { context.delete($0) }
            
        }catch{
            DataModel.sharedInstance.receivedCoreDataError(error: error)
        }
    }
    
    static func inboxEnabled() ->Bool {
        return PermissionsManager.shared.permissionStatus(for: .push) == .authorized &&
            UserDefaults.standard.bool(forKey: UserDefaultsKeys.gdpr_agreedToEmail)
    }
    
    static func insertMessageFromPush(userInfo: [AnyHashable : Any] ){
        if let dataDict = userInfo["data"] as? [AnyHashable: Any],  let dict = dataDict["inbox"] as? [String:Any] {
            DataModel.sharedInstance.performBackgroundTask { (context) in
                InboxMessage.createUpdateWith(lookupDict: nil, dictionary: dict, create: true, update: false, context: context)
                context.saveIfNeeded()
            }
        }
    }
    
    static func markMessageAsReadFromPush(userInfo: [AnyHashable : Any] ){
        //This is need to deal with both remote and local notification which have differnt structor the userInfo
        var uuid:String? = nil
        if let dataDict = userInfo["data"] as? [AnyHashable: Any],  let dict = dataDict["inbox"] as? [String:Any] {
            uuid = dict["uuid"] as? String
        }
        if let dict = userInfo["inbox"] as? [String:Any] {
            uuid = dict["uuid"] as? String
        }
        if let uuid = uuid {
            DataModel.sharedInstance.performBackgroundTask { (context) in
                let lookup = InboxMessage.lookupWith(uuids: [uuid], in: context)
                if let message = lookup[uuid] {
                    message.isNew = false
                }

                context.saveIfNeeded()
            }
        }
    }
    
    
    static func createUpdateWith(lookupDict:[String:InboxMessage]?, actionType:String, actionValue:String, buttonText:String, image:String, title:String, uuid:String, expireDate:Date, date:Date, showAfterDate:Date, tracking:[String:String]?, create:Bool, update:Bool, context:NSManagedObjectContext){
        let lookup = lookupDict ?? InboxMessage.lookupWith(uuids: [uuid], in: context)
        let foundMessage = lookup[uuid]
        if foundMessage != nil && update == false {
            return
        }
        if foundMessage == nil && create == false {
            return
        }
        
        let message = lookup[uuid] ?? InboxMessage(context: context)
        
        if message.uuid != uuid {
            message.uuid = uuid
        }
        if message.actionType != actionType {
            message.actionType = actionType
        }
        if message.actionValue != actionValue {
            message.actionValue = actionValue
        }
        if message.buttonText != buttonText {
            message.buttonText = buttonText
        }
        if message.image != image {
            message.image = image
        }
        if message.title != title {
            message.title = title
        }
        if message.title != title {
            message.title = title
        }
        if message.date != date {
            message.date = date
        }
        if message.expireDate != expireDate {
            message.expireDate = expireDate
        }
        if message.showAfterDate != showAfterDate {
            message.showAfterDate = showAfterDate
        }
        
        if let tracking = tracking {
            if JSONSerialization.isValidJSONObject(tracking), let jsonData = try? JSONSerialization.data(withJSONObject: tracking, options: []), let jsonString = String.init(data:jsonData, encoding:.utf8) {
                if message.trackingJSON != jsonString {
                    message.trackingJSON = jsonString
                }
            }
        }else {
            if message.trackingJSON != nil {
                message.trackingJSON = nil
            }
        }
        message.isExpired = expireDate.timeIntervalSinceNow < 0
        if expireDate.timeIntervalSinceNow < -TimeInterval.oneWeek {
            context.delete(message)
        }
        if let installDate = UserDefaults.standard.object(forKey: UserDefaultsKeys.dateInstalled) as? Date {
            if date < installDate {
                if message.isNew != false {
                    message.isNew = false
                }
            }
        }
    }
    
    static func createUpdateWith(lookupDict:[String:InboxMessage]?, dictionary:[String:Any], create:Bool, update:Bool, context:NSManagedObjectContext){
        
        if  let actionType = dictionary["actionType"] as? String,
            let actionValue = dictionary["actionValue"] as? String,
            let buttonText = dictionary["buttonText"] as? String,
            let image = dictionary["image"] as? String,
            let title = dictionary["title"] as? String,
            let uuid = dictionary["uuid"] as? String,
            let expireNumber = dictionary["expireDate"] as? NSNumber,
            let dateNumber = dictionary["date"] as? NSNumber
        {
            
            let expireDate = Date.init(timeIntervalSince1970: TimeInterval(expireNumber.intValue))
            let date = Date.init(timeIntervalSince1970: TimeInterval(dateNumber.intValue))
             let tracking = dictionary["tracking"] as? [String:String]
            
            createUpdateWith(lookupDict: lookupDict,
                             actionType: actionType,
                             actionValue: actionValue,
                             buttonText: buttonText,
                             image: image,
                             title: title,
                             uuid: uuid,
                             expireDate: expireDate,
                             date: date,
                             showAfterDate: Date.init(timeIntervalSince1970: 0),
                             tracking: tracking,
                             create: create,
                             update: update,
                             context: context)
        }
    }
    
    static func lookupWith(uuids:[String], in context:NSManagedObjectContext) -> [String:InboxMessage]{
        let fetchRequest: NSFetchRequest<InboxMessage> = InboxMessage.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "uuid IN %@", uuids)
        fetchRequest.sortDescriptors = nil
        var lookup:[String:InboxMessage] = [:]
        if let results = try? context.fetch(fetchRequest) {
            results.forEach { if let uuid = $0.uuid { lookup[uuid] = $0  } }
        }
        return lookup
    }
    
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
                    if let expire = m.expireDate {
                        let isExpired = expire.timeIntervalSinceNow < 0
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
