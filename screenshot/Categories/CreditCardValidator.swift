//
//  CreditCardValidator.swift
//  screenshot
//
//  Created by Corey Werner on 4/11/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import CreditCardValidator

extension CreditCardValidator {
    static let shared = CreditCardValidator()
    
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
}
