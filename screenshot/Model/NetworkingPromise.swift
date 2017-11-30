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
            track("sent image to Syte")
            NetworkingModel.upload(toSyte: imageData, completionHandler: { (response: URLResponse, responseObject: Any?, error: Error?) in
                guard error == nil,
                    let responseObjectDict = responseObject as? [String : Any],
                    let uploadedURLString = responseObjectDict.keys.first,
                    let segments = responseObjectDict[uploadedURLString] as? [[String : Any]],
                    segments.count > 0 else {
                        var emptyError: NSError
                        if let responseObjectDict = responseObject as? [String : Any],
                          let uploadedURLString = responseObjectDict.keys.first {
                            emptyError = NSError(domain: "Craze", code: 4, userInfo: [NSLocalizedDescriptionKey : "Syte returned no segments", Constants.uploadedURLStringKey : uploadedURLString])
                        } else {
                            emptyError = NSError(domain: "Craze", code: 4, userInfo: [NSLocalizedDescriptionKey : "Syte returned no segments"])
                        }
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
    
    // Promises to return an AWS Subscription ARN identifying this device's subscription to our AWS cloud
    static func createAndSubscribeToSilentPushEndpoint(pushToken token: String, tzOffset: String, subscriptionARN arn: String? = nil) -> Promise<String> {
        guard let url = URL(string: Constants.screenShotLambdaDomain + "push-subscribe") else {
            let error = NSError(domain: "Craze", code: 9, userInfo: [NSLocalizedDescriptionKey: "Cannot create url from screenShotLambdaDomain:\(Constants.screenShotLambdaDomain)"])
            return Promise(error: error)
        }
        
        var parameters = [ "token": token, "timezone": tzOffset ]

        if let arn = arn {
            parameters["arnToUnsubscribe"] = arn
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(parameters)
        } catch {
            return Promise(error: error)
        }
        
        let promise:URLDataPromise = URLSession.shared.dataTask(with: request)
        return promise.asDataAndResponse().then { data, response -> Promise<String> in
            var dictionary:[String: String]!
            do {
                dictionary = try JSONDecoder().decode([String: String].self, from: data)
            } catch {
                return Promise(error: error)
            }
            
            guard let subscriptionARN = dictionary["subscriptionArn"] else {
                return Promise(error: NSError(domain: "Craze", code: 0, userInfo: [NSLocalizedDescriptionKey : "No subscription ARN in the response payload!"]))
            }
            
            return Promise(value: subscriptionARN)
        }
    }
    
    static func share(userName: String?, imageURLString: String?, syteJson: String?) -> Promise<(String, String)> {
        guard let url = URL(string: Constants.screenShotLambdaDomain + "screenshots?createShare=true") else {
            let error = NSError(domain: "Craze", code: 9, userInfo: [NSLocalizedDescriptionKey: "Cannot create url from screenShotLambdaDomain:\(Constants.screenShotLambdaDomain)"])
            print(error)
            return Promise(error: error)
        }
        let parameterDict = ["screenshot" : ["userName" : userName, "image" : imageURLString, "syteJson" : syteJson]]
        guard let parameterData = try? JSONSerialization.data(withJSONObject: parameterDict, options: []) else {
            let error = NSError(domain: "Craze", code: 10, userInfo: [NSLocalizedDescriptionKey: "Cannot JSONSerialize userName:\(userName ?? "-")  image:\(imageURLString ?? "-")  syteJson:\(syteJson ?? "-")"])
            print(error)
            return Promise(error: error)
        }
        return NetworkingPromise.shareWorkhorse(parameterData: parameterData, url: url)
    }
    
    static func reshare(userName: String?, shareId: String?) -> Promise<(String, String)> {
        guard let encoded = shareId?.addingPercentEncoding(withAllowedCharacters: .alphanumerics),
          let url = URL(string: Constants.screenShotLambdaDomain + "shares?reshare=" + encoded) else {
            let error = NSError(domain: "Craze", code: 9, userInfo: [NSLocalizedDescriptionKey: "Cannot create url from screenShotLambdaDomain:\(Constants.screenShotLambdaDomain)"])
            print(error)
            return Promise(error: error)
        }
        guard let userNameUnwrapped = userName,
          let parameterData = try? JSONSerialization.data(withJSONObject: ["share" : ["userName" : userNameUnwrapped]], options: []) else {
            let error = NSError(domain: "Craze", code: 10, userInfo: [NSLocalizedDescriptionKey: "Cannot JSONSerialize userName:\(userName ?? "-")"])
            print(error)
            return Promise(error: error)
        }
        return NetworkingPromise.shareWorkhorse(parameterData: parameterData, url: url)
    }
    
    static func shareWorkhorse(parameterData: Data, url: URL) -> Promise<(String, String)> {
        return Promise { fulfill, reject in
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = parameterData
            request.setValue("\(parameterData.count)", forHTTPHeaderField: "Content-Length")
            request.setValue("application/json", forHTTPHeaderField:"Content-Type")

            let session = URLSession.shared
            let dataTask = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    reject(error)
                } else if let data = data,
                  let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any],
                  let share = json["share"] as? [String : Any],
                  let shareId = share["id"] as? String,
                  let shareLink = share["link"] as? String {
                    fulfill((shareId, shareLink))
                } else {
                    let error = NSError(domain: "Craze", code: 13, userInfo: [NSLocalizedDescriptionKey: "share unknown error"])
                    reject(error)
                }
            }
            dataTask.resume()
        }
    }
    
    static func appSettings() -> Promise<[String : Any]> {
        return Promise { fulfill, reject in
            guard let URL = URL(string: Constants.appSettingsDomain) else {
                return
            }
            
            let task = URLSession.shared.dataTask(with: URL) { (dataOpt, responseOpt, errorOpt) in
                guard let data = dataOpt else {
                    // TODO: Deal with error.
                    return
                }
                
                do {
                    guard let JSON = try JSONSerialization.jsonObject(with: data) as? [String : Any] else {
                        // TODO: Deal with mismatched type?
                        return
                    }
                    
                    fulfill(JSON)
                } catch {
                    reject(error)
                }
            }
            
            task.resume()
        }
    }
}
