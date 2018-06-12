//
//  CheckoutSupportedLocationModel.swift
//  screenshot
//
//  Created by Corey Werner on 4/24/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import Foundation

typealias CheckoutSupportedName = String
typealias CheckoutSupportedCode = String

class CheckoutSupportedCountriesMap {
    private(set) var countryNames = [CheckoutSupportedCode: CheckoutSupportedName]()
    private(set) var countryCodes = [CheckoutSupportedName: CheckoutSupportedCode]()
    
    init() {
        if let path = Bundle.main.path(forResource: "CheckoutSupportedCountries", ofType: "plist"),
            let data = NSDictionary(contentsOfFile: path) as? [CheckoutSupportedName: CheckoutSupportedCode]
        {
            countryCodes = data
            
            var tempCountryNames = [CheckoutSupportedCode: CheckoutSupportedName]()
            
            for country in data {
                tempCountryNames[country.value] = country.key
            }
            
            countryNames = tempCountryNames
        }
    }
}

class CheckoutSupportedStatesMap {
    private(set) var stateNames = [CheckoutSupportedCode: CheckoutSupportedName]()
    private(set) var stateCodes = [CheckoutSupportedName: CheckoutSupportedCode]()
    
    init() {
        if let path = Bundle.main.path(forResource: "CheckoutSupportedStates", ofType: "plist"),
            let data = NSDictionary(contentsOfFile: path) as? [CheckoutSupportedName: CheckoutSupportedCode]
        {
            stateCodes = data
            
            var tempStateNames = [CheckoutSupportedCode: CheckoutSupportedName]()
            
            for state in data {
                tempStateNames[state.value] = state.key
            }
            
            stateNames = tempStateNames
        }
    }
}

//class CheckoutSupportedProvincesMap {
//
//}
