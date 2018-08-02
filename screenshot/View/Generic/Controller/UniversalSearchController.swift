//
//  UniversalSearchController.swift
//  Screenshop
//
//  Created by Corey Werner on 7/30/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class UniversalSearchController {
    static let shared = UniversalSearchController()
    
    fileprivate var inboxBarButtonItems: [BadgeBarButtonItem] = []
    var inboxUnreadCountFRC = DataModel.sharedInstance.inboxMessageNewFrc(delegate: nil)

    init() {
        inboxUnreadCountFRC.delegate = self
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Inbox
    
    
    @objc func updateInboxBadgeCount() {
        if InboxMessage.inboxEnabled() {
            let count = self.inboxUnreadCountFRC.fetchedObjectsCount
            self.inboxBarButtonItems.forEach { $0.count = UInt(count) }
        }else{
            self.inboxBarButtonItems.forEach { $0.count = 0 }
        }
    }
    
    func presentNotificationInbox(from viewController: UIViewController) {
        let vc = MessageInboxViewController.init()
        InboxMessage.updateExpired()
        let navVC = UINavigationController.init(rootViewController: vc)
        viewController.present(navVC, animated: true)
        let inboxFRC = DataModel.sharedInstance.inboxMessageFrc(delegate: nil)
        Analytics.trackInboxOpened(tab: viewController.title ?? "", unread: self.inboxUnreadCountFRC.fetchedObjectsCount, total: inboxFRC.fetchedObjectsCount)
    }
}


extension UniversalSearchController : FetchedResultsControllerManagerDelegate {
    func managerDidChangeContent(_ controller: NSObject, change: FetchedResultsControllerManagerChange) {
        updateInboxBadgeCount()
    }
}
extension UIViewController {
    func applyNavigationItemSearchAndInbox() {
        let inboxBarButtonItem = BadgeBarButtonItem(image: UIImage(named: "NavigationBarEmail"), style: .plain, target: self, action: #selector(presentNotificationInbox))
        
        navigationItem.leftBarButtonItem = inboxBarButtonItem
        UniversalSearchController.shared.inboxBarButtonItems.append(inboxBarButtonItem)
    }
    
    @objc func presentNotificationInbox() {
        UniversalSearchController.shared.presentNotificationInbox(from: self)
    }
}
