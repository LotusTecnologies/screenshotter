//
//  CurrencyModel.swift
//  screenshot
//
//  Created by Corey Werner on 11/27/17.
//  Copyright (c) 2017 crazeapp. All rights reserved.
//

import Foundation

class CurrencyMap : NSObject {
    private(set) var items: [CurrencyItem] = []
    
    override init() {
        super.init()
        
        if let path = Bundle.main.path(forResource: "ISO4217", ofType: "plist"),
            let data = NSArray(contentsOfFile: path) as NSArray? as? [[String : Any]]
        {
            items = data.map { item in
                return CurrencyItem(withItem: item)
            }
        }
    }
    
    func index(forCode code: String) -> Int? {
        return items.index { item -> Bool in
            return item.code == code
        }
    }
    
    static var autoCode: String {
        return "XXX"
    }
}

struct CurrencyItem {
    private var item: [String : Any]
    
    init(withItem item: [String : Any]) {
        self.item = item
    }
    
    var code: String {
        return item["code"] as? String ?? ""
    }
    
    var currency: String {
        return item["title"] as? String ?? ""
    }
}
