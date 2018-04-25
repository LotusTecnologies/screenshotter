//
//  Form.swift
//  screenshot
//
//  Created by Corey Werner on 3/26/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

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
    
    var hasRequiredFields: Bool {
        if let sections = sections {
            for section in sections {
                guard let rows = section.rows else {
                    continue
                }
                
                for row in rows {
                    if row.isRequired && (row.value == nil || row.value!.isEmpty) {
                        return false
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
    var placeholder: String?
    var value: String?
    
    var isRequired = true
    var isValid: Bool {
        guard isRequired else {
            return true
        }
        
        guard let value = value, !value.isEmpty, let validRegex = validRegex else {
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
            return "[\\d ]{15,19}"
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
            return "[\\d]{3,4}"
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
            return "[\\d]{2}\\/[\\d]{4}"
        }
    }
    
    class Number: Text {
        fileprivate override var validRegex: String? {
            return "[\\d]+"
        }
    }
    
    class Phone: Text {
        fileprivate override var validRegex: String? {
            return "\\+?[\\d-]{10,14}"
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
            return "[\\d]{5,9}"
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
