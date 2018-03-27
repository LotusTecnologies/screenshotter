//
//  Form.swift
//  screenshot
//
//  Created by Corey Werner on 3/26/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class Form {
    var sections: [FormSection]?
    
    convenience init(with sections: [FormSection]) {
        self.init()
        self.sections = sections
    }
}

class FormSection {
    var title: String?
    var rows: [FormRow]?
}

class FormRow {
    var placeholder: String?
}

extension FormRow {
    class Card: Text {
        
    }
    
    class Date: FormRow {
        var value: (month: UInt, year: UInt)?
    }
    
    class Email: Text {
        
    }
    
    class Number: Text {
        
    }
    
    class Phone: Text {
        
    }
    
    class Selection: FormRow {
        var value: String?
        var options: [String]?
    }
    
    class Text: FormRow {
        var value: String?
    }
}
