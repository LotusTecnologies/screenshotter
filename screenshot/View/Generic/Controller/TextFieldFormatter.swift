//
//  TextFieldFormatter.swift
//  screenshot
//
//  Created by Corey Werner on 4/12/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import CreditCardValidator

class TextFieldFormatter {
    enum Field {
        case card
        case cvv
        case zip
    }
    
    let field: Field
    
    private var isObserving = false
    private var previousTextFieldContent: String?
    private var previousSelection: UITextRange?
    
    init(with field: Field) {
        self.field = field
    }
    
    deinit {
        if isObserving {
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    // MARK: Text Field Delegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        previousTextFieldContent = textField.text
        previousSelection = textField.selectedTextRange
        
        let length = (textField.text ?? "").count - range.length + string.count
        let maxLength: Int
        let allowedCharacters: CharacterSet
        
        switch field {
        case .card:
            if !isObserving {
                isObserving = true
                NotificationCenter.default.addObserver(self, selector: #selector(textFieldTextDidChange(_:)), name: .UITextFieldTextDidChange, object: textField)
            }
            
            maxLength = 19 // 16 digits + 3 spaces
            allowedCharacters = .decimalDigits
            
        case .cvv:
            maxLength = 4
            allowedCharacters = .decimalDigits
            
        case .zip:
            maxLength = 9
            allowedCharacters = .decimalDigits
        }
        
        return length <= maxLength && allowedCharacters.isSuperset(of: CharacterSet(charactersIn: string))
    }
    
    @objc fileprivate func textFieldTextDidChange(_ notification: Notification) {
        guard let textField = notification.object as? UITextField else {
            return
        }
        
        reformatAsCardNumber(textField: textField)
    }
    
    // MARK: Credit Card Formatting
    
    fileprivate func reformatAsCardNumber(textField: UITextField) {
        var targetCursorPosition = 0
        var cardNumberWithoutSpaces = ""
        
        if let startPosition = textField.selectedTextRange?.start {
            targetCursorPosition = textField.offset(from: textField.beginningOfDocument, to: startPosition)
        }
        
        if let text = textField.text {
            cardNumberWithoutSpaces = removeNonDigits(string: text, andPreserveCursorPosition: &targetCursorPosition)
        }
        
        let isAmex: Bool = {
            for cardType in CreditCardValidator.shared.types {
                if cardType.name == "Amex" {
                    return CreditCardValidator.shared.validate(string: cardNumberWithoutSpaces, forType: cardType)
                }
            }
            return false
        }()
        
        if (isAmex && cardNumberWithoutSpaces.count > 15) || cardNumberWithoutSpaces.count > 19 {
            textField.text = previousTextFieldContent
            textField.selectedTextRange = previousSelection
            return
        }
        
        textField.text = insertCreditCardSpaces(cardNumberWithoutSpaces, preserveCursorPosition: &targetCursorPosition)
        
        if let targetPosition = textField.position(from: textField.beginningOfDocument, offset: targetCursorPosition) {
            textField.selectedTextRange = textField.textRange(from: targetPosition, to: targetPosition)
        }
    }
    
    fileprivate func removeNonDigits(string: String, andPreserveCursorPosition cursorPosition: inout Int) -> String {
        var digitsOnlyString = ""
        let originalCursorPosition = cursorPosition
        
        for i in 0..<string.count {
            let characterToAdd = string[string.index(string.startIndex, offsetBy: i)]
            
            if characterToAdd >= "0" && characterToAdd <= "9" {
                digitsOnlyString.append(characterToAdd)
            }
            else if i < originalCursorPosition {
                cursorPosition -= 1
            }
        }
        
        return digitsOnlyString
    }
    
    fileprivate func insertCreditCardSpaces(_ string: String, preserveCursorPosition cursorPosition: inout Int) -> String {
        var isAmex = false
        var stringWithAddedSpaces = ""
        let cursorPositionInSpacelessString = cursorPosition
        
        for i in 0..<string.count {
            let needsAmexSpacing = (isAmex && (i == 4 || i == 10 || i == 15))
            let needsNormalSpacing = (!isAmex && i > 0 && (i % 4) == 0)
            
            if needsAmexSpacing || needsNormalSpacing {
                stringWithAddedSpaces.append(" ")
                
                if i < cursorPositionInSpacelessString {
                    cursorPosition += 1
                }
            }
            
            let characterToAdd = string[string.index(string.startIndex, offsetBy:i)]
            stringWithAddedSpaces.append(characterToAdd)
            
            // https://baymard.com/checkout-usability/credit-card-patterns
            if i == 1 && (stringWithAddedSpaces == "34" || stringWithAddedSpaces == "37") {
                isAmex = true
            }
        }
        
        return stringWithAddedSpaces
    }
}
