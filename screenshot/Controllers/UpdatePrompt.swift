//
//  UpdatePrompt.swift
//  screenshot
//
//  Created by Jacob Relkin on 9/18/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation
import UIKit

class UpdatePromptHandler  {
    private let appStoreURL = URL(string: "itms-apps://itunes.apple.com/app/id1254964391")!
    
    private var rootViewController: UIViewController? {
        return UIApplication.shared.keyWindow?.rootViewController
    }
    
    private var applicationWillEnterForegroundObserver: Any?
    
    // MARK: Life Cycle
    
    deinit {
        if let observer = applicationWillEnterForegroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: Alert presentation
    
    func presentUpdatePromptIfNeeded() {
        guard !UIApplication.isDev else {
            return
        }
        
        let appSettings = AppDelegate.shared.appSettings
        
        if appSettings.shouldForceUpdate {
            presentForceUpdateAlert()
            
        } else if appSettings.shouldUpdate {
            // Ignore if we've already asked to update to this version.
            if let lastVersionAskedToUpdate = UserDefaults.standard.string(forKey: UserDefaultsKeys.versionLastAskedToUpdate),
                lastVersionAskedToUpdate == appSettings.updateVersion
            {
                return
            }
            
            presentUpdateAlert()
            UserDefaults.standard.set(appSettings.updateVersion, forKey: UserDefaultsKeys.versionLastAskedToUpdate)
        }
    }

    private func presentUpdateAlert() {
        let controller = UIAlertController(title: "update.request.title".localized, message: "update.request.message", preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "generic.later".localized, style: .cancel, handler: nil))
        
        let updateAction = UIAlertAction(title: "generic.update".localized, style: .default, handler: navigateToAppStore)
        controller.addAction(updateAction)
        controller.preferredAction = updateAction
        
        rootViewController?.present(controller, animated: true, completion: nil)
    }
    
    private func presentForceUpdateAlert() {
        let controller = UIAlertController(title: "update.force.title".localized, message: "update.force.message", preferredStyle: .alert)
        
        let updateAction = UIAlertAction(title: "generic.update".localized, style: .default, handler: navigateToAppStore)
        controller.addAction(updateAction)
        controller.preferredAction = updateAction
        
        rootViewController?.present(controller, animated: true, completion: nil)
        
        guard applicationWillEnterForegroundObserver == nil else {
            return
        }
        
        applicationWillEnterForegroundObserver = NotificationCenter.default.addObserver(forName: .UIApplicationWillEnterForeground, object: nil, queue: nil) { notification in
            if let presentedViewController = self.rootViewController?.presentedViewController {
                if !presentedViewController.isKind(of: UIAlertController.self) {
                    self.rootViewController?.dismiss(animated: true, completion: self.presentUpdatePromptIfNeeded)
                }
                
            } else {
                self.presentUpdatePromptIfNeeded()
            }
        }
    }

    private func navigateToAppStore(action: UIAlertAction) {
        if UIApplication.shared.canOpenURL(appStoreURL) {
            UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
        }
    }
}
