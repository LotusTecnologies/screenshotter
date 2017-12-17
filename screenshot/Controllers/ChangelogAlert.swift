//
//  ChangelogAlert.swift
//  screenshot
//
//  Created by Jacob Relkin on 12/14/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit
import PromiseKit

struct ChangelogAlert {
    static var lastVersion: String? {
        get {
             return UserDefaults.standard.string(forKey: UserDefaultsKeys.previousAppVersion)
        }
        set {
             UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.previousAppVersion)
        }
    }
    
    private static let currentVersion = Bundle.displayVersion
    
    static func presentIfNeeded(inViewController viewController: UIViewController) {
        guard let last = lastVersion else {
            lastVersion = currentVersion
            return
        }
        
        if last.compare(currentVersion, options: .numeric) == .orderedAscending {
            lastVersion = currentVersion

            // Last version was less than this one. Present alert
            let localeIdentifier = Locale.current.identifier
            let version = currentVersion
            
            // If the request for the changelog of this locale fails, send another request for the default changelog in en_US
            NetworkingPromise.changelog(forAppVersion: version, localeIdentifier: localeIdentifier)
            .recover { (error) -> Promise<ChangelogResponse> in
                return NetworkingPromise.changelog(forAppVersion: version, localeIdentifier: "en_US")
            }
            .catch { error in
                print(error)
            }
            .then(on: .main) { response in
                let controller = UIAlertController(title: response.title, message: response.body, preferredStyle: .alert)
                controller.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                viewController.present(controller, animated: true, completion: nil)
                
                return AnyPromise(Promise<Void>())
            }
        }
    }
}

