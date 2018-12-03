//
//  HTTPHelper.swift
//  Screenshop
//
//  Created by Zachary Podbela on 11/5/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation

public enum HTTPRequestContentType {
    case httpJsonContent
    case httpMultipartContent
}

public class HTTPHelper {
    static var serverConfig: NSDictionary! {
        return (Bundle.main.object(forInfoDictionaryKey: "Server Config") as? NSDictionary) ?? NSDictionary()
    }
    static let API_KEY:String? = serverConfig.value(forKey: "API Key") as? String
    static let DOMAIN = serverConfig.value(forKey: "Domain") as? String ?? ""
    
    static let FILL_DISCOVER_URL = DOMAIN+"/fill-discover-queue"
    static let ADD_USER_ACTION_URL = DOMAIN+"/add-user-action"
    static let DISCOVER_CONFIG_URL = DOMAIN+"/get-discover-config"
    static let DISCOVER_SESSION_URL = DOMAIN+"/start-discover-session"
    static let UPLOAD_DISCOVER_IMAGE_URL = DOMAIN+"/upload-discover-photo"
    
    public class func buildRequest(_ path: String!, method: String, params inparams:[String:Any] = [String:Any](), requestContentType: HTTPRequestContentType = HTTPRequestContentType.httpJsonContent, requestBoundary:String = "") -> NSMutableURLRequest {
        
        var params = inparams
        
        // Decorate with params that should accompany every request
        let userID = UserDefaults.standard.string(forKey: UserDefaultsKeys.userID) ?? ""
        params["user_id"] = userID
        params["user_ss_uuid"] = userID
        
        var jsonData:Data? = nil
        var urlParamString = ""
        if method == "GET" {
            // Add params as URL params
            for (key, value) in params {
                let paramPrefix:String = urlParamString.isEmpty ? "?" : "&"
                urlParamString += "\(paramPrefix)\(key)=\(value)"
            }
        } else {
            // Add params as body Data
            jsonData = try? JSONSerialization.data(withJSONObject: params)
        }
        
        // Create the request URL from path and add params
        let requestURL = URL(string: path+urlParamString)!
        let request = NSMutableURLRequest(url: requestURL)
        request.httpMethod = method
        if let data = jsonData {
            request.httpBody = data
        }
        
        // Set the correct Content-Type for the HTTP Request. This will be multipart/form-data for photo upload request and application/json for other requests in this app
        switch requestContentType {
        case .httpJsonContent:
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        case .httpMultipartContent:
            let contentType = "multipart/form-data; boundary=\(requestBoundary)"
            request.addValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        
        // 3. Set the correct Authorization header.
        if let key = API_KEY {
            request.addValue(key, forHTTPHeaderField: "x-api-key")
        }
        
        return request
    }
    
    public class func asyncRequest(_ request: URLRequest, completion:@escaping (Data?, NSError?) -> Void) -> () {
        // Create a NSURLSession task
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler:  {(data: Data?, response: URLResponse?, error: Error?) -> Void in
            
            //if error making request
            if error != nil {
                DispatchQueue.main.async {
                    completion(data, error as NSError?)
                }
            }
            
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse {
                    if (httpResponse.statusCode >= 200) && (httpResponse.statusCode < 300) {
                        //If status is 2xx, success!
                        completion(data, nil)
                    } else {
                        //if request was made ok, but server returned error (non 200)
                        let responseError : NSError = NSError(domain: "HTTPHelperError", code: httpResponse.statusCode, userInfo: nil)
                        completion(data, responseError)
                    }
                }
            }
        })
        
        // start the task
        task.resume()
    }
}

extension URLSession {
    func synchronousDataTask(with request: URLRequest) -> (Data?, URLResponse?, Error?) {
        var data: Data?
        var response: URLResponse?
        var error: Error?
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let dataTask = self.dataTask(with: request) {
            data = $0
            response = $1
            error = $2
            
            semaphore.signal()
        }
        dataTask.resume()
        
        _ = semaphore.wait(timeout: .distantFuture)
        
        return (data, response, error)
    }
}
