//
//  Label.swift
//  screenshot
//
//  Created by Corey Werner on 3/18/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class Label: UILabel {
    override var text: String? {
        set {
            if font.screenshopFontName != nil, let newValue = newValue {
                attributedText = NSAttributedString(string: newValue)
            }
            else {
                super.text = newValue
            }
        }
        get {
            return super.text
        }
    }
    
    override var attributedText: NSAttributedString? {
        set {
            if let screenshopFontName = font.screenshopFontName, let newValue = newValue {
                let attributedText = NSMutableAttributedString(attributedString: newValue)
                let range = NSMakeRange(0, attributedText.string.count)
                
                attributedText.addAttribute(NSFontAttributeName, value: font, range: range)
                
                let paragraph = NSMutableParagraphStyle()
                paragraph.lineHeightMultiple = screenshopFontName.lineHeightMultiple
                paragraph.alignment = textAlignment
                attributedText.addAttribute(NSParagraphStyleAttributeName, value: paragraph, range: range)
                
                super.attributedText = attributedText
            }
            else {
                super.attributedText = newValue
            }
        }
        get {
            return super.attributedText
        }
    }
    
    override var font: UIFont! {
        didSet {
            if font.screenshopFontName != nil, let text = text, !text.isEmpty {
                self.text = text
            }
        }
    }
    
    override func drawText(in rect: CGRect) {
        var lineHeightMultiple: CGFloat = 0

        if let attributes = attributedText?.attributes(at: 0, effectiveRange: nil) {
            for attribute in attributes {
                if let paragraph = attribute.value as? NSMutableParagraphStyle {
                    lineHeightMultiple = paragraph.lineHeightMultiple
                    break
                }
            }
        }
        
        var rect = rect
        
        if lineHeightMultiple != 0 {
            rect.origin.y = (font.lineHeight / 2) * (1 - lineHeightMultiple)
        }
        
        super.drawText(in: rect)
    }
}
