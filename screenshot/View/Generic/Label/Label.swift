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
            if font.screenshopFontName != nil, numberOfLines != 1, let newValue = newValue {
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
            if let screenshopFontName = font.screenshopFontName, numberOfLines != 1, let newValue = newValue {
                let attributedText = NSMutableAttributedString(attributedString: newValue)
                let range = NSMakeRange(0, attributedText.string.count)
                
                attributedText.addAttribute(NSAttributedStringKey.font, value: font, range: range)
                
                let paragraph = NSMutableParagraphStyle()
                paragraph.lineHeightMultiple = screenshopFontName.lineHeightMultiple
                paragraph.alignment = textAlignment
                attributedText.addAttribute(NSAttributedStringKey.paragraphStyle, value: paragraph, range: range)
                
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
            syncTextIfNeeded()
        }
    }
    
    override var numberOfLines: Int {
        didSet {
            syncTextIfNeeded()
        }
    }
    
    fileprivate func syncTextIfNeeded() {
        if font.screenshopFontName != nil, numberOfLines != 1, let text = text, !text.isEmpty {
            self.text = text
        }
    }
    
    override func drawText(in rect: CGRect) {
        var rect = rect
        
        // When numberOfLines is 1, adjusting the draw text rect is ignored
        if numberOfLines != 1 {
            var lineHeightMultiple: CGFloat = 0
            
            if let screenshopFontName = font.screenshopFontName {
                lineHeightMultiple = screenshopFontName.lineHeightMultiple
            }
            else if let attributes = attributedText?.attributes(at: 0, effectiveRange: nil) {
                for attribute in attributes {
                    if let paragraph = attribute.value as? NSMutableParagraphStyle {
                        lineHeightMultiple = paragraph.lineHeightMultiple
                        break
                    }
                }
            }
            
            if lineHeightMultiple != 0 {
                rect.origin.y = (font.lineHeight / 2) * (1 - lineHeightMultiple)
            }
        }
        
        super.drawText(in: rect)
    }
    
    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        
        if let font = font {
            size.height = max(size.height, font.lineHeight)
        }
        
        return size
    }
}
