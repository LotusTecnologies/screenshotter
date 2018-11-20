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
    static let FILL_DISCOVER_URL = "https://2xsab50nui.execute-api.us-east-1.amazonaws.com/dev_api/fill-discover-queue"
    static let ADD_USER_ACTION_URL = "https://2xsab50nui.execute-api.us-east-1.amazonaws.com/dev_api/add-user-action"
    static let DISCOVER_CONFIG_URL = "https://2xsab50nui.execute-api.us-east-1.amazonaws.com/dev_api/get-discover-config"
    static let DISCOVER_SESSION_URL = "https://2xsab50nui.execute-api.us-east-1.amazonaws.com/dev_api/start-discover-session"
    static let UPLOAD_DISCOVER_IMAGE_URL = "https://2xsab50nui.execute-api.us-east-1.amazonaws.com/dev_api/upload-discover-photo"
    
    static let API_KEY = "Q4ueHFYAuOaEm0512B2lW5HhclvKEe6T9zsFqVrm"
    
    public class func buildRequest(_ path: String!, method: String, requestContentType: HTTPRequestContentType = HTTPRequestContentType.httpJsonContent, requestBoundary:String = "") -> NSMutableURLRequest {
        // 1. Create the request URL from path
        let requestURL = URL(string: path)
        let request = NSMutableURLRequest(url: requestURL!)
        
        // Set HTTP request method and Content-Type
        request.httpMethod = method
        
        // 2. Set the correct Content-Type for the HTTP Request. This will be multipart/form-data for photo upload request and application/json for other requests in this app
        switch requestContentType {
        case .httpJsonContent:
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        case .httpMultipartContent:
            let contentType = "multipart/form-data; boundary=\(requestBoundary)"
            request.addValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        
        // 3. Set the correct Authorization header.
        request.addValue(API_KEY, forHTTPHeaderField: "x-api-key")
        
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
