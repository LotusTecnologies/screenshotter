//
//  CreditCardTextFieldController.swift
//  screenshot
//
//  Created by Corey Werner on 4/12/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class CreditCardTextFieldController {
    enum Field {
        case card
        case cvv
        case zip
    }
    
    let field: Field
    
    init(with field: Field) {
        self.field = field
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        switch field {
        case .card:
            return true
        case .cvv:
            return cvv(textField: textField, shouldChangeCharactersIn: range, replacementString: string)
        case .zip:
            return zip(textField: textField, shouldChangeCharactersIn: range, replacementString: string)
        }
    }
    
    fileprivate func cvv(textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let length = (textField.text ?? "").count - range.length + string.count
        let maxLength = 4
        let isReturnKey = string.range(of: "\n") != nil
        
        return length <= maxLength || isReturnKey
    }
    
    fileprivate func zip(textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let length = (textField.text ?? "").count - range.length + string.count
        let maxLength = 9
        let isReturnKey = string.range(of: "\n") != nil
        
        return length <= maxLength || isReturnKey
    }
}
