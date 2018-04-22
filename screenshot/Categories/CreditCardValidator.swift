//
//  CreditCardValidator.swift
//  screenshot
//
//  Created by Corey Werner on 4/11/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import CreditCardValidator

enum CreditCardBrand {
    case Amex
    case DinersClub
    case Discover
    case JCB
    case Mastercard
    case Visa
}

extension CreditCardValidator {
    static let shared = CreditCardValidator()
    
    // MARK: Card
    
    func isAmex(cardNumber: String) -> Bool {
        // https://baymard.com/checkout-usability/credit-card-patterns
        return ["34", "37"].contains(cardNumber.prefix(2))
    }
    
    // MARK: Expiration
    
    private static let calendar = Calendar(identifier: .gregorian)
    
    private static var currentDates: DateComponents {
        return calendar.dateComponents([.year, .month], from: Date())
    }
    
    static var currentMonth: Int {
        return currentDates.month!
    }
    
    static var currentYear: Int {
        return currentDates.year!
    }
    
    /// month = xx; year = xxxx
    func isExpired(month: Int, year: Int) -> Bool {
        let current = CreditCardValidator.currentDates
        
        guard let currentMonth = current.month, let currentYear = current.year else {
            return false
        }
        
        return currentYear > year || (currentYear == year && currentMonth >= month)
    }
    
    // MARK: Number
    
    func formatNumber(_ number: String, includedSpace: ((Int)->())? = nil) -> String {
        let amex = isAmex(cardNumber: number)
        var formattedNumber = ""
        
        for i in 0..<number.count {
            let needsAmexSpacing = (amex && (i == 4 || i == 10 || i == 15))
            let needsNormalSpacing = (!amex && i > 0 && (i % 4) == 0)
            
            if needsAmexSpacing || needsNormalSpacing {
                formattedNumber.append(" ")
                
                includedSpace?(i)
            }
            
            let characterToAdd = number[number.index(number.startIndex, offsetBy:i)]
            formattedNumber.append(characterToAdd)
        }
        
        return formattedNumber
    }
    
    /// Create a number which replaces all digits but the last component with a *
    func secureNumber(_ number: String?) -> String? {
        guard let number = number, !number.isEmpty else {
            return nil
        }
        
        let formattedNumber = formatNumber(number.replacingOccurrences(of: " ", with: ""))
        var formattedNumberComponents = formattedNumber.split(separator: " ")
        let secureComponentsCount = formattedNumberComponents.count - 1
        
        for i in 0..<secureComponentsCount {
            let number = formattedNumberComponents[i]
            let secureNumber = number.replacingOccurrences(of: ".", with: "*", options: .regularExpression)
            formattedNumberComponents[i] = Substring(secureNumber)
        }
        
        return formattedNumberComponents.joined(separator: " ")
    }
    
    /// Only diplsay the last digits of a card
    func lastComponentNumber(_ number: String) -> String {
        return ""
    }
}
