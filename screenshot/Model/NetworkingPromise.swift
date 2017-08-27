//
//  NetworkingPromise.swift
//  screenshot
//
//  Created by Gershon Kagan on 8/14/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit
import PromiseKit

class NetworkingPromise: NSObject {
    
    static func uploadToSyte(imageData: Data?) -> Promise<(String, [[String : Any]])> {
        return Promise { fulfill, reject in
            guard let imageData = imageData else {
                let emptyError = NSError(domain: "Craze", code: 3, userInfo: [NSLocalizedDescriptionKey : "Empty image passed to Syte"])
                reject(emptyError)
                return
            }
            NetworkingModel.upload(toSyte: imageData, completionHandler: { (response: URLResponse, responseObject: Any?, error: Error?) in
                guard error == nil,
                    let responseObjectDict = responseObject as? [String : Any],
                    let uploadedURLString = responseObjectDict.keys.first,
                    let segments = responseObjectDict[uploadedURLString] as? [[String : Any]],
                    segments.count > 0 else {
                        let emptyError = NSError(domain: "Craze", code: 4, userInfo: [NSLocalizedDescriptionKey : "Syte returned no segments"])
                        reject(emptyError)
                        return
                }
                fulfill(uploadedURLString, segments)
            })
        }
    }
    
    static func jsonStringify(object: Any) -> String? {
        if let objectData = try? JSONSerialization.data(withJSONObject: object, options: JSONSerialization.WritingOptions(rawValue: 0)) {
            let objectString = String(data: objectData, encoding: .utf8)
            return objectString
        }
        return nil
    }
    
    static func downloadInfo(url: URL) -> Promise<[String : Any]> {
        return Promise { fulfill, reject in
            let request = URLRequest(url: url)
            let session = URLSession.shared
            let dataTask = session.dataTask(with: request) { data, response, error in
                if let data = data,
                    let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] {
                    fulfill(json)
                } else if let error = error {
                    reject(error)
                } else {
                    let error = NSError(domain: "Craze", code: 4,
                                        userInfo: [NSLocalizedDescriptionKey: "downloadInfo unknown error"])
                    reject(error)
                }
            }    
            dataTask.resume()
        }
    }

}
