//
//  DataModel+FRC.swift
//  screenshot
//
//  Created by Jonathan Rose on 6/3/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import Foundation
import CoreData


extension DataModel {
    func screenshotFrc(delegate:FetchedResultsControllerManagerDelegate?) -> FetchedResultsControllerManager<Screenshot>  {
        let request: NSFetchRequest<Screenshot> = Screenshot.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "lastModified", ascending: false), NSSortDescriptor(key: "createdAt", ascending: false)]
        request.predicate = NSPredicate(format: "isHidden == FALSE AND isRecognized == TRUE AND sourceString != %@", ScreenshotSource.shuffle.rawValue)
        let context = self.mainMoc()
        let fetchedResultsController = FetchedResultsControllerManager<Screenshot>.init(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, delegate: delegate)
        return fetchedResultsController
    }
    
    func screenshotBySourceFrc(sourse:ScreenshotSource, delegate:FetchedResultsControllerManagerDelegate?) -> FetchedResultsControllerManager<Screenshot>  {
        let request: NSFetchRequest<Screenshot> = Screenshot.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "lastModified", ascending: false), NSSortDescriptor(key: "createdAt", ascending: false)]
        let notHidden = NSPredicate(format: "isHidden == FALSE AND isRecognized == TRUE")
        let fromSource:NSPredicate = {
            if sourse == .unknown {
                return NSPredicate.init(format: "sourseString == nil || sourceString == %@", sourse.rawValue)
            }else {
                return NSPredicate.init(format: "sourceString == %@", sourse.rawValue)
            }
        }()
        request.predicate = NSCompoundPredicate.init(andPredicateWithSubpredicates: [notHidden, fromSource])
        let context = self.mainMoc()
        let fetchedResultsController = FetchedResultsControllerManager<Screenshot>.init(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, delegate: delegate)
        return fetchedResultsController
    }
    
    func singleScreenshotFrc(delegate:FetchedResultsControllerManagerDelegate?, screenshot:Screenshot) -> FetchedResultsControllerManager<Screenshot>  {
        let request: NSFetchRequest<Screenshot> = Screenshot.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "lastModified", ascending: false)]
        request.predicate = NSPredicate(format: "SELF == %@", screenshot.objectID)
        let context = self.mainMoc()
        let fetchedResultsController = FetchedResultsControllerManager<Screenshot>.init(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, delegate: delegate)
        return fetchedResultsController
    }
    
    func shoppableFrc(delegate:FetchedResultsControllerManagerDelegate?, screenshot:Screenshot) -> FetchedResultsControllerManager<Shoppable> {
        let request: NSFetchRequest<Shoppable> = Shoppable.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true), NSSortDescriptor(key: "b0x", ascending: true), NSSortDescriptor(key: "b0y", ascending: true), NSSortDescriptor(key: "b1x", ascending: true), NSSortDescriptor(key: "b1y", ascending: true), NSSortDescriptor(key: "offersURL", ascending: true)]
        request.predicate = NSPredicate(format: "screenshot == %@", screenshot)
        let context = self.mainMoc()
        let fetchedResultsController = FetchedResultsControllerManager<Shoppable>.init(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, delegate: delegate)
        return fetchedResultsController
    }
    
    func favoriteFrc(delegate:FetchedResultsControllerManagerDelegate?) -> FetchedResultsControllerManager<Screenshot> {
        let request: NSFetchRequest = Screenshot.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "lastFavorited", ascending: false)]
        request.predicate = NSPredicate(format: "favoritesCount != 0")
        let context = self.mainMoc()
        let fetchedResultsController:FetchedResultsControllerManager<Screenshot> = FetchedResultsControllerManager<Screenshot>.init(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, delegate: delegate)
        return fetchedResultsController
    }
    
    func favoritedProductsFrc(delegate:FetchedResultsControllerManagerDelegate?) -> FetchedResultsControllerManager<Product> {
        let request: NSFetchRequest = Product.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "dateFavorited", ascending: false)]
        request.predicate = NSPredicate(format: "isFavorite == true")
        let context = self.mainMoc()
        let fetchedResultsController:FetchedResultsControllerManager<Product> = FetchedResultsControllerManager<Product>.init(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, delegate: delegate)
        return fetchedResultsController
    }
    
    func productFrc(delegate:FetchedResultsControllerManagerDelegate?, shoppableOID: NSManagedObjectID) -> FetchedResultsControllerManager<Product> {
        let request: NSFetchRequest = Product.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "order", ascending: false)]
        request.predicate = NSPredicate(format: "shoppable == %@", shoppableOID)
        
        let context = self.mainMoc()
        let fetchedResultsController:FetchedResultsControllerManager<Product> = FetchedResultsControllerManager<Product>.init(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, delegate: delegate)
        return fetchedResultsController
    }
    
    func productFrc(delegate:FetchedResultsControllerManagerDelegate?, productObjectID: NSManagedObjectID) -> FetchedResultsControllerManager<Product> {
        let request: NSFetchRequest = Product.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "dateFavorited", ascending: false)]
        request.predicate = NSPredicate(format: "SELF == %@", productObjectID)
        
        let context = self.mainMoc()
        let fetchedResultsController:FetchedResultsControllerManager<Product> = FetchedResultsControllerManager<Product>.init(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, delegate: delegate)
        return fetchedResultsController
    }
    
    
    func productBarFrc(delegate:FetchedResultsControllerManagerDelegate?) -> FetchedResultsControllerManager<Product> {
        let request: NSFetchRequest = Product.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "dateSortProductBar", ascending: false)]
        let date = NSDate.init(timeIntervalSinceNow:  -TimeInterval.oneWeek)
        request.predicate = NSCompoundPredicate.init(andPredicateWithSubpredicates: [NSPredicate(format: "hideFromProductBar != true"), NSCompoundPredicate.init(orPredicateWithSubpredicates: [ NSPredicate(format: "isFavorite == true"), NSPredicate(format: "dateViewed != nil")]), NSPredicate(format:"dateSortProductBar > %@", date)])
        
        let context = self.mainMoc()
        let fetchedResultsController:FetchedResultsControllerManager<Product> = FetchedResultsControllerManager<Product>.init(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, delegate: delegate)
        return fetchedResultsController
    }
    
    func matchstickFrc(delegate:FetchedResultsControllerManagerDelegate?) -> FetchedResultsControllerManager<Matchstick> {
        let request: NSFetchRequest = Matchstick.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "receivedAt", ascending: true)]
        request.predicate = Matchstick.predicateForDisplayingMatchstick()
        let context = self.mainMoc()
        let fetchedResultsController:FetchedResultsControllerManager<Matchstick> = FetchedResultsControllerManager<Matchstick>.init(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, delegate:delegate)
        
        return fetchedResultsController
    }
    
    func inboxMessageNewFrc(delegate:FetchedResultsControllerManagerDelegate?) -> FetchedResultsControllerManager<InboxMessage>{
        
        let request: NSFetchRequest<InboxMessage> = InboxMessage.fetchRequest()
        request.predicate = NSPredicate.init(format: "isNew == true AND isExpired == false")
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        let context = self.mainMoc()
        let fetchedResultsController = FetchedResultsControllerManager<InboxMessage>(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, delegate: delegate)
        return fetchedResultsController
    }
    
    func inboxMessageFrc(delegate:FetchedResultsControllerManagerDelegate?) -> FetchedResultsControllerManager<InboxMessage>{
        
        let request: NSFetchRequest<InboxMessage> = InboxMessage.fetchRequest()
        request.predicate = nil
        request.sortDescriptors = [NSSortDescriptor(key:"isExpired", ascending:true), NSSortDescriptor(key: "date", ascending: false)]
        let context = self.mainMoc()
        let fetchedResultsController = FetchedResultsControllerManager<InboxMessage>(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: #keyPath(InboxMessage.sectionHeader), delegate: delegate)
        return fetchedResultsController
    }
    
}
