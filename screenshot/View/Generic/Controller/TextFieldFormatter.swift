//
//  TextFieldFormatter.swift
//  screenshot
//
//  Created by Corey Werner on 4/12/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import CreditCardValidator
import PhoneNumberKit

class TextFieldFormatter {
    enum Field {
        case card
        case cvv
        case phone
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
                NotificationCenter.default.addObserver(self, selector: #selector(cardTextFieldTextDidChange(_:)), name: .UITextFieldTextDidChange, object: textField)
            }
            
            maxLength = 19 // 16 digits + 3 spaces
            allowedCharacters = .decimalDigits
            
        case .cvv:
            maxLength = 4
            allowedCharacters = .decimalDigits
            
        case .phone:
            if !isObserving {
                isObserving = true
                NotificationCenter.default.addObserver(self, selector: #selector(phoneTextFieldTextDidChange(_:)), name: .UITextFieldTextDidChange, object: textField)
            }
            
            maxLength = 14 // 10 digits + 4 extra characters
            allowedCharacters = .decimalDigits
            
        case .zip:
            maxLength = 9
            allowedCharacters = .decimalDigits
        }
        
        return length <= maxLength && allowedCharacters.isSuperset(of: CharacterSet(charactersIn: string))
    }
    
    // MARK: Credit Card Formatting
    
    @objc fileprivate func cardTextFieldTextDidChange(_ notification: Notification) {
        guard let textField = notification.object as? UITextField else {
            return
        }
        
        reformatAsCardNumber(textField: textField)
    }
    
    fileprivate func reformatAsCardNumber(textField: UITextField) {
        var targetCursorPosition = 0
        var cardNumberWithoutSpaces = ""
        
        if let startPosition = textField.selectedTextRange?.start {
            targetCursorPosition = textField.offset(from: textField.beginningOfDocument, to: startPosition)
        }
        
        if let text = textField.text {
            cardNumberWithoutSpaces = removeNonDigits(string: text, andPreserveCursorPosition: &targetCursorPosition)
        }
        
        let isAmex = CreditCardValidator.shared.isAmex(cardNumber: cardNumberWithoutSpaces)
        
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
        let cursorPositionInSpacelessString = cursorPosition
        var excapingCursorPosition = cursorPosition
        
        let formattedNumber = CreditCardValidator.shared.formatNumber(string) { i in
            if i < cursorPositionInSpacelessString {
                excapingCursorPosition += 1
            }
        }
        
        cursorPosition = excapingCursorPosition
        
        return formattedNumber
    }
    
    // MARK: Phone Number Formatting
    
    @objc fileprivate func phoneTextFieldTextDidChange(_ notification: Notification) {
        guard let textField = notification.object as? UITextField, let text = textField.text else {
            return
        }
        
        textField.text = PartialFormatter().formatPartial(text)
    }
}
