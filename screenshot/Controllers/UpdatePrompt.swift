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
    private var currentAppVersion: String {
        return Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
    }
    
    private var appStoreURL: URL {
        return URL(string: "itms-apps://itunes.apple.com/app/id1254964391")!
    }
    
    private var containerViewController: UIViewController
    private var didBecomeActiveObserver: Any?
    
    init(containerViewController controller: UIViewController) {
        containerViewController = controller
        super.init()
    }
    
    // MARK: Public methods
    
    deinit {
        guard let observer = didBecomeActiveObserver else {
            return
        }
        
        NotificationCenter.default.removeObserver(observer)
    }
    
    func start() {
        print("Starting update handler")

        startUpdateFlow()
    }
    
    // MARK: Fetching update payload
    
    private func startUpdateFlow() {
        fetchSettingsPayload() { state in
//            #if DEV
//                print("Not running update flow because we are in development")
//            #else
                self.presentAppropriatePromptIfNecessary(withUpdateState: state)
//            #endif
        }
    }
    
    private func fetchSettingsPayload(withCompletion completion: ((UpdatePromptState) -> Void)? = nil) {
        let _ = NetworkingPromise.appSettings().then(on: DispatchQueue.global(qos: .default)) { dictionary -> Promise<UpdatePromptState> in
            print("Received settings payload from server")
            
            self.processDiscoverURLs(dictionary)
            
            return Promise(value: UpdatePromptState(dictionaryRepresentation: dictionary))
        }.then(on: .main) { state in
            completion?(state)
        }
    }
    
    // MARK: Discover URL handling
    
    private func processDiscoverURLs(_ dictionary: [String : Any]) {
        let currentlyRecordedUrl = UserDefaults.standard.string(forKey: UserDefaultsKeys.discoverUrl)
        
        if let discoverURLHash = dictionary["DiscoverURL"] as? [String : String] {
            var needsToUpdatePersistedURL = true
            if let recordedURL = currentlyRecordedUrl {
                needsToUpdatePersistedURL = !discoverURLHash.values.contains(recordedURL)
            }
            
            if (needsToUpdatePersistedURL) {
                // Figure out which key in the hash to use based on the A-B test parameters
                
                let integerKeys = discoverURLHash.keys.flatMap { Int($0) }
                let total = integerKeys.reduce(0, +)
                let randomKey = arc4random_uniform(UInt32(total - 1)) + 1
                
                var resultKey = ""
                var runningSum = 0
                
                for key in integerKeys {
                    runningSum += key
                    
                    if randomKey <= runningSum {
                        resultKey = "\(key)"
                        break
                    }
                }
                
                if let discoverURL = discoverURLHash[resultKey], discoverURL.count > 0 {
                    UserDefaults.standard.set(discoverURL, forKey: UserDefaultsKeys.discoverUrl)
                }
            }
        }
    }
    
    // MARK: Alert presentation
    
    private func presentAppropriatePromptIfNecessary(withUpdateState state: UpdatePromptState) {
        print("Determining appropriate prompt action (if any)...")
        
        let forcedVersionIsGreater = state.forceVersion?.compare(currentAppVersion, options: .numeric) == .orderedDescending
        let suggestedVersionIsGreater = state.suggestedVersion?.compare(currentAppVersion, options: .numeric) == .orderedDescending
 
        if forcedVersionIsGreater {
            print("forced version is greater")
            
            // Force update.
            presentForceUpdateAlert()
        } else if suggestedVersionIsGreater {
            print("suggested version is greater")
            
            // Suggested update.
            
            // Ignore if we've already asked to update to this version.
            if let lastVersionAskedToUpdate = UserDefaults.standard.object(forKey: UserDefaultsKeys.versionLastAskedToUpdate) as? String,
                lastVersionAskedToUpdate == state.suggestedVersion {
                return
            }
            
            presentUpdateAlert()
            UserDefaults.standard.set(state.suggestedVersion, forKey: UserDefaultsKeys.versionLastAskedToUpdate)
        } else {
            print("No prompt action deemed necessary")
        }
    }

    private func presentUpdateAlert() {
        let controller = UIAlertController(title: "New Version Available", message: "Update now for the best Craze experience!", preferredStyle: .alert)
        let updateAction = UIAlertAction(title: "Update", style: .default, handler: navigateToAppStore)
        
        controller.addAction(UIAlertAction(title: "Later", style: .cancel, handler: nil))
        controller.addAction(updateAction)
        controller.preferredAction = updateAction
        
        containerViewController.present(controller, animated: true, completion: nil)
    }
    
    private func presentForceUpdateAlert() {
        containerViewController.view.isUserInteractionEnabled = false
        
        // Restart the flow if users try to re-enter the app.
        didBecomeActiveObserver = didBecomeActiveObserver ?? NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidBecomeActive, object: nil, queue: nil) { note in
            self.containerViewController.dismiss(animated: false, completion: nil)
            self.startUpdateFlow()
        }
        
        let controller = UIAlertController(title: "Update Required", message: "You need to update to the latest version to keep using Craze.", preferredStyle: .alert)
        let updateAction = UIAlertAction(title: "Update", style: .cancel, handler: navigateToAppStore)
        controller.addAction(updateAction)
        controller.preferredAction = updateAction
        
        containerViewController.present(controller, animated: true) { [weak containerViewController] in
            containerViewController?.view.isUserInteractionEnabled = true
        }
    }

    private func navigateToAppStore(action: UIAlertAction) {
        guard UIApplication.shared.canOpenURL(appStoreURL) else {
            return
        }
        
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(appStoreURL)
        }
    }
}
