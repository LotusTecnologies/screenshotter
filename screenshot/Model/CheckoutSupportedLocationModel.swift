//
//  CheckoutSupportedLocationModel.swift
//  screenshot
//
//  Created by Corey Werner on 4/24/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation

typealias CheckoutSupportedName = String
typealias CheckoutSupportedCode = String

class CheckoutSupportedCountriesMap {
    private(set) var countries: [CheckoutSupportedName: CheckoutSupportedCode] = [:]
    
    init() {
        if let path = Bundle.main.path(forResource: "CheckoutSupportedCountries", ofType: "plist"),
            let data = NSDictionary(contentsOfFile: path) as? [CheckoutSupportedName: CheckoutSupportedCode]
        {
            countries = data
        }
    }
}

class CheckoutSupportedStatesMap {
    private(set) var states: [CheckoutSupportedName: CheckoutSupportedCode] = [:]
    
    init() {
        if let path = Bundle.main.path(forResource: "CheckoutSupportedStates", ofType: "plist"),
            let data = NSDictionary(contentsOfFile: path) as? [CheckoutSupportedName: CheckoutSupportedCode]
        {
            states = data
        }
    }
}

//class CheckoutSupportedProvincesMap {
//
//}
