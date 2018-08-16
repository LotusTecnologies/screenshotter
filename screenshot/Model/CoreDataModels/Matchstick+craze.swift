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
    static func predicateForQueuedMatchstick(gender:ProductsOptionsGender, category:String?) -> NSPredicate {
        let basic = NSPredicate.init(format: "dateSkipped = nil AND was404 != true AND wasAdded != true AND isDisplaying != true")
        var genderPredicate = NSPredicate.init(value: true)
        if gender == .female {
            genderPredicate = NSPredicate.init(format: "isFemale == true")
        }else if gender == .male {
            genderPredicate = NSPredicate.init(format: "isMale == true")
        }
        var categoryPredicate = NSPredicate.init(value: true)
        
        if let category = category {
            categoryPredicate = NSPredicate.init(format: "tags CONTAINS %@", "[\(category)]")
        }
    
        
        return NSCompoundPredicate.init(andPredicateWithSubpredicates: [basic, genderPredicate, categoryPredicate])
    }

    static var skipRotationTime = TimeInterval.oneWeek
    static var displayingSize = 2
    static var queueSize = 10  //Must have at least this ammount  - if not grab random numbers
    static var recombeeQueueSize = 30  // want to have this amount of recombee recommendations
    static var recombeeQueueLowMark = 20 // if less than this amount make request for recombee recomendations (recombeeQueueSize - current)

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
}
