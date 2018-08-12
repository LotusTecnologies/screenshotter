//
//  UniversalSearchController.swift
//  Screenshop
//
//  Created by Corey Werner on 7/30/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class UniversalSearchController: NSObject {
    static let shared = UniversalSearchController()
    
    fileprivate var inboxBarButtonItems: [BadgeBarButtonItem] = []
    var inboxUnreadCountFRC = DataModel.sharedInstance.inboxMessageNewFrc(delegate: nil)
    
    override init() {
        super.init()
        
        SearchCategoryModel.shared.fetchCategories()
        inboxUnreadCountFRC.delegate = self
    }
    
    // MARK: Inbox
    
    @objc func updateInboxBadgeCount() {
        if InboxMessage.inboxEnabled() {
            let count = self.inboxUnreadCountFRC.fetchedObjects.filter{ $0.showAfterDate ?? Date.init(timeIntervalSince1970: 0) < Date() }.count
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
    
    // MARK: Search
    
    private var searchNavigationController: SearchNavigationController?
    
    private func presentSearchViewController() {
        let searchNavigationController = SearchNavigationController()
        
        searchNavigationController.searchViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "SearchX"), style: .plain, target: self, action: #selector(dismissSearchViewController))
        
        self.searchNavigationController = searchNavigationController
        
        UIApplication.shared.keyWindow?.rootViewController?.present(searchNavigationController, animated: false, completion: { [weak searchNavigationController] in
            searchNavigationController?.searchViewController.presentSearchController()
        })
    }
    
    @objc private func dismissSearchViewController() {
        if let searchNavigationController = searchNavigationController {
            searchNavigationController.presentingViewController?.dismiss(animated: false)
        }
        
        searchNavigationController = nil
    }
}

extension UniversalSearchController: UISearchBarDelegate {
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        if searchNavigationController == nil {
            presentSearchViewController()
        }
        return false
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
        
        let searchBar = SearchBar()
        searchBar.delegate = UniversalSearchController.shared
        searchBar.placeholder = "search.placeholder".localized
        searchBar.searchBarStyle = .minimal
        navigationItem.titleView = searchBar
    }
    
    @objc func presentNotificationInbox() {
        UniversalSearchController.shared.presentNotificationInbox(from: self)
    }
}
