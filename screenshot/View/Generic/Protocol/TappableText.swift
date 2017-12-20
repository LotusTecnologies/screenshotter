//
//  TappableText.swift
//  screenshot
//
//  Created by Corey Werner on 12/19/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

protocol TappableTextProtocol : NSObjectProtocol {
    weak var tappableTextDelegate: TappableTextDelegate? { get set }
    
    // This will set the attributedText property. The dictionary's
    // string is a text fragment while the number is a boolean. If
    // @YES then the text fragment becomes tappable. Note that for
    // the best tapping results, a space key ' ', should always be
    // inserted before and after tappable text fragments.
    func applyTappableText(_ texts: [[String : Bool]], with attributes: [String : AnyObject]?)
}

protocol TappableTextDelegate : NSObjectProtocol {
    // The index is from the order used with -applyTappableText:
    func tappableText(view: TappableTextProtocol, tappedTextAt index: UInt)
}
