//
//  Form.swift
//  screenshot
//
//  Created by Corey Werner on 3/26/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import CreditCardValidator

class Form {
    var sections: [FormSection]? {
        didSet {
            generateMap()
        }
    }
    var map: [Int: FormRow]?
    
    convenience init(with sections: [FormSection]) {
        self.init()
        defer {
            self.sections = sections
        }
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
    
    private func generateMap() {
        var map: [Int: FormRow] = [:]
        
        sections?.forEach({ section in
            section.rows?.forEach({ row in
                if let id = row.id {
                    map[id] = row
                }
            })
        })
        
        self.map = map.isEmpty ? nil : map
    }
    
    var hasValidFields: Bool {
        if let sections = sections {
            for section in sections {
                guard let rows = section.rows else {
                    continue
                }
                
                for row in rows {
                    if row.isRequired {
                        let value = (row.value?.isEmpty ?? true) ? nil : row.value
                        let placeholder = (row.placeholder?.isEmpty ?? true) ? nil : row.placeholder
                        
                        if (value == nil && placeholder == nil) ||
                            (value != nil && !row.isValid()) ||
                            (value == nil && placeholder != nil && !row.isValid())
                        {
                            return false
                        }
                    }
                }
            }
        }
        
        return true
    }
}

class FormSection {
    var title: String?
    var rows: [FormRow]?
    
    convenience init(with formRows: [FormRow]) {
        self.init()
        rows = formRows
    }
}

class FormRow: NSObject {
    var id: Int?
    var title: String?
    var placeholder: String?
    var value: String?
    
    var isRequired = true
    func isValid() -> Bool {
        guard isRequired else {
            return true
        }
        
        var _value: String?
        
        if let value = value, !value.isEmpty {
            _value = value
        }
        else if let placeholder = placeholder, !placeholder.isEmpty {
            _value = placeholder
        }
        
        guard let value = _value, !value.isEmpty, let validRegex = validRegex else {
            return false
        }
        
        do {
            let regex = try NSRegularExpression(pattern: validRegex)
            let results = regex.matches(in: value, range: NSRange(value.startIndex..., in: value))
            return results.count > 0
        }
        catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return false
        }
    }
    fileprivate var validRegex: String? {
        return nil
    }
    
    var isVisible = true
    var condition: FormCondition? {
        willSet {
            let index = condition?.formRow.linkedConditions.index(where: { formLinkedCondition -> Bool in
                return formLinkedCondition.formRow == self
            })
            
            if let index = index {
                condition?.formRow.linkedConditions.remove(at: index)
            }
        }
        didSet {
            if let condition = condition {
                let linkedCondition = FormLinkedCondition(display: self, whenHasValue: condition.value)
                condition.formRow.linkedConditions.append(linkedCondition)
            }
        }
    }
    private(set) var linkedConditions: [FormLinkedCondition] = []
    
    convenience init(_ id: Int) {
        self.init()
        self.id = id
    }
}

extension FormRow {
    class Card: Text {
        fileprivate override var validRegex: String? {
            return "[0-9* ]{15,19}"
        }
        
        override func isValid() -> Bool {
            var isValid = super.isValid()
            
            if isValid, let number = value, !number.isEmpty {
                isValid = CreditCardValidator().validate(string: number)
            }
            
            return isValid
        }
    }
    
    class Checkbox: FormRow {
        override init() {
            super.init()
            value = Checkbox.value(for: false)
        }
        
        // The value should be stored as a "1" or a "0"
        static func bool(for value: String?) -> Bool {
            return NSString(string: value ?? "0").boolValue
        }
        
        static func value(for bool: Bool?) -> String {
            return NSNumber(value: bool ?? false).stringValue
        }
        
        fileprivate override var validRegex: String? {
            return ".+"
        }
    }
    
    class CVV: Number {
        fileprivate override var validRegex: String? {
            return "[0-9]{3,4}"
        }
    }
    
    class Email: Text {
        fileprivate override var validRegex: String? {
            return "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        }
    }
    
    class Expiration: FormRow {
        typealias Date = (month: Int, year: Int)
        
        // The value should be stored as "mm/yyyy"
        static func date(for value: String?) -> Date? {
            guard let components = value?.split(separator: "/"),
                components.count == 2,
                let month = Int(components[0]),
                let year = Int(components[1])
                else {
                    return nil
            }
            
            return Date(month: month, year: year)
        }
        
        static func value(for date: Date?) -> String? {
            guard let month = date?.month, let year = date?.year else {
                return nil
            }
            
            if month > 0 && year > 0 {
                return String(format: "%02d/%d", month, year)
            }
            else if month > 0 {
                return String(format: "%02d", month)
            }
            else {
                return "\(year)"
            }
        }
        
        static func isYear(_ value: Int) -> Bool {
            return value / 1000 > 1
        }
        
        fileprivate override var validRegex: String? {
            return "[0-9]{2}\\/[0-9]{4}"
        }
    }
    
    class Number: Text {
        fileprivate override var validRegex: String? {
            return "[0-9]+"
        }
    }
    
    class Phone: Text {
        fileprivate override var validRegex: String? {
            return "\\+?[0-9-() ]{10,15}"
        }
    }
    
    class Selection: FormRow {
        var options: [String]?
        
        fileprivate override var validRegex: String? {
            return ".+"
        }
    }
    
    class Text: FormRow {
        fileprivate override var validRegex: String? {
            return ".+"
        }
    }
    
    class Zip: Number {
        fileprivate override var validRegex: String? {
            return "[0-9]{5,9}"
        }
    }
}

struct FormCondition {
    let formRow: FormRow
    let value: String
    
    init(displayWhen formRow: FormRow, hasValue value: String) {
        self.formRow = formRow
        self.value = value
    }
}

struct FormLinkedCondition {
    let formRow: FormRow
    let value: String
    
    init(display formRow: FormRow, whenHasValue value: String) {
        self.formRow = formRow
        self.value = value
    }
}