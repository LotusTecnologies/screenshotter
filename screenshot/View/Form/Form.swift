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
    
    func indexPath(for formRow: FormRow) -> IndexPath? {
        if let sections = sections {
            var sectionIndex: Int?
            var rowIndex: Int?
            
            for i in sections.startIndex...sections.endIndex {
                if let j = sections[i].rows?.index(where: { $0 == formRow }) {
                    sectionIndex = i
                    rowIndex = j
                    break
                }
            }
            
            if let rowIndex = rowIndex, let sectionIndex = sectionIndex {
                return IndexPath(row: rowIndex, section: sectionIndex)
            }
        }
        
        return nil
    }
}

class FormSection {
    var title: String?
    var rows: [FormRow]?
}

class FormRow: NSObject {
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
