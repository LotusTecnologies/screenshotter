//
//  DiscoverManager+categories.swift
//  Screenshop
//
//  Created by Jonathan Rose on 10/18/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation

extension DiscoverManager {
    
    func propertiesFor( id:String) -> [String:[String]] {
        loadTagsDictIfNeeded()
        var tags:[String] = []
        var genders:[String] = []
        self.tags?.forEach({ (args) in
            let (key, value) = args
            if key == "male" {
                if value.contains(id) {
                   genders = ["male"]
                }
            }else{
                if value.contains(id) {
                    if !tags.contains(key) {
                        tags.append(key)
                    }
                }
            }
        })
        return [
            "tags":tags,
            "genders":genders
        ]
    }
    func indexForCategory(_ category:String) -> SortedArray<String>? {
        loadTagsDictIfNeeded()
        
        return self.tags?[category]
    }
    
    func urlStringFor(index:String) -> String{
        return "https://s3.amazonaws.com/screenshop-ordered-matchsticks/byUUID/\(index)1.jpg"
    }

    func isUndisplayable(index:String) -> Bool{
        loadTagsDictIfNeeded()
        let isUndisplayableBool = self.undisplayable?.contains(index) ?? false
        return isUndisplayableBool
    }
    
    private func loadTagsDictIfNeeded() {
        if self.tags == nil {
            
            if let bundleUrl = Bundle.main.url(forResource: "DiscoverTags", withExtension: "json"), let data = try? Data.init(contentsOf: bundleUrl) {
                
                if let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)  {
                    if let json = json as? [String:Any] {
                        if let undisplayableArray = json["undisplayable"] as? [String]{
                            self.undisplayable = Set(undisplayableArray)
                        }
                        if let tagsDict = json["tags"] as? [String:[String]] {
                            var tagsLocal:[String:SortedArray<String>] = [:]
                            tagsDict.forEach({ (args) in
                                let (key, value) = args
                                tagsLocal[key] = SortedArray.init(sorted: value)
                            })
                            self.tags = tagsLocal
                        }
                    }
                    
                }
            }
        }
    }
}
