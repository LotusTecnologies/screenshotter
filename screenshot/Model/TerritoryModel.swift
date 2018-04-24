//
//  TerritoryModel.swift
//  screenshot
//
//  Created by Corey Werner on 4/24/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation

class USStatesMap {
    typealias Name = String
    typealias Abbreviation = String
    
    private(set) var states: [Name: Abbreviation] = [:]
    
    init() {
        if let path = Bundle.main.path(forResource: "USStates", ofType: "plist"),
            let data = NSDictionary(contentsOfFile: path) as? [Name: Abbreviation]
        {
            states = data
        }
    }
}
