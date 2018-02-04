//
//  TextView.swift
//  screenshot
//
//  Created by Corey Werner on 2/4/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation

class TextView : UITextView {
    var isHighlightable = true
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if isHighlightable {
            return super.point(inside: point, with: event)
        }
        else {
            guard let position = closestPosition(to: point) else {
                return false
            }
            
            guard let range = tokenizer.rangeEnclosingPosition(position, with: .character, inDirection: UITextLayoutDirection.left.rawValue) else {
                return false
            }
            
            let startIndex = offset(from: beginningOfDocument, to: range.start)
            
            return attributedText.attribute(NSLinkAttributeName, at: startIndex, effectiveRange: nil) != nil
        }
    }
}
