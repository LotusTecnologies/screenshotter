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
            AnalyticsManager.track("sent image to Syte")
            NetworkingModel.upload(toSyte: imageData, completionHandler: { (response: URLResponse, responseObject: Any?, error: Error?) in
                guard error == nil,
                    let responseObjectDict = responseObject as? [String : Any],
                    let uploadedURLString = responseObjectDict.keys.first,
                    let segments = responseObjectDict[uploadedURLString] as? [[String : Any]],
                    segments.count > 0 else {
                        let emptyError = NSError(domain: "Craze", code: 4, userInfo: [NSLocalizedDescriptionKey : "Syte returned no segments"])
                        print("Syte no segments. responseObject:\(String(describing: responseObject))")
                        reject(emptyError)
                        return
                }
                fulfill(uploadedURLString, segments)
            })
        }
    }
    
    static func jsonStringify(object: Any) -> String? {
        if let objectData = try? JSONSerialization.data(withJSONObject: object, options: []) {
            let objectString = String(data: objectData, encoding: .utf8)
            return objectString
        }
        return nil
    }
    
    static func jsonDestringify(string: String) -> [[String : Any]]? {
        guard let data = string.data(using: .utf8),
            let segments = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [[String: Any]] else {
                return nil
        }
        return segments
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
                    let error = NSError(domain: "Craze", code: 5, userInfo: [NSLocalizedDescriptionKey: "downloadInfo unknown error"])
                    reject(error)
                }
            }
            dataTask.resume()
        }
    }
    
    static func downloadImage(url: URL, screenshotDict: [String : Any]) -> Promise<(Data, [String : Any])> {
        return Promise { fulfill, reject in
            let request = URLRequest(url: url)
            let session = URLSession.shared
            let dataTask = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    reject(error)
                } else if let data = data {
                    fulfill(data, screenshotDict)
                } else {
                    let error = NSError(domain: "Craze", code: 6, userInfo: [NSLocalizedDescriptionKey: "downloadImage unknown error"])
                    reject(error)
                }
            }
            dataTask.resume()
        }
    }
    
    static func share(userName: String?, imageURLString: String?, syteJson: String?) -> Promise<(String, String)> {
        return Promise { fulfill, reject in
            guard let url = URL(string: Constants.screenShotLambdaDomain + "screenshot") else {
                let error = NSError(domain: "Craze", code: 11, userInfo: [NSLocalizedDescriptionKey: "Cannot create url from screenShotLambdaDomain:\(Constants.screenShotLambdaDomain)"])
                print(error)
                reject(error)
                return
            }
            let parameterDict = ["userName" : userName, "image" : imageURLString, "syteJson" : syteJson]
            guard let parameterData = try? JSONSerialization.data(withJSONObject: parameterDict, options: []) else {
                let error = NSError(domain: "Craze", code: 12, userInfo: [NSLocalizedDescriptionKey: "Cannot JSONSerialize userName:\(userName ?? "-")  image:\(imageURLString ?? "-")  syteJson:\(syteJson ?? "-")"])
                print(error)
                reject(error)
                return
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = parameterData
            let session = URLSession.shared
            let dataTask = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    reject(error)
                } else if let data = data,
                  let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any],
                  let id = json["id"] as? String,
                  let shareLink = json["shareLink"] as? String {
                    fulfill((id, shareLink))
                } else {
                    let error = NSError(domain: "Craze", code: 13, userInfo: [NSLocalizedDescriptionKey: "share unknown error"])
                    reject(error)
                }
            }
            dataTask.resume()
        }
    }
}
