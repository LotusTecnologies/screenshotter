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
        guard let URL = URL(string: urlString) else {
            return Promise(error: NSError(domain: "Craze", code: 0, userInfo: [NSLocalizedDescriptionKey : "Unable to construct changelog URL"]))
        }
        
        let request = URLRequest(url: URL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
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
                let title = response.title ?? "changelog.alert.title.default".localized
                let controller = UIAlertController(title: title, message: response.body, preferredStyle: .alert)
                controller.addAction(UIAlertAction(title: "generic.ok".localized, style: .default, handler: nil))
                viewController.present(controller, animated: true, completion: nil)
                
                return AnyPromise(Promise<Void>())
            }
        }
    }
}

