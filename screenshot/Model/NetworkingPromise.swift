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
    
    static func uploadToSyteWorkhorse(imageData: Data?, imageClassification: ClarifaiModel.ImageClassification) -> Promise<NSDictionary> {
        guard let imageData = imageData,
            imageClassification != .unrecognized else {
                let emptyError = NSError(domain: "Craze", code: 3, userInfo: [NSLocalizedDescriptionKey : "Empty image passed to Syte"])
                return Promise(error: emptyError)
        }
        let urlString = imageClassification == .human
            ? "https://syteapi.com/offers/bb?account_id=6677&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU=&feed=shoppable_nordstrom&payload_type=image_bin"
            : "https://homedecor.syteapi.com/offers/bb?account_id=6722&sig=G51b+lgvD2TO4l1AjvnVI1OxokzFK5FLw5lHBksXP1c=&feed=craze_home&payload_type=image_bin"
        guard let url = URL(string: urlString) else {
            let malformedError = NSError(domain: "Craze", code: 3, userInfo: [NSLocalizedDescriptionKey : "Malformed upload url from: \(urlString)"])
            return Promise(error: malformedError)
        }
        AnalyticsTrackers.standard.track("sent image to Syte")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = imageData
        let sessionConfiguration = URLSessionConfiguration.default
//        sessionConfiguration.timeoutIntervalForResource = 60  // On GPRS, even 60 seconds timeout.
        sessionConfiguration.timeoutIntervalForRequest = 60
        let promise = URLSession(configuration: sessionConfiguration).dataTask(with: request).asDictionary()
        return promise
    }

    static func uploadToSyte(imageData: Data?, imageClassification: ClarifaiModel.ImageClassification) -> Promise<(String, [[String : Any]])> {
        return uploadToSyteWorkhorse(imageData: imageData, imageClassification: imageClassification)
            .then { dict -> Promise<(String, [[String : Any]])> in
                guard let responseObjectDict = dict as? [String : Any],
                    let uploadedURLString = responseObjectDict.keys.first,
                    let segments = responseObjectDict[uploadedURLString] as? [[String : Any]],
                    segments.count > 0 else {
                        let emptyError = NSError(domain: "Craze", code: 4, userInfo: [NSLocalizedDescriptionKey : "Syte returned no segments"])
                        print("Syte no segments. responseObject:\(dict)")
                        return Promise(error: emptyError)
                }
                print("uploadToSyte segments:\(segments)")
                return Promise(value: (uploadedURLString, segments))
        }
    }
    
    static func feedbackToSyte(isPositive: Bool, imageUrl: String?, offersUrl: String?, b0x: Double, b0y: Double, b1x: Double, b1y: Double) {
        // From an email from Adi Mizrahi on Dec. 20, 2017 at 11:43 am:
//        Headers:
//        Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmaW5nZXIiOiJ2L0NhY3YzREs5K0NxaVFTQXB1ZDFBPT0iLCJ0aW1lc3RhbXAiOjE1MTM3NjEzNzI1OTksInV1aWQiOiJjMTliZmVkNy05M2FmLTVkZjAtYTQ1ZS1kNWQ5ZGVmMjMzMjYifQ.6KtjqtvusixdqoaZjfp3au9b6SU5x-mdyq8WEJJx2U0
//
//        Request:
//
//        http://syteapi.com/et?
//        name=negative_feedback
//        &account_id=6677
//        &image_url=http%3A%2F%2Ffashionforward.mako.co.il%2Fwp-content%2Fuploads%2F2017%2F11%2FGettyImages-545137798.jpg
//        &offers_url=http%3A%2F%2Fd1wt9iscpot47x.cloudfront.net%2Foffers%3Fimage_url%3DaHR0cDovL2Zhc2hpb25mb3J3YXJkLm1ha28uY28uaWwvd3AtY29udGVudC91cGxvYWRzLzIwMTcvMTEvNjMyNS5qcGc%253D%26crop%3DeyJ5MiI6MC42MjcyMjI1Nzc4NTQ5OTA5LCJ5IjowLjIxNzk1MjgzNzQyMjQ5MDE0LCJ4MiI6MC42MDg4NDYzOTgwNzA0NTQ2LCJ4IjowLjM5OTQwNjA3MzYxNDk1NDk1fQ%253D%253D%26cats%3DWyJQdWxsb3ZlckFuZFNoaXJ0cyJd%26prob%3D0.4632%26gender%3Dmale%26feed%3Ddefault%26country%3DIL%26account_id%3D46%26session_id%3D84500797%26sig%3DCsDPsDJZ47WlTHOjhJx6QB6Jm3nAZhOPH2Tw3c9HmmI%253D%26account_id%3D46%26session_id%3D84500797%26sig%3DCsDPsDJZ47WlTHOjhJx6QB6Jm3nAZhOPH2Tw3c9HmmI%253D&sig=GglIWwyIdqi5tBOhAmQMA6gEJVpCPEbgf73OCXYbzCU%3D
//        &tags=feedback
//        &coords=eyJ5MSI6MC42MjcyMjI1Nzc4NTQ5OTA5LCJ5MCI6MC4yMTc5NTI4Mzc0MjI0OTAxNCwieDEiOjAuNjA4ODQ2Mzk4MDcwNDU0NiwieDAiOjAuMzk5NDA2MDczNjE0OTU0OTV9
//
//        * image_url and offers_url should be urlencoded
//        * please notice that name and tags changed to: name: negative_feedback || positive_feedback, tags: feedback
//        * coords should be a base64 encoded JSON, for example Base64('{"x0": 0.2, "y0": 0.2, "x1": 0.4, "y1": 0.5}')
        let accountId: Int
        let auth: String
        if let offersUrl = offersUrl,
            offersUrl.contains("&account_id=\(Constants.furnitureAccountId)") || offersUrl.contains("&feed=craze_home") {
            accountId = Constants.furnitureAccountId
            auth = Constants.furnitureHardcodedAuth
        } else {
            accountId = Constants.syteAccountId
            auth = Constants.syteHardcodedAuth
        }
        let urlEncodedImageUrl = imageUrl?.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        let urlEncodedOffersUrl = offersUrl?.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        let coordsObject = ["x0": b0x, "y0": b0y, "x1": b1x, "y1": b1y]
        let base64EncodedJsonCoords = jsonStringify(object: coordsObject)?.data(using: .utf8)?.base64EncodedString() ?? ""
        let urlString = "https://syteapi.com/et" +
            "?name=\(isPositive ? "positive_feedback" : "negative_feedback")" +
            "&account_id=\(accountId)" +
            "&image_url=\(urlEncodedImageUrl)" +
            "&offers_url=\(urlEncodedOffersUrl)" +
            "&tags=feedback" +
            "&coords=\(base64EncodedJsonCoords)"
        guard let url = URL(string: urlString) else {
            print("feedbackToSyte failed to create feedback url from string:\(urlString)")
            return
        }
        var request = URLRequest(url: url)
        request.addValue(auth, forHTTPHeaderField: "Authorization")
        let dataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("feedbackToSyte received error:\(error) for urlString:\(urlString)")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode >= 200,
              httpResponse.statusCode <  300 else {
                print("feedbackToSyte invalid http statusCode for urlString:\(urlString)")
                return
            }
        }
        dataTask.resume()
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
    
    static func downloadJsonArray(url: URL) -> Promise<NSArray> {
        let request = URLRequest(url: url)
        let session = URLSession.shared
        let dataPromise: URLDataPromise = session.dataTask(with: request)
        return dataPromise.asArray()
    }
    
    // See: https://github.com/mxcl/PromiseKit/blob/master/Documentation/CommonPatterns.md
    static func attempt<T>(interdelay: DispatchTimeInterval = .seconds(2), maxRepeat: Int = 3, body: @escaping () -> Promise<T>) -> Promise<T> {
        var attempts = 0
        
        func attempt() -> Promise<T> {
            attempts += 1
            return body().recover { error -> Promise<T> in
                guard attempts < maxRepeat else { throw error }
                return after(interval: interdelay).then {
                    return attempt()
                }
            }
        }
        
        return attempt()
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
    
    static func downloadProducts(url: URL) -> Promise<[String : Any]> {
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForResource = 45
        return URLSession(configuration: sessionConfiguration).dataTask(with: URLRequest(url: url)).asDictionary().then { nsDict in
            if let productsDict = nsDict as? [String : Any] {
                if let productsArray = productsDict["ads"] as? [[String : Any]], productsArray.count > 0 {
                    print("downloadProducts productsArray:\(productsArray)")
                    return Promise(value: productsDict)
                } else {
                    let error = NSError(domain: "Craze", code: 20, userInfo: [NSLocalizedDescriptionKey: "no products"])
                    return Promise(error: error)
                }
            }
            let error = NSError(domain: "Craze", code: 5, userInfo: [NSLocalizedDescriptionKey: "downloadProducts unknown error"])
            return Promise(error: error)
        }
    }
    
    static func downloadProductsWithRetry(url: URL) -> Promise<[String : Any]> {
        return attempt(interdelay: .seconds(11), maxRepeat: 2, body: {downloadProducts(url: url)})
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
    
    static func nextMatchsticks() -> Promise<NSDictionary> {
        let syncTokenParam: String
        if let matchsticksSyncToken = UserDefaults.standard.string(forKey: UserDefaultsKeys.matchsticksSyncToken),
          !matchsticksSyncToken.isEmpty {
            syncTokenParam = "?start=\(matchsticksSyncToken)"
        } else {
            syncTokenParam = ""
        }
        guard let url = URL(string: Constants.screenShotLambdaDomain + "screenshots/matchsticks" + syncTokenParam) else {
            let error = NSError(domain: "Craze", code: 21, userInfo: [NSLocalizedDescriptionKey: "Cannot create matchsticks url from screenShotLambdaDomain:\(Constants.screenShotLambdaDomain)"])
            return Promise(error: error)
        }
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = 60
        let promise = URLSession(configuration: sessionConfiguration).dataTask(with: URLRequest(url: url)).asDictionary()
        return promise
    }
    
    static func downloadImageData(urlString: String) -> Promise<Data> {
        guard let url = URL(string: urlString) else {
            let error = NSError(domain: "Craze", code: 25, userInfo: [NSLocalizedDescriptionKey: "Cannot form image url:\(urlString)"])
            return Promise(error: error)
        }
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = 60
        return URLSession(configuration: sessionConfiguration).dataTask(with: URLRequest(url: url)).asDataAndResponse().then { (data, response) -> Promise<Data> in
            guard let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode >= 200,
                httpResponse.statusCode <  300 else {
                    let error = NSError(domain: "Craze", code: 26, userInfo: [NSLocalizedDescriptionKey: "downloadImageData invalid http statusCode for urlString:\(urlString)"])
                    print("downloadImageData httpResponse.statusCode error")
                    return Promise(error: error)
            }
            return Promise(value: data)
        }
    }
    
    // Promises to return an AWS Subscription ARN identifying this device's subscription to our AWS cloud
    static func createAndSubscribeToSilentPushEndpoint(pushToken token: String, tzOffset: String, subscriptionARN arn: String? = nil) -> Promise<String> {
        guard let url = URL(string: Constants.screenShotLambdaDomain + "push-subscribe") else {
            let error = NSError(domain: "Craze", code: 9, userInfo: [NSLocalizedDescriptionKey: "Cannot create url from screenShotLambdaDomain:\(Constants.screenShotLambdaDomain)"])
            return Promise(error: error)
        }
        
        var parameters = [ "token": token, "timezone": tzOffset, "email": UserDefaults.standard.string(forKey: UserDefaultsKeys.email) ?? ""]

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
            guard let response = response as? HTTPURLResponse, response.statusCode >= 200 && response.statusCode < 300 else {
                return Promise(error: NSError(domain: "Craze", code: 0, userInfo: [NSLocalizedDescriptionKey : "Invalid status code received from AWS lambda"]))
            }
            
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
    
    static func shorten(url: URL, completion: @escaping (URL?) -> Void) {
        guard let shortenerUrl = URL(string: "https://craz.me/shortener") else {
            completion(nil)
            return
        }
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.setLocalizedDateFormatFromTemplate("yyyy-MM-dd")
        let dateNow = dateFormatter.string(from: Date())
        
        let postDict = ["type": "long", "long": url.absoluteString, "datePicker": dateNow]
        
        let postData = try? JSONSerialization.data(withJSONObject: postDict, options: [])
        let postLength = "\(postData == nil ? 0 : postData!.count)"
        
        var request = URLRequest(url: shortenerUrl)
        request.httpMethod = "POST"
        request.addValue(postLength, forHTTPHeaderField: "Content-Length")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = postData

        let session = URLSession.shared
        let completionHandler = { (data: Data?, response: URLResponse?, error: Error?) in
            var url: URL? = nil
            do {
                if let data = data,
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                    let shortString = json["short"] as? String {
                    url = URL(string: shortString)
                }
            } catch {
                print("NetworkingPromise shorten catch on JSONSerialization data:\(String(describing: data))")
            }
            DispatchQueue.main.async {
                completion(url)
            }
        }
        let dataTask = session.dataTask(with: request, completionHandler: completionHandler)
        dataTask.resume()
    }

}
