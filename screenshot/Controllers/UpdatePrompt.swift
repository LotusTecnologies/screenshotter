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
    let suggestedVersion: String
    let forceVersion: String
    
    enum JSONKeys : String {
        case Suggested = "SuggestedUpdateVersion"
        case Force = "ForceUpdateVersion"
    }
    
    var dictionaryRepresentation: [String : String] {
        return [JSONKeys.Suggested.rawValue: suggestedVersion, JSONKeys.Force.rawValue: forceVersion]
    }
    
    init(dictionaryRepresentation representation: [String : String]) throws {
        guard let suggested = representation[JSONKeys.Suggested.rawValue], let force = representation[JSONKeys.Force.rawValue] else {
            // TODO: Use a better error value here.
            throw NSError(domain: "io.crazeapp.screenshot.validation-error", code: 3, userInfo: representation)
        }
        
        suggestedVersion = suggested
        forceVersion = force
    }
}

class UpdatePromptHandler {
    private var currentAppVersion: String {
        return Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
    }
    
    private var appStoreURL: URL {
        return URL(string: "itms-apps://itunes.apple.com/app/id1254964391")!
    }
    
    var containerViewController: UIViewController?
    
    // MARK: Public methods
    
    func start() {
        startUpdateFlow()
    }
    
    // MARK: Fetching update payload
    
    private func startUpdateFlow() {
        fetchUpdatePayload() { state in
            self.presentAppropriatePromptIfNecessary(withUpdateState: state)
        }
    }
    
    private func fetchUpdatePayload(withCompletion completion: ((UpdatePromptState) -> Void)? = nil) {
        let _ = NetworkingPromise.appVersionRequirements().then(on: DispatchQueue.global(qos: .default)) { dictionary -> Promise<UpdatePromptState> in
            guard let updateState = try? UpdatePromptState(dictionaryRepresentation: dictionary) else {
                throw NSError(domain: Bundle.main.infoDictionary!["CFBundleIdentifier"] as! String, code: 100, userInfo: [NSLocalizedDescriptionKey: "Can't create an UpdatePromptState from the given dictionary: \(dictionary.description)"])
            }
            
            return Promise(value: updateState)
            }.then(on: .main) { state in
                completion?(state)
                
                // TODO: Is this correct?
                return AnyPromise(Promise())
        }
    }
    
    // MARK: Alert presentation
    
    private func presentAppropriatePromptIfNecessary(withUpdateState state: UpdatePromptState) {
        let forcedVersionIsGreater = state.forceVersion.compare(currentAppVersion, options: .numeric) == .orderedDescending
        let suggestedVersionIsGreater = state.suggestedVersion.compare(currentAppVersion, options: .numeric) == .orderedDescending
 
        if forcedVersionIsGreater {
            // Force update.
            presentForceUpdateAlert()
        } else if suggestedVersionIsGreater {
            // Suggested update.
            
            // Ignore if we've already asked to update to this version.
            if let lastVersionAskedToUpdate = UserDefaults.standard.object(forKey: UserDefaultsKeys.versionLastAskedToUpdate) as? String, lastVersionAskedToUpdate == state.suggestedVersion {
                return
            }
            
            presentUpdateAlert()
            UserDefaults.standard.set(state.suggestedVersion, forKey: UserDefaultsKeys.versionLastAskedToUpdate)
        }
    }

    private func presentUpdateAlert() {
        let controller = UIAlertController(title: "New Version Available", message: "Update now for the best Craze experience!", preferredStyle: .alert)
        let updateAction = UIAlertAction(title: "Update", style: .default, handler: navigateToAppStore)
        
        controller.addAction(UIAlertAction(title: "Later", style: .cancel, handler: nil))
        controller.addAction(updateAction)
        controller.preferredAction = updateAction
        
        containerViewController?.present(controller, animated: true, completion: nil)
    }
    
    private func presentForceUpdateAlert() {
        containerViewController?.view.isUserInteractionEnabled = false
        
        // Restart the flow if users try to re-enter the app.
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidBecomeActive, object: nil, queue: nil) { note in
            self.containerViewController?.dismiss(animated: false, completion: nil)
            self.startUpdateFlow()
        }
        
        let controller = UIAlertController(title: "Update Required", message: "You need to update to the latest version to keep using Craze.", preferredStyle: .alert)
        let updateAction = UIAlertAction(title: "Update", style: .cancel, handler: navigateToAppStore)
        controller.addAction(updateAction)
        controller.preferredAction = updateAction
        
        containerViewController?.present(controller, animated: true, completion: nil)
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
