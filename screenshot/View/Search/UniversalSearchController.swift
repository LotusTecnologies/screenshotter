//
//  UniversalSearchController.swift
//  Screenshop
//
//  Created by Corey Werner on 7/30/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import PushwooshInboxUI
import Pushwoosh

class UniversalSearchController: NSObject {
    static let shared = UniversalSearchController()
    
    fileprivate var inboxBarButtonItems: [BadgeBarButtonItem] = []
    
    override init() {
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(pushWooshDidReceiveInPush(_:)), name: .PWInboxMessagesDidReceiveInPush, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Inbox
    
    @objc private func pushWooshDidReceiveInPush(_ notification: Notification) {
        updateInboxBadgeCount()
    }
    
    func updateInboxBadgeCount() {
        PWInbox.unreadMessagesCount(completion: { [weak self] (count, error) in
            DispatchQueue.mainAsyncIfNeeded {
                if error == nil {
                    self?.inboxBarButtonItems.forEach({ item in
                        item.count = UInt(count)
                    })
                }
            }
        })
    }
    
    func presentNotificationInbox(from viewController: UIViewController) {
        guard let inboxStyle = PWIInboxStyle.default() else {
            return
        }
        
        inboxStyle.backgroundColor = .background
        inboxStyle.defaultTextColor = .gray3
        inboxStyle.selectionColor = .gray9
        inboxStyle.accentColor = .crazeGreen
        inboxStyle.dateColor = .gray6
        inboxStyle.separatorColor = .cellBorder
        
        if let inboxViewController = PWIInboxUI.createInboxController(with: inboxStyle) {
            let navigationController = ModalNavigationController(rootViewController: inboxViewController)
            viewController.present(navigationController, animated: true)
        }
    }
    
    // MARK: Search
    
    private var searchNavigationController: SearchNavigationController?
    
    private func presentSearchViewController() {
        let searchNavigationController = SearchNavigationController()
        searchNavigationController.searchViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissSearchViewController))
        self.searchNavigationController = searchNavigationController
        
        UIApplication.shared.keyWindow?.rootViewController?.present(searchNavigationController, animated: false, completion: { [weak searchNavigationController] in
//            searchNavigationController?.searchViewController.searchBar.becomeFirstResponder()
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

extension UIViewController {
    func applyNavigationItemSearchAndInbox() {
        let inboxBarButtonItem = BadgeBarButtonItem(image: UIImage(named: "NavigationBarEmail"), style: .plain, target: self, action: #selector(presentNotificationInbox))
        
        navigationItem.leftBarButtonItem = inboxBarButtonItem
        UniversalSearchController.shared.inboxBarButtonItems.append(inboxBarButtonItem)
        
        let searchBar = UISearchBar()
        searchBar.delegate = UniversalSearchController.shared
        searchBar.placeholder = "search.placeholder".localized
        searchBar.searchBarStyle = .minimal
        navigationItem.titleView = searchBar
    }
    
    @objc func presentNotificationInbox() {
        UniversalSearchController.shared.presentNotificationInbox(from: self)
    }
}
