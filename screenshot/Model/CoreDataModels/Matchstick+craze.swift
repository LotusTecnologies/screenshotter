//
//  Matchstick+craze.swift
//  screenshot
//
//  Created by Jonathan Rose on 6/3/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import Foundation
import CoreData

extension Matchstick {
    static func predicateForDisplayingMatchstick() -> NSPredicate {
        return NSPredicate.init(format: "isDisplaying == true")
    }
    static func predicateForQueuedMatchstick(gender:String, category:String?) -> NSPredicate {
        let basic = NSPredicate.init(format: "dateSkipped = nil AND was404 != true AND wasAdded != true AND isDisplaying != true")
        var genderPredicate = NSPredicate.init(value: true)
        if gender == "female" {
            genderPredicate = NSPredicate.init(format: "isFemale == true")
        }else if gender == "male" {
            genderPredicate = NSPredicate.init(format: "isMale == true")
        }
        var categoryPredicate = NSPredicate.init(value: true)
        
        if let category = category, !category.isEmpty{
            categoryPredicate = NSPredicate.init(format: "tags CONTAINS %@", "[\(category)]")
        }
    
        
        return NSCompoundPredicate.init(andPredicateWithSubpredicates: [basic, genderPredicate, categoryPredicate])
    }

    static var skipRotationTime = TimeInterval.oneWeek
    static var displayingSize = 2
    
    //Must have at least this amount in "Queue" ready to display on UI.
    public class var minQueueSize:Int {
        return UserDefaults.standard.integer(forKey: UserDefaultsKeys.discoverMinQueueSize)
    }
    
    var isInGarbage:Bool {
        if self.wasAdded || self.was404 {
            return true
        }else if let date = self.dateSkipped {
            if abs(date.timeIntervalSinceNow) < Matchstick.skipRotationTime {
                return true                
            }
        }
        return false
    }
  
    public func add(callback: ((_ screenshot: Screenshot) -> Void)? = nil) {
        DiscoverManager.shared.didAdd(self, callback:callback)
    }
    
    public func pass() {
        DiscoverManager.shared.didSkip(self)
    }
    public func delayedAdd(){
        DiscoverManager.shared.didDelayedAdd(self)
    }
    
    static func lookupWith(remoteIds:[String], in context:NSManagedObjectContext) -> [String:Matchstick]{
        let fetchRequest: NSFetchRequest<Matchstick> = Matchstick.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "remoteId IN %@", remoteIds)
        fetchRequest.sortDescriptors = nil
        var matchstickLookup:[String:Matchstick] = [:]
        if let results = try? context.fetch(fetchRequest) {
            results.forEach { if let remoteId = $0.remoteId { matchstickLookup[remoteId] = $0  } }
        }
        return matchstickLookup
    }
    
    static func with( imageUrl:String, in context:NSManagedObjectContext) -> Matchstick?{
        let fetchRequest: NSFetchRequest<Matchstick> = Matchstick.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "imageUrl == %@", imageUrl)
        fetchRequest.sortDescriptors = nil
        if let results = try? context.fetch(fetchRequest), let matchstick = results.first {
            return matchstick
        }
        return nil
    }
    
    // NOTE: This will get called every time the app enters the forground
    public class func refreshMinQueueSize() {
        return
        //TODO: Input actual URL below and remove above return line to allow function to run
        let url = URL(string: "https://blank")!
        let request = URLRequest(url: url)
        HTTPHelper.asyncRequest(request) { (data, error) in
            //TODO: process data to extract the minQueueSize config var and then set it below
            UserDefaults.standard.set(5, forKey: UserDefaultsKeys.discoverMinQueueSize)
        }
    }
}
