//
//  UpdatePrompt.swift
//  screenshot
//
//  Created by Jacob Relkin on 9/18/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

class UpdatePromptHandler : NSObject {
    var appSettings: AppSettings?
    var _appSettings: _AppSettings? {
        // TODO: can be removed once files converted to swift
        didSet {
            if let settings = _appSettings {
                appSettings = AppSettings(settings)
                
            } else {
                appSettings = nil
            }
        }
    }
    
    private let currentAppVersion = UIApplication.version()
    private let appDisplayName = UIApplication.displayName()
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
        guard !UIApplication.isDev(), let appSettings = appSettings else {
            return
        }
        
        let forcedVersionIsGreater = appSettings.forceVersion?.compare(currentAppVersion, options: .numeric) == .orderedDescending
        let suggestedVersionIsGreater = appSettings.suggestedVersion?.compare(currentAppVersion, options: .numeric) == .orderedDescending
        
        if forcedVersionIsGreater {
            presentForceUpdateAlert()
            
        } else if suggestedVersionIsGreater {
            // Ignore if we've already asked to update to this version.
            if let lastVersionAskedToUpdate = UserDefaults.standard.object(forKey: UserDefaultsKeys.versionLastAskedToUpdate) as? String,
                lastVersionAskedToUpdate == appSettings.suggestedVersion
            {
                return
            }
            
            presentUpdateAlert()
            UserDefaults.standard.set(appSettings.suggestedVersion, forKey: UserDefaultsKeys.versionLastAskedToUpdate)
        }
    }

    private func presentUpdateAlert() {
        let controller = UIAlertController(title: "New Version Available", message: "Update now for the best \(String(describing: appDisplayName)) experience!", preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "Later", style: .cancel, handler: nil))
        
        let updateAction = UIAlertAction(title: "Update", style: .default, handler: navigateToAppStore)
        controller.addAction(updateAction)
        controller.preferredAction = updateAction
        
        rootViewController?.present(controller, animated: true, completion: nil)
    }
    
    private func presentForceUpdateAlert() {
        let controller = UIAlertController(title: "Update Required", message: "You need to update to the latest version to keep using \(appDisplayName).", preferredStyle: .alert)
        
        let updateAction = UIAlertAction(title: "Update", style: .default, handler: navigateToAppStore)
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
