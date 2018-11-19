//
//  HTTPHelper.swift
//  Screenshop
//
//  Created by Zachary Podbela on 11/5/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation

public class HTTPHelper {
    static let FILL_DISCOVER_URL = "https://2xsab50nui.execute-api.us-east-1.amazonaws.com/dev_api/fill-discover-queue"
    static let ADD_USER_ACTION_URL = "https://2xsab50nui.execute-api.us-east-1.amazonaws.com/dev_api/add-user-action"
    static let DISCOVER_CONFIG_URL = "https://2xsab50nui.execute-api.us-east-1.amazonaws.com/dev_api/get-discover-config"
    static let DISCOVER_SESSION_URL = "https://2xsab50nui.execute-api.us-east-1.amazonaws.com/dev_api/start-discover-session"
    
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
                        do {
                            let errorDict = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as? NSDictionary
                            let responseError : NSError = NSError(domain: "HTTPHelperError", code: httpResponse.statusCode, userInfo: errorDict as? [AnyHashable: Any] as! [String : Any])
                            completion(data, responseError)
                        } catch {
                            //json parsing error -- do something.
                        }
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
