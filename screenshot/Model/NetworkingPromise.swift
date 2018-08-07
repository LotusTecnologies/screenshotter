//
//  NetworkingPromise.swift
//  screenshot
//
//  Created by Gershon Kagan on 8/14/17.
//  Copyright (c) 2017 crazeapp. All rights reserved.
//

import UIKit
import PromiseKit
import CoreData

struct ChangelogResponse : Decodable {
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

class NetworkingPromise : NSObject {
    
    public static let sharedInstance = NetworkingPromise()
    
    override init() {
        // do stuff
        super.init()
    }

    func changelog(forAppVersion appVersion: String, localeIdentifier: String) -> Promise<ChangelogResponse> {
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

    func uploadToSyteURLRequest(imageData: Data?, orImageUrlString:String?) -> Promise<URLRequest> {
        var httpBody:Data?
        var payloadType:String = ""
        if let urlToSendToSyte = orImageUrlString {
            if let urlListBody = "[\"\(urlToSendToSyte)\"]".data(using: .utf8) {
                httpBody = urlListBody
            } else {
                let emptyError = NSError(domain: "Craze", code: 3, userInfo: [NSLocalizedDescriptionKey : "Bad URL array to Syte from:\(urlToSendToSyte)"])
                return Promise(error: emptyError)
            }
            payloadType = ""
        }else if let imageData = imageData {
            httpBody = imageData
            payloadType = "&payload_type=image_bin"
        }else{
            let emptyError = NSError(domain: "Craze", code: 3, userInfo: [NSLocalizedDescriptionKey : "Empty image passed to Syte"])
            return Promise(error: emptyError)
        }
        
        let urlString = "https://syteapi.com/v1.1/offers/bb?account_id=\(Constants.syteAccountId)&sig=\(Constants.syteAccountSignature)&features=related_looks&catalog=fashion\(payloadType)"

        guard let url = URL(string: urlString) else {
            let malformedError = NSError(domain: "Craze", code: 3, userInfo: [NSLocalizedDescriptionKey : "Malformed upload url from: \(urlString)"])
            return Promise(error: malformedError)
        }
        Analytics.trackSentImageToSyte()

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = httpBody
        return Promise(value: request)
    }

    
    enum UploadToSyteError : Error {
        case unknown
        case invalidResponse
        case not200
        case noData
        case cannotParseJson
        case jsonIsNotObjectWithStringKeys
        case emptyObject
        case shopablesIsNotArrayWithStringKeys
        case noShoppables
        public static var errorDomain: String {
            return "io.crazeapp.screenshot.networkPromise.uploadToSyte"
        }
        public var errorCode: Int {
            switch self {
            case .unknown:
                return -1
            case .invalidResponse:
                return 1
            case .not200:
                return 2
            case .noData:
                return 3
            case .cannotParseJson:
                return 4
            case .jsonIsNotObjectWithStringKeys:
                return 5
            case .emptyObject:
                return 6
            case .shopablesIsNotArrayWithStringKeys:
                return 7
            case .noShoppables:
                return 8
            
            
            }
        }
        public var localizedDescription: String {
            switch self {
            case .unknown:
                return "uploadToSyte internal coding error"
            case .invalidResponse:
                return "uploadToSyte invalid response"
            case .not200:
                return "uploadToSyte invalid status code"
            case .noData:
                return "uploadToSyte no data"
            case .cannotParseJson:
                return "uploadToSyte invalid json"
            case .jsonIsNotObjectWithStringKeys:
                return "uploadToSyte invalid response object dictionary"
            case .emptyObject:
                return "uploadToSyte empty object"
            case .shopablesIsNotArrayWithStringKeys:
                return "shopables is not an array with string"
            case .noShoppables:
                return "uploadToSyte returned no segments"
            }
        }
    
    }
    func parseSyteResponse(data:Data?, response:URLResponse?, error:Error?) -> (NSError?, (String, [[String : Any]])?) {
        if let error = error {
            return (error as NSError, nil)
        }
        guard let response = response as? HTTPURLResponse else {
            let error = UploadToSyteError.invalidResponse
            return (NSError(domain: UploadToSyteError.errorDomain, code: error.errorCode, userInfo: [NSLocalizedDescriptionKey : error.localizedDescription]), nil)
        }

        guard response.statusCode >= 200 && response.statusCode < 300 else {
            let error = UploadToSyteError.not200
            var reason = error.localizedDescription
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                reason = dataString
            }
            return (NSError(domain: UploadToSyteError.errorDomain, code: error.errorCode, userInfo: [NSLocalizedDescriptionKey : reason,"statusCode":response.statusCode]), nil)
        }
        guard let data = data else {
            let error = UploadToSyteError.noData
            return (NSError(domain: UploadToSyteError.errorDomain, code: error.errorCode, userInfo: [NSLocalizedDescriptionKey : error.localizedDescription,"statusCode":response.statusCode]), nil)

        }
        guard let responseObject = (try? JSONSerialization.jsonObject(with: data, options: [])) else{
            let error = UploadToSyteError.cannotParseJson
            return (NSError(domain: UploadToSyteError.errorDomain, code: error.errorCode, userInfo: [NSLocalizedDescriptionKey : error.localizedDescription,"statusCode":response.statusCode]), nil)
        }
        guard let responseObjectDict = responseObject as? [String: Any] else {
            let error = UploadToSyteError.jsonIsNotObjectWithStringKeys
            return (NSError(domain: UploadToSyteError.errorDomain, code: error.errorCode, userInfo: [NSLocalizedDescriptionKey : error.localizedDescription,"statusCode":response.statusCode]), nil)
        }
        guard let uploadedURLString = responseObjectDict.keys.first else {
            let error = UploadToSyteError.emptyObject
            return (NSError(domain: UploadToSyteError.errorDomain, code: error.errorCode, userInfo: [NSLocalizedDescriptionKey : error.localizedDescription,"statusCode":response.statusCode]), nil)
        }
        guard let segments = responseObjectDict[uploadedURLString] as? [[String : Any]] else{
            let error = UploadToSyteError.shopablesIsNotArrayWithStringKeys
            return (NSError(domain: UploadToSyteError.errorDomain, code: error.errorCode, userInfo: [NSLocalizedDescriptionKey : error.localizedDescription,"statusCode":response.statusCode]), nil)
        }
        guard segments.count > 0 else {
            let error = UploadToSyteError.noShoppables
            return (NSError(domain: UploadToSyteError.errorDomain, code: error.errorCode, userInfo: [NSLocalizedDescriptionKey : error.localizedDescription,"statusCode":response.statusCode]), nil)
        }
        return (nil, (uploadedURLString, segments))
    }
    func uploadToSyteWorkHorse( request:URLRequest) -> Promise<(String, [[String : Any]])> {
        return Promise { fulfill, reject in
            let sessionConfiguration = URLSessionConfiguration.default
            //        sessionConfiguration.timeoutIntervalForResource = 60  // On GPRS, even 60 seconds timeout.
            sessionConfiguration.timeoutIntervalForRequest = 60
            let dataTask = URLSession(configuration: sessionConfiguration).dataTask(with: request) { data, response, error in
                let (error, tuple) = self.parseSyteResponse(data: data, response: response, error: error)
                if let error = error {
                    reject(error)
                }else if let tuple = tuple{
                    fulfill(tuple)
                }else{
                    //unexpected
                    reject(UploadToSyteError.unknown)
                }
            }
            dataTask.resume()
        }
    }
    func uploadToSyte(imageData: Data?, orImageUrlString:String?) -> Promise<(String, [[String : Any]])> {
        return self.uploadToSyteURLRequest(imageData: imageData, orImageUrlString:orImageUrlString).then { request -> Promise<(String, [[String : Any]])> in
            return self.attempt(interdelay:.seconds(2), maxRepeat: 3, body: { return self.uploadToSyteWorkHorse(request: request) }, retryableError: { (error) -> (Bool) in
                let nsError = error as NSError
                let retryable:Bool =  ((nsError.code == UploadToSyteError.emptyObject.errorCode  || nsError.code == UploadToSyteError.noShoppables.errorCode ) && nsError.domain == UploadToSyteError.errorDomain)
                if retryable {
                    Analytics.trackDevLog(file:  NSString.init(string: #file).lastPathComponent, line: #line, message: "retrying {} or {id:[]} response from syte")
                }
                return retryable
            }).catch(execute: { (error) in
                let nsError = error as NSError
                Analytics.trackReceivedUploadErrorFromSyte(imageUrl: orImageUrlString, httpStatusCode: (nsError.userInfo["statusCode"] as? Int), reason: error.localizedDescription)
            })
        }
    }
    
    func feedbackToSyte(isPositive: Bool, imageUrl: String?, offersUrl: String?, b0x: Double, b0y: Double, b1x: Double, b1y: Double) {
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
        let base64EncodedJsonCoords = jsonDatafy(object: coordsObject)?.base64EncodedString() ?? ""
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
    
    func jsonDatafy(object: Any) -> Data? {
        if let objectData = try? JSONSerialization.data(withJSONObject: object, options: []) {
            return objectData
        }
        return nil
    }
    
    func jsonStringify(object: Any) -> String? {
        if let objectData = try? JSONSerialization.data(withJSONObject: object, options: []) {
            let objectString = String(data: objectData, encoding: .utf8)
            return objectString
        }
        return nil
    }
    
    func jsonDestringify(string: String) -> [[String : Any]]? {
        guard let data = string.data(using: .utf8),
            let segments = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [[String: Any]] else {
                return nil
        }
        return segments
    }
    
    func downloadJsonArray(url: URL) -> Promise<NSArray> {
        let request = URLRequest(url: url)
        let session = URLSession.shared
        let dataPromise: URLDataPromise = session.dataTask(with: request)
        return dataPromise.asArray()
    }
    
    // See: https://github.com/mxcl/PromiseKit/blob/master/Documentation/CommonPatterns.md
    func attempt<T>(interdelay: DispatchTimeInterval = .seconds(2), maxRepeat: Int = 3, body: @escaping () -> Promise<T>, retryableError: ((Error)->(Bool))? = nil) -> Promise<T> {
        var attempts = 0
        
        func attempt() -> Promise<T> {
            attempts += 1
            return body().recover { error -> Promise<T> in
                guard attempts < maxRepeat else { throw error }
                if let retryableError = retryableError {
                    if !retryableError(error) {
                        throw error
                    }
                }
                return after(interval: interdelay).then {
                    return attempt()
                }
            }
        }
        
        return attempt()
    }
    
    func downloadInfo(url: URL) -> Promise<[String : Any]> {
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
    
    func downloadProducts(url: URL) -> Promise<[String : Any]> {
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForResource = 45
        return URLSession(configuration: sessionConfiguration).dataTask(with: URLRequest(url: url)).asDictionary().then { nsDict in
            if let productsDict = nsDict as? [String : Any] {
                if let productsArray = productsDict["ads"] as? [[String : Any]], productsArray.count > 0 {
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
    
    func downloadProductsWithRetry(url: URL) -> Promise<[String : Any]> {
        return attempt(interdelay: .seconds(11), maxRepeat: 2, body: {self.downloadProducts(url: url)})
    }
  
    struct RecombeeRecommendation{
        var imageURL:String
        var remoteId:String
        var properties:[String:[String]] = [:]
    }
    func recombeeRecommendation(count:Int, gender:ProductsOptionsGender) -> Promise<[RecombeeRecommendation]>{
        let userId = AnalyticsUser.current.identifier
        var params:[String:Any] = [:]
        params["count"] = count
        params["cascadeCreate"] = true
        params["rotationRate"] = 0.99
        params["filter"] = "'displayable' == true"
        params["returnProperties"] = true
        params["includedProperties"] = "rekognition-labels,genders,itemTypes,rekognition-celebs"
        if gender == .female {
            params["filter"] = "'displayable' == true AND \"female\" in 'genders'"
        }else if gender == .male{
            params["filter"] = "'displayable' == true AND \"male\" in 'genders'"
        }
        params["rotationTime"] = 60*60*24*2 // 2 days rotation
        return NetworkingPromise.sharedInstance.recombeeRequest(path: "recomms/users/\(userId)/items/", method: "GET", params: params).then { (dict) -> Promise<[RecombeeRecommendation]> in
            var toReturn:[RecombeeRecommendation] = []
            if let recomms = dict["recomms"] as? [[String:Any]]{
                if recomms.count == 0 {
                    //turn off filter...
                     UserDefaults.standard.set(true, forKey: UserDefaultsKeys.discoverDontFilter)
                }
                recomms.forEach({ (matchstick) in
                    if let index = matchstick["id"] as? String {
                        var properties:[String:[String]] = [:]
                        
                        if let values = matchstick["values"] as? [String:Any]{
                            values.forEach({ (key, value) in
                                if let value = value as? [String] {
                                    properties[key] = value
                                }
                            })
                        }
                        
                        toReturn.append(RecombeeRecommendation.init(imageURL: "https://s3.amazonaws.com/screenshop-ordered-matchsticks/\(index).jpg", remoteId: "\(index)", properties:properties))
                    }
                })
            }
            return Promise.init(value:toReturn)
        }
    }
    func recombeeRequest(path:String, method:String, params:[String:Any]? ) -> Promise<NSDictionary> {
        let hostName = "rapi.recombee.com"
        let databaseId = "screenshop"
        let hmac_timestamp = String(Int(NSDate().timeIntervalSince1970))
        let partialPath = "/\(databaseId)/\(path)"
        var queryItems = [URLQueryItem.init(name: "hmac_timestamp", value: "\(hmac_timestamp)")]
        if let params = params, method == "GET" {
            params.forEach({ (arg) in
                let (key, value) = arg
                    queryItems.append( URLQueryItem.init(name: key, value: "\(value)"))


            })
        }
        var components = URLComponents.init()
        components.path = partialPath
        components.queryItems = queryItems
        if let string = components.string {
            let recombeeKey = "TJVMFkb5sq4aaIXJGTCrCzPKsjxuyV8RLZOBlXt9QhGQSVOLNgy4jp3lqdlOc8Gn"
            let hmac_sign = string.hmac(algorithm: .SHA1, key: recombeeKey)
            let urlString = "https://\(hostName)\(string)&hmac_sign=\(hmac_sign)"
            
            if let url = URL.init(string: urlString ) {
                var request = URLRequest.init(url: url )
                request.httpMethod = method
                request.addValue("application/json", forHTTPHeaderField: "Accept")
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                if let params = params, method == "POST" {
                    do{
                        let parameterData = try JSONSerialization.data(withJSONObject: params, options: [])
                        request.httpBody = parameterData
                        request.setValue("\(parameterData.count)", forHTTPHeaderField: "Content-Length")
                    }catch{
                        print("recombee request error:\(error)")
                    }
                }
                let sessionConfiguration = URLSessionConfiguration.default
                sessionConfiguration.timeoutIntervalForRequest = 60
                let promise = URLSession(configuration: sessionConfiguration).dataTask(with: request).asDictionary()
                return promise
            }
        }
        return Promise.init(error: NSError.init(domain:  NSString.init(string: #file).lastPathComponent, code: #line, userInfo: [NSLocalizedDescriptionKey:"unable to make url\(path) = \(String(describing: params))"]))
        
    }
    
    func downloadImageData(urlString: String) -> Promise<Data> {
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
    
    func downloadTmp(from urlString: String, identifier: String) -> Promise<URL> {
        guard let url = URL(string: urlString) else {
            return Promise(error: NSError(domain: "Craze", code: 95, userInfo: [NSLocalizedDescriptionKey: "downloadTmp failed to form url for urlString:\(urlString)"]))
        }
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = 60
        return URLSession(configuration: sessionConfiguration).dataTask(with: URLRequest(url: url)).asDataAndResponse().then { (data, response) -> Promise<URL> in
            return self.saveToTmp(data: data, identifier: identifier, originalExtension: url.pathExtension)
        }
    }

    func saveToTmp(data: Data, identifier: String, originalExtension: String) -> Promise<URL> {
        let appendingExtension = originalExtension.isEmpty ? "jpg" : originalExtension
        let tmpImageFileUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(identifier).appendingPathExtension(appendingExtension)
        do {
            try data.write(to: tmpImageFileUrl)
            return Promise(value: tmpImageFileUrl)
        } catch {
            print("saveToTmp error:\(error)")
            return Promise(error: error)
        }
    }
    
    func getAvailableVariants(partNumber: String) -> Promise<NSDictionary> {
        guard let url = URL(string: Constants.shoppableDomain + "/product/" + partNumber) else {
            let error = NSError(domain: "Craze", code: 27, userInfo: [NSLocalizedDescriptionKey: "Cannot create shoppable url from shoppableDomain:\(Constants.shoppableDomain)"])
            return Promise(error: error)
        }
        var request = URLRequest(url: url)
        request.addValue("bearer \(Constants.shoppableToken)", forHTTPHeaderField: "Authorization")
        request.addValue(AnalyticsUser.current.identifier, forHTTPHeaderField: "cid")
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForResource = 60
        let promise = URLSession(configuration: sessionConfiguration).dataTask(with: request).asDictionary()
        return promise
    }
    
    func createCart() -> Promise<NSDictionary> {
        guard let url = URL(string: Constants.shoppableDomain + "/cart") else {
            let error = NSError(domain: "Craze", code: 33, userInfo: [NSLocalizedDescriptionKey: "Cannot create cart url from shoppableDomain:\(Constants.shoppableDomain)"])
            return Promise(error: error)
        }
        var request = URLRequest(url: url)
        request.addValue("bearer \(Constants.shoppableToken)", forHTTPHeaderField: "Authorization")
        request.addValue(AnalyticsUser.current.identifier, forHTTPHeaderField: "cid")
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForResource = 60
        let promise = URLSession(configuration: sessionConfiguration).dataTask(with: request).asDictionary()
        return promise
    }

    func clearCart(remoteId: String) -> Promise<Bool> {
        guard let url = URL(string: Constants.shoppableDomain + "/cart/\(remoteId)/clear") else {
            let error = NSError(domain: "Craze", code: 43, userInfo: [NSLocalizedDescriptionKey: "Cannot create clearCart url from remoteId:\(remoteId)  shoppableDomain:\(Constants.shoppableDomain)"])
            return Promise(error: error)
        }
        var request = URLRequest(url: url)
        request.addValue("bearer \(Constants.shoppableToken)", forHTTPHeaderField: "Authorization")
        request.addValue(AnalyticsUser.current.identifier, forHTTPHeaderField: "cid")
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForResource = 60
        return URLSession(configuration: sessionConfiguration).dataTask(with: request).asDataAndResponse().then { (data, response) -> Promise<Bool> in
            guard let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode >= 200,
                httpResponse.statusCode <  300 else {
                    let error = NSError(domain: "Craze", code: 44, userInfo: [NSLocalizedDescriptionKey: "clearCart invalid http statusCode for url:\(url)"])
                    print("clearCart httpResponse.statusCode error")
                    return Promise(error: error)
            }
            // Don't bother parsing the contents of what was returned; http status is enough, as on Android.
            // Contents changes between prod and dev, on March 13, 2018.
            return Promise(value: true)
        }
    }

    func validateCart(jsonObject: [String : Any]) -> Promise<[String : Any]> {
        guard let url = URL(string: Constants.shoppableDomain + "/cart/put/bundling") else {
            let error = NSError(domain: "Craze", code: 37, userInfo: [NSLocalizedDescriptionKey: "Cannot form cart bundle url from shoppableDomain:\(Constants.shoppableDomain)"])
            return Promise(error: error)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("bearer \(Constants.shoppableToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(AnalyticsUser.current.identifier, forHTTPHeaderField: "cid")
        request.httpBody = jsonDatafy(object: jsonObject)
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForResource = 60
        return URLSession(configuration: sessionConfiguration).dataTask(with: request).asDataAndResponse().then { (data, response) -> Promise<[String : Any]> in
            guard let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode >= 200,
                httpResponse.statusCode <  300 else {
                    let error = NSError(domain: "Craze", code: 41, userInfo: [NSLocalizedDescriptionKey: "validateCart invalid http statusCode for url:\(url)"])
                    print("validateCart httpResponse.statusCode error")
                    return Promise(error: error)
            }
            if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String : Any] {
                return Promise(value: jsonObject)
            } else {
                let error = NSError(domain: "Craze", code: 42, userInfo: [NSLocalizedDescriptionKey: "validateCart JSONSerialize failed for url:\(url)"])
                print("validateCart failed to JSONSerialize data.count:\(data.count)")
                return Promise(error: error)
            }
        }
    }
    
    func divideByLastSpace(fullName: String?) -> (String, String) {
        let firstName: String
        let lastName: String
        if let fullName = fullName?.trimmingCharacters(in: .whitespacesAndNewlines),
            let lastSpaceRange = fullName.range(of: " ", options: .backwards) {
            firstName = String(fullName[..<lastSpaceRange.lowerBound])
            lastName = String(fullName[lastSpaceRange.upperBound...])
        } else {
            firstName = fullName ?? ""
            lastName = ""
        }
        return (firstName, lastName)
    }
    
    
    
    
    // Promises to return an AWS Subscription ARN identifying this device's subscription to our AWS cloud
    func createAndSubscribeToSilentPushEndpoint(pushToken token: String, tzOffset: String, subscriptionARN arn: String? = nil) -> Promise<String> {
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
    
    func registerPriceAlert(partNumber: String, lastPrice: Float, pushToken: String, outOfStock: Bool) -> Promise<Bool> {
        let parameterDict: [String : Any] =
            ["pushToken" : pushToken,
             "pushTokenPlatform" : "ios",
             "partNumber" : partNumber,
             "lastPrice" : lastPrice,
             "outOfStock" : outOfStock] // One of lastPrice and outOfStock must be provided. Each is optional.
        return priceAlertWorkhorse(parameterDict: parameterDict, actionName: "registerPriceAlert", serverActionName: "track")
    }
    
    // action = [tapped|favorited|disabled]
    func registerCrazePriceAlert(id: String, merchant: String, lastPrice: Float, firebaseId: String, action: String = "favorited") -> Promise<(Data, URLResponse)> {
        guard let url = URL(string: "\(Constants.notificationsApiEndpoint)/users/\(firebaseId)/subscriptions") else {
            let error = NSError(domain: "Craze", code: 9, userInfo: [NSLocalizedDescriptionKey: "Cannot create url from notificationsApiEndpoint:\(Constants.notificationsApiEndpoint)"])
            return Promise(error: error)
        }
        let parameters = ["subscription" : ["priceAlert" : ["lastSeenPrice" : lastPrice, "variantId" : id, "type" : action, "merchant" : merchant]]]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(AnalyticsUser.current.identifier, forHTTPHeaderField: "cid")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            return Promise(error: error)
        }
        
        return URLSession.shared.dataTask(with: request).asDataAndResponse()
    }
    
    func deregisterPriceAlert(partNumber: String, pushToken: String) -> Promise<Bool> {
        let parameterDict: [String : Any] =
            ["pushToken" : pushToken,
             "pushTokenPlatform" : "ios",
             "partNumber" : partNumber]
        return priceAlertWorkhorse(parameterDict: parameterDict, actionName: "deregisterPriceAlert", serverActionName: "unTrack")
    }

    func priceAlertWorkhorse(parameterDict: [String : Any], actionName: String, serverActionName: String) -> Promise<Bool> {
        guard let url = URL(string: Constants.screenShotLambdaDomain + "productSubscription/\(serverActionName)") else {
            let error = NSError(domain: "Craze", code: 60, userInfo: [NSLocalizedDescriptionKey: "Cannot create \(actionName) url from screenShotLambdaDomain:\(Constants.screenShotLambdaDomain)"])
            print(error)
            return Promise(error: error)
        }
        guard let parameterData = try? JSONSerialization.data(withJSONObject: parameterDict, options: []) else {
            let error = NSError(domain: "Craze", code: 61, userInfo: [NSLocalizedDescriptionKey: "Cannot JSONSerialize \(actionName) parameterDict:\(parameterDict)"])
            print(error)
            return Promise(error: error)
        }
        
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = parameterData
        
        return URLSession.shared.dataTask(with: request).asDataAndResponse().then { data, response -> Promise<Bool> in
            guard let response = response as? HTTPURLResponse, response.statusCode >= 200 && response.statusCode < 300 else {
                let error = NSError(domain: "Craze", code: 62, userInfo: [NSLocalizedDescriptionKey: "Invalid status code received from \(actionName) url:\(url)"])
                print(error)
                return Promise(error: error)
            }
            return Promise(value: true)
        }.catch { (error) in
                print("error from tracking price alert: \(error)")
        }
    }

    func submitToDiscover(image: String, userName: String?,  intercomUserId: String?, email: String?) -> Promise<NSDictionary>{
        var parameterDict = ["image" : image]
        if let userName = userName, !userName.isEmpty {
            parameterDict["userName"] = userName
        }
        if let intercomUserId = intercomUserId, !intercomUserId.isEmpty {
            parameterDict["intercomUserId"] = intercomUserId
        }
        if let email = email, !email.isEmpty {
            parameterDict["email"] = email
        }
        do {
            let parameterData = try JSONSerialization.data(withJSONObject: parameterDict, options: [])
            
            guard let url = URL(string: Constants.screenShotLambdaDomain + "matchstick/submit") else {
                let error = NSError(domain: "Craze", code: 9, userInfo: [NSLocalizedDescriptionKey: "Cannot create URL"])
                return Promise.init(error: error)
                
            }
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.httpBody = parameterData
                request.setValue("\(parameterData.count)", forHTTPHeaderField: "Content-Length")
                request.setValue("application/json", forHTTPHeaderField:"Content-Type")
                
                return URLSession.shared.dataTask(with: request).asDictionary()
        }catch {
            let error = NSError(domain: "Craze", code: 10, userInfo: [NSLocalizedDescriptionKey: "Cannot JSONSerialize params"])
            return Promise.init(error: error)
        }
        
    }
    
    func share(userName: String?, imageURLString: String?, syteJson: String?) -> Promise<(String, String)> {
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
        return self.shareWorkhorse(parameterData: parameterData, url: url)
    }
    
    func reshare(userName: String?, shareId: String?) -> Promise<(String, String)> {
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
        return self.shareWorkhorse(parameterData: parameterData, url: url)
    }
    
    func shareWorkhorse(parameterData: Data, url: URL) -> Promise<(String, String)> {
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
    
    func sendProductEmail( brand:String, title:String, offer:String, price:String, imageURL:String, email:String) -> Promise<NSDictionary>{
        let postDict:[String:Any] = [
            "email":email,
            "products":[[
                "brand":brand,
                "title":title,
                "link":offer,
                "price":price,
                "image":imageURL]]
        ]
        let userId = UserAccountManager.shared.user?.uid ?? "unknown"
        
        if let url = URL(string: Constants.notificationsApiEndpoint + "/users/\(userId)/emailme"), let postData = try? JSONSerialization.data(withJSONObject: postDict, options: []) {
            let postLength = "\(postData.count)"
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue(postLength, forHTTPHeaderField: "Content-Length")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            request.addValue(AnalyticsUser.current.identifier, forHTTPHeaderField: "cid")

            request.httpBody = postData
            
            
            return URLSession.shared.dataTask(with: request).asDictionary()
            
        }else{
            let error = NSError(domain: "Craze", code: #line, userInfo: [NSLocalizedDescriptionKey: "unable to send 'emailme' request"])
            return Promise(error: error)
            
        }
    }
    
    func sendProductEmailWithRetry( product:Product, email:String) -> Promise<NSDictionary>{
        let title = product.productTitle() ?? ""
        let brand = product.calculatedDisplayTitle ?? ""
        let offer = product.offer ?? ""
        let price = product.price ?? ""
        let imageURL = product.imageURL ?? ""
        return attempt(interdelay: .seconds(21), maxRepeat: 5, body: { self.sendProductEmail(brand: brand, title: title, offer: offer, price: price, imageURL: imageURL, email: email)   })
    }
    
    func appSettings() -> Promise<[String : Any]> {
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
    
    func shorten(url: URL, completion: @escaping (URL?) -> Void) {
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
