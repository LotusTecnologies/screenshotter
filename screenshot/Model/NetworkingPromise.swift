//
//  NetworkingPromise.swift
//  screenshot
//
//  Created by Gershon Kagan on 8/14/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit
import PromiseKit


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

    func uploadToSyteWorkhorse(imageData: Data?, orImageUrlString:String?, imageClassification: ClarifaiModel.ImageClassification, isUsc: Bool) -> Promise<NSDictionary> {
        guard imageClassification != .unrecognized else {
                let emptyError = NSError(domain: "Craze", code: 3, userInfo: [NSLocalizedDescriptionKey : "Empty image passed to Syte"])
                return Promise(error: emptyError)
        }
        var httpBody:Data?
        var payloadType:String = ""
        if let url = orImageUrlString {
            httpBody =  "[\"\(url)\"]".data(using: .utf8)
            payloadType = ""
        }else if let imageData = imageData {
            httpBody = imageData
            payloadType = "&payload_type=image_bin"
        }else{
            let emptyError = NSError(domain: "Craze", code: 3, userInfo: [NSLocalizedDescriptionKey : "Empty image passed to Syte"])
            return Promise(error: emptyError)
        }
        
        let urlString = imageClassification == .human
            ? "https://syteapi.com/v1.1/offers/bb?account_id=\(Constants.syteAccountId)&sig=\(Constants.syteAccountSignature)&features=related_looks,validate&feed=\(isUsc ? Constants.syteUscFeed : Constants.syteNonUscFeed)\(payloadType)"
            : "https://homedecor.syteapi.com/v1.1/offers/bb?account_id=\(Constants.furnitureAccountId)&sig=\(Constants.furnitureAccountSignature)&features=related_looks,validate&feed=craze_home\(payloadType)"

        guard let url = URL(string: urlString) else {
            let malformedError = NSError(domain: "Craze", code: 3, userInfo: [NSLocalizedDescriptionKey : "Malformed upload url from: \(urlString)"])
            return Promise(error: malformedError)
        }
        Analytics.trackSentImageToSyte()

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = httpBody
        let sessionConfiguration = URLSessionConfiguration.default
//        sessionConfiguration.timeoutIntervalForResource = 60  // On GPRS, even 60 seconds timeout.
        sessionConfiguration.timeoutIntervalForRequest = 60
        let promise = URLSession(configuration: sessionConfiguration).dataTask(with: request).asDictionary()
        return promise
    }

    func uploadToSyte(imageData: Data?, orImageUrlString:String?, imageClassification: ClarifaiModel.ImageClassification, isUsc: Bool) -> Promise<(String, [[String : Any]])> {
        return uploadToSyteWorkhorse(imageData: imageData, orImageUrlString:orImageUrlString, imageClassification: imageClassification, isUsc: isUsc)
            .then { dict -> Promise<(String, [[String : Any]])> in
                guard let responseObjectDict = dict as? [String : Any],
                    let uploadedURLString = responseObjectDict.keys.first,
                    let segments = responseObjectDict[uploadedURLString] as? [[String : Any]],
                    segments.count > 0 else {
                        let emptyError = NSError(domain: "Craze", code: 4, userInfo: [NSLocalizedDescriptionKey : "Syte returned no segments"])
                        print("Syte no segments. responseObject:\(dict)")
                        return Promise(error: emptyError)
                }
                return Promise(value: (uploadedURLString, segments))
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
    func attempt<T>(interdelay: DispatchTimeInterval = .seconds(2), maxRepeat: Int = 3, body: @escaping () -> Promise<T>) -> Promise<T> {
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
    
    func nextMatchsticks() -> Promise<NSDictionary> {
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
    
    func getAvailableVariants(partNumber: String) -> Promise<NSDictionary> {
        guard let url = URL(string: Constants.shoppableDomain + "/product/" + partNumber) else {
            let error = NSError(domain: "Craze", code: 27, userInfo: [NSLocalizedDescriptionKey: "Cannot create shoppable url from shoppableDomain:\(Constants.shoppableDomain)"])
            return Promise(error: error)
        }
        var request = URLRequest(url: url)
        request.addValue("bearer \(Constants.shoppableToken)", forHTTPHeaderField: "Authorization")
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
    
    func checkStock(partNumbers: [String]) -> Promise<([[String : Any]], [String])> {
        guard let url = URL(string: Constants.shoppableDomain + "/product?part_numbers=" + partNumbers.joined(separator: "%2C")) else {
            let error = NSError(domain: "Craze", code: 27, userInfo: [NSLocalizedDescriptionKey: "Cannot create shoppable url from shoppableDomain:\(Constants.shoppableDomain)"])
            print("networking checkStock url error:\(error)")
            return Promise(error: error)
        }
        var request = URLRequest(url: url)
        request.addValue("bearer \(Constants.shoppableToken)", forHTTPHeaderField: "Authorization")
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = 60
        return URLSession(configuration: sessionConfiguration).dataTask(with: request).asDataAndResponse().then { data, response -> Promise<([[String : Any]], [String])> in
            guard let httpResponse = response as? HTTPURLResponse else {
                let error = NSError(domain: "Craze", code: 42, userInfo: [NSLocalizedDescriptionKey: "checkStock no http response for url:\(String(describing: request.url))"])
                print("checkStock no httpResponse")
                return Promise(error: error)
            }
            let serializedObject: Any
            do {
                serializedObject = try JSONSerialization.jsonObject(with: data)
            } catch {
                let error = NSError(domain: "Craze", code: 42, userInfo: [NSLocalizedDescriptionKey: "checkStock JSONSerialize exception for url:\(String(describing: request.url))"])
                print("checkStock exception on JSONSerialize")
                return Promise(error: error)
            }
            guard httpResponse.statusCode >= 200,
                httpResponse.statusCode < 300 else {
                    let error: NSError
                    if httpResponse.statusCode == 422,
                        let jsonError = serializedObject as? [String : Any] {
                        error = NSError(domain: "Shoppable", code: httpResponse.statusCode, userInfo: jsonError)
                        print("checkStock Shoppable code:\(httpResponse.statusCode)  jsonError:\(String(describing: jsonError))")
                    } else {
                        error = NSError(domain: "Craze", code: 41, userInfo: [NSLocalizedDescriptionKey: "checkStock invalid http statusCode for url:\(String(describing: request.url))"])
                        print("checkStock httpResponse.statusCode error")
                    }
                    return Promise(error: error)
            }
            if let jsonObject = serializedObject as? [[[String : Any]]] { // First array is array of variant info, second array is array of out of stock. Either may be empty.
                let variantInfo: [[String : Any]] = jsonObject.first ?? []
                let outOfStocks: [String] = jsonObject.count >= 2 ? jsonObject[1].compactMap { $0["part_number"] as? String } : []
                return Promise(value: (variantInfo, outOfStocks))
            } else if let jsonObject = serializedObject as? [String : Any] { // Unlikely. If passed in single partNumber, receive dictionary, like redirect to /product/partNumber.
                let variantInfo: [[String : Any]]
                let outOfStocks: [String]
                if jsonObject["error"] as? String == "Product Not Found" {
                    variantInfo = []
                    if let partNumber = jsonObject["part_number"] as? String {
                        outOfStocks = [partNumber]
                    } else {
                        outOfStocks = []
                    }
                } else {
                    variantInfo = [jsonObject]
                    outOfStocks = []
                }
                return Promise(value: (variantInfo, outOfStocks))
            }
            let error = NSError(domain: "Craze", code: 42, userInfo: [NSLocalizedDescriptionKey: "checkStock JSONSerialize failed for url:\(String(describing: request.url))"])
            print("checkStock failed to JSONSerialize")
            return Promise(error: error)
        }
    }
    
    func nativeCheckout(remoteId: String, card: Card, cvv: String, shippingAddress: ShippingAddress) -> Promise<[[String : Any]]> {
        guard let url = URL(string: Constants.shoppableHosted + "/api/v3/token/\(Constants.shoppableToken)/checkout") else {
            let error = NSError(domain: "Craze", code: 37, userInfo: [NSLocalizedDescriptionKey: "Cannot form nativeCheckout url from shoppableDomain:\(Constants.shoppableDomain)"])
            return Promise(error: error)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("bearer \(Constants.shoppableToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("http://screenshopit.com", forHTTPHeaderField: "Referer")
        request.addValue("no-cache", forHTTPHeaderField: "Cache-Control")
        let tuple = divideByLastSpace(fullName: card.fullName)
        let billingFirstName = tuple.0
        let billingLastName = tuple.1
        let jsonObject: [String : Any] = [
            "billing_city" : card.city ?? "",
            "billing_country" : card.country ?? "",
            "billing_email" : card.email ?? "",
            "billing_first_name" : billingFirstName,
            "billing_last_name" : billingLastName,
            "billing_phone" : card.phone ?? "",
            "billing_postal_code" : card.zipCode ?? "",
            "billing_state" : card.state ?? "",
            "billing_street1" : card.street ?? "",
            "billing_street2" : "",
            "card_name" : card.fullName ?? "",
            "card_number" : card.retrieveCardNumber() ?? "",
            "cartId" : remoteId,
            "currency" : "USD",
            "expiry_month" : "\(card.expirationMonth)",
            "expiry_year" : "\(card.expirationYear)",
            "referer" : "http://screenshopit.com",
            "security_code" : cvv,
            "shipping_city" : shippingAddress.city ?? "",
            "shipping_country" : shippingAddress.country ?? "",
            "shipping_email" : card.email ?? "",
            "shipping_first_name" : shippingAddress.firstName ?? "",
            "shipping_last_name" : shippingAddress.lastName ?? "",
            "shipping_phone" : shippingAddress.phone ?? "",
            "shipping_postal_code" : shippingAddress.zipCode ?? "",
            "shipping_state" : shippingAddress.state ?? "",
            "shipping_street1" : shippingAddress.street ?? "",
            "shipping_street2" : ""
        ]
        request.httpBody = jsonDatafy(object: jsonObject)
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForResource = 60
        return sendAndParseNativeCheckout(request: request)
    }
    
    func sendAndParseNativeCheckout(request: URLRequest) -> Promise<[[String : Any]]> {
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForResource = 60
        return Promise<[[String : Any]]> { fulfill, reject in
            let dataTask = URLSession(configuration: sessionConfiguration).dataTask(with: request, completionHandler: { (data, response, error) in
                if let error = error {
                    print("sendAndParseNativeCheckout received error:\(error)")
                    reject(error)
                    return
                }
                guard let data = data else {
                    let error = NSError(domain: "Craze", code: 42, userInfo: [NSLocalizedDescriptionKey: "sendAndParseNativeCheckout empty data for url:\(String(describing: request.url))"])
                    print("sendAndParseNativeCheckout empty data")
                    reject(error)
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse else {
                    let error = NSError(domain: "Craze", code: 42, userInfo: [NSLocalizedDescriptionKey: "sendAndParseNativeCheckout no http response for url:\(String(describing: request.url))"])
                    print("sendAndParseNativeCheckout no httpResponse")
                    reject(error)
                    return
                }
                let serializedObject: Any
                do {
                    serializedObject = try JSONSerialization.jsonObject(with: data)
                } catch {
                    let error = NSError(domain: "Craze", code: 42, userInfo: [NSLocalizedDescriptionKey: "sendAndParseNativeCheckout JSONSerialize exception for url:\(String(describing: request.url))"])
                    print("sendAndParseNativeCheckout exception on JSONSerialize")
                    reject(error)
                    return
                }
                guard httpResponse.statusCode >= 200,
                  httpResponse.statusCode < 300 else {
                    let error: NSError
                    if httpResponse.statusCode == 422,
                      let jsonError = serializedObject as? [String : Any] {
                        error = NSError(domain: "Shoppable", code: httpResponse.statusCode, userInfo: jsonError)
                        print("sendAndParseNativeCheckout Shoppable code:\(httpResponse.statusCode)  jsonError:\(String(describing: jsonError))")
                    } else {
                        error = NSError(domain: "Craze", code: 41, userInfo: [NSLocalizedDescriptionKey: "sendAndParseNativeCheckout invalid http statusCode for url:\(String(describing: request.url))"])
                        print("sendAndParseNativeCheckout httpResponse.statusCode error")
                    }
                    reject(error)
                    return
                }
                guard let jsonObject = serializedObject as? [[String : Any]] else {
                    let error = NSError(domain: "Craze", code: 42, userInfo: [NSLocalizedDescriptionKey: "sendAndParseNativeCheckout JSONSerialize failed for url:\(String(describing: request.url))"])
                    print("sendAndParseNativeCheckout failed to JSONSerialize")
                    reject(error)
                    return
                }
                fulfill(jsonObject)
            })
            dataTask.resume()
        }
    }
    
    func geoLocateIsUSC() -> Promise<Bool> {
        guard let url = URL(string: "http://www.geoplugin.net/json.gp?jsoncallback=") else {
            let error = NSError(domain: "Craze", code: 49, userInfo: [NSLocalizedDescriptionKey: "Cannot form geoLocate url"])
            return Promise(error: error)
        }
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForResource = 60
        return URLSession(configuration: sessionConfiguration).dataTask(with: URLRequest(url: url)).asDictionary().then { dict -> Promise<Bool> in
            var isUsc = false
            if let countryCode = dict["geoplugin_countryCode"] as? String,
              countryCode == "US" || countryCode == "IL" {
                isUsc = true
            }
            UserDefaults.standard.set(isUsc, forKey: UserDefaultsKeys.isUSC)
            return Promise(value: isUsc)
        }
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
