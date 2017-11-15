//
//  UpdatePrompt.swift
//  screenshot
//
//  Created by Jacob Relkin on 9/18/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation
import PromiseKit

struct UpdatePromptState {
    let suggestedVersion: String?
    let forceVersion: String?
    
    enum JSONKeys : String {
        case Suggested = "SuggestedUpdateVersion"
        case Force = "ForceUpdateVersion"
    }
    
    init(dictionaryRepresentation representation: [AnyHashable : Any]) {
        suggestedVersion = representation[JSONKeys.Suggested.rawValue] as? String
        forceVersion = representation[JSONKeys.Force.rawValue] as? String
    }
}

class UpdatePromptHandler : NSObject {
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
    
    // MARK: Public methods
    
    func start() {
        startUpdateFlow()
    }
    
    // MARK: Fetching update payload
    
    private func startUpdateFlow() {
        fetchSettingsPayload() { updateState in
//            #if DEV
//                // Dont update on dev
//            #else
                self.presentAppropriatePromptIfNecessary(withUpdateState: updateState)
//            #endif
        }
    }
    
    private func fetchSettingsPayload(withCompletion completion: ((UpdatePromptState) -> Void)? = nil) {
        let _ = NetworkingPromise.appSettings().then(on: DispatchQueue.global(qos: .default)) { dictionary -> Promise<UpdatePromptState> in
            self.processDiscoverURLs(dictionary)
            
            return Promise(value: UpdatePromptState(dictionaryRepresentation: dictionary))
            
        }.then(on: .main) { updateState in
            completion?(updateState)
        }
    }
    
    // MARK: Discover URL handling
    
    private func processDiscoverURLs(_ dictionary: [String : Any]) {
        guard let discoverURLs = dictionary["DiscoverURLs"] as? [String] else {
            return
        }
        
        // TODO: move this code out of this class
        
        let randomIndex = Int(arc4random_uniform(UInt32(discoverURLs.count)))
        let randomURL = discoverURLs[randomIndex]
        UserDefaults.standard.set(randomURL, forKey: UserDefaultsKeys.discoverUrl)
    }
    
    // MARK: Alert presentation
    
    private func presentAppropriatePromptIfNecessary(withUpdateState state: UpdatePromptState) {
        let forcedVersionIsGreater = state.forceVersion?.compare(currentAppVersion, options: .numeric) == .orderedDescending
        let suggestedVersionIsGreater = state.suggestedVersion?.compare(currentAppVersion, options: .numeric) == .orderedDescending
        
        // !!!: DEBUG
        if forcedVersionIsGreater || true {
            presentForceUpdateAlert()
            
        } else if suggestedVersionIsGreater {
            // Ignore if we've already asked to update to this version.
            if let lastVersionAskedToUpdate = UserDefaults.standard.object(forKey: UserDefaultsKeys.versionLastAskedToUpdate) as? String,
                lastVersionAskedToUpdate == state.suggestedVersion
            {
                return
            }
            
            presentUpdateAlert()
            UserDefaults.standard.set(state.suggestedVersion, forKey: UserDefaultsKeys.versionLastAskedToUpdate)
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
                    self.rootViewController?.dismiss(animated: true, completion: self.startUpdateFlow)
                }
                
            } else {
                self.startUpdateFlow()
            }
        }
    }

    private func navigateToAppStore(action: UIAlertAction) {
        if UIApplication.shared.canOpenURL(appStoreURL) {
            UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
        }
    }
}
