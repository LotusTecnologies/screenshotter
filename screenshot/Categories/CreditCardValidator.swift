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
    
    /// month = xx; year = xxxx
    func isExpired(month: Int, year: Int) -> Bool {
        let current = CreditCardValidator.calendar.dateComponents([.year, .month], from: Date())
        
        guard let currentMonth = current.month, let currentYear = current.year else {
            return false
        }
        
        return currentYear > year || (currentYear == year && currentMonth >= month)
    }
}
