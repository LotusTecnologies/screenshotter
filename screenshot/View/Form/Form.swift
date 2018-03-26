//
//  Form.swift
//  screenshot
//
//  Created by Corey Werner on 3/26/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

protocol FormRow {
    var placeholder: String? { get set }
}

class Form {
    let rows: [FormRow]
    
    init(with rows: [FormRow]) {
        self.rows = rows
    }
    
    class Text: FormRow {
        var placeholder: String?
        var value: String?
    }
    
    class Email: Text {
        
    }
    
    class Phone: Text {
        
    }
    
    class Number: Text {
        
    }
    
    class Card: Text {
        
    }
    
    class Selection: FormRow {
        var placeholder: String?
        var value: String?
    }
    
    class Date: FormRow {
        var placeholder: String?
        var value: (month: UInt, year: UInt)?
    }
}
