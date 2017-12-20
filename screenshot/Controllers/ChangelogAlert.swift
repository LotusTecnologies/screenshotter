//
//  ChangelogAlert.swift
//  screenshot
//
//  Created by Jacob Relkin on 12/14/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit
import PromiseKit

fileprivate struct ChangelogResponse : Decodable {
    enum CodingKeys : String, CodingKey {
        case title = "title"
        case body = "body"
    }
    
    var title: String? = nil
    let body: String
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            title = try container.decode(String.self, forKey: .title)
        } catch {}
        
        body = try container.decode(String.self, forKey: .body)
    }
}

fileprivate extension NetworkingPromise {
    static func changelog(forAppVersion appVersion: String, localeIdentifier: String) -> Promise<ChangelogResponse> {
        let urlString = [Constants.whatsNewDomain, appVersion, "\(localeIdentifier).json"].joined(separator: "/")
        guard let url = URL(string: urlString) else {
            return Promise(error: NSError(domain: "Craze", code: 0, userInfo: [NSLocalizedDescriptionKey : "Unable to construct changelog URL"]))
        }
        
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        let promise:URLDataPromise = URLSession.shared.dataTask(with: request)
        return promise.asDataAndResponse().then { data, response -> Promise<ChangelogResponse> in
            guard let response = response as? HTTPURLResponse, response.statusCode >= 200 && response.statusCode < 300 else {
                return Promise(error: NSError(domain: "Craze", code: 0, userInfo: [NSLocalizedDescriptionKey : "Invalid status code received from AWS lambda"]))
            }
            
            return Promise(value: try JSONDecoder().decode(ChangelogResponse.self, from: data))
        }
    }
}

public class ChangelogAlertController : NSObject {
    static func presentIfNeeded(inViewController viewController: UIViewController) {
        let appSettings = AppDelegate.shared.settings
        
        if appSettings.isCurrentVersion(greaterThan: appSettings.previousVersion) {
            // Last version was less than this one. Present alert
            let currentVersion = Bundle.displayVersion
            let localeIdentifier = Locale.current.identifier
            
            // If the request for the changelog of this locale fails, send another request for the default changelog in en_US
            NetworkingPromise.changelog(forAppVersion: currentVersion, localeIdentifier: localeIdentifier)
            .recover { (error) -> Promise<ChangelogResponse> in
                return NetworkingPromise.changelog(forAppVersion: currentVersion, localeIdentifier: "en_US")
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