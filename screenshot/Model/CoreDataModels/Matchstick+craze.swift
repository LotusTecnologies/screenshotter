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
    static func predicateForQueuedMatchstick() -> NSPredicate {
        return NSPredicate.init(format: "dateSkipped = nil AND was404 != true AND wasAdded != true AND isDisplaying != true")
    }

    static var skipRotationTime:TimeInterval = 7*24*60*60  // 1 week
    static var displayingSize = 2
    static var queueSize = 30  //Must have at least this ammount  - if not grab random numbers
    static var recombeeQueueSize = 20  // want to have this amount of recombee recommendations
    static var recombeeQueueLowMark = 10 // if less than this amount make request for recombee recomendations (recombeeQueueSize - current)

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
