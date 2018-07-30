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

class UniversalSearchController {
    static let shared = UniversalSearchController()
    
    fileprivate var inboxBarButtonItems: [BadgeBarButtonItem] = []
    
    init() {
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
