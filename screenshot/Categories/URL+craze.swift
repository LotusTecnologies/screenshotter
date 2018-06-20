//
//  URL+Craze.swift
//  screenshot
//
//  Created by Jonathan Rose on 3/26/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import Foundation

extension URL {
    static func urlWith(string:String, queryParameters:[String:String]) ->URL?{
        if var urlComponents = URLComponents.init(string: string){
            var queryItems:[URLQueryItem] = []
            if let q = urlComponents.queryItems {
                queryItems = q
            }
            //remove existing version of these parameters
            var items = queryItems.filter({ queryParameters[$0.name] == nil })
            
            //add the query parameters
            queryParameters.forEach({ (key, value) in
                items.append(URLQueryItem.init(name: key, value: value))
            })
            urlComponents.queryItems = items
            
            
            if let url = urlComponents.url {
                return url
            }
        }
        return nil
    }
}
