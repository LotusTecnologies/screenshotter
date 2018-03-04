//
//  ChangelogAlert.swift
//  screenshot
//
//  Created by Jacob Relkin on 12/14/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit
import PromiseKit



public class ChangelogAlertController  {
    static func presentIfNeeded(inViewController viewController: UIViewController) {
        let appSettings = AppDelegate.shared.appSettings
        
        if appSettings.isCurrentVersion(greaterThan: appSettings.previousVersion) {
            // Last version was less than this one. Present alert
            let currentVersion = Bundle.displayVersion
            let localeIdentifier = Locale.current.identifier
            
            // If the request for the changelog of this locale fails, send another request for the default changelog in en_US
            NetworkingPromise.sharedInstance.changelog(forAppVersion: currentVersion, localeIdentifier: localeIdentifier)
            .recover { (error) -> Promise<ChangelogResponse> in
                return NetworkingPromise.sharedInstance.changelog(forAppVersion: currentVersion, localeIdentifier: "en_US")
            }
            .catch { error in
                print(error)
            }
            .then(on: .main) { response in
                let title = response.title ?? "changelog.title".localized
                let controller = UIAlertController(title: title, message: response.body, preferredStyle: .alert)
                controller.addAction(UIAlertAction(title: "generic.ok".localized, style: .default, handler: nil))
                viewController.present(controller, animated: true, completion: nil)
                
                return AnyPromise(Promise<Void>())
            }
        }
    }
}
