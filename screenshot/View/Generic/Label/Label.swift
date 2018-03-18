//
//  Label.swift
//  screenshot
//
//  Created by Corey Werner on 3/18/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class Label: UILabel {
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
