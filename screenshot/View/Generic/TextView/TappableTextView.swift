//
//  TappableTextView.swift
//  screenshot
//
//  Created by Corey Werner on 12/19/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

class TappableTextView : UITextView, TappableTextProtocol {
    weak var tappableTextDelegate: TappableTextDelegate?
    private var tappableIndexes: [UInt]?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognizerAction(_:))))
    }
    
    @objc private func tapGestureRecognizerAction(_ tapGesture: UITapGestureRecognizer) {
        guard let tappableIndexes = tappableIndexes, let tappableTextDelegate = tappableTextDelegate else {
            return
        }
        
        var location = tapGesture.location(in: self)
        location.x -= textContainerInset.left
        location.y -= textContainerInset.top
        
        let characterIndex = layoutManager.characterIndex(for: location, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        
        if textStorage.length > characterIndex {
            for tappableIndex in tappableIndexes {
                if attributedText.attribute("\(tappableIndex)", at: characterIndex, effectiveRange: nil) != nil {
                    tappableTextDelegate.tappableText(view: self, tappedTextAt: tappableIndex)
                    break
                }
            }
        }
    }
    
    func applyTappableText(_ texts: [[String : Bool]], with attributes: [String : AnyObject]? = nil) {
        var tappableIndexes: [UInt] = []
        let attributedString = NSMutableAttributedString()
        
        texts.enumerated().forEach { (index: Int, dictionary: [String : Bool]) in
            if let text = dictionary.keys.first, let isTappable = dictionary.values.first {
                var fragmentAttributes: [String : Any]?
                
                if isTappable {
                    tappableIndexes.append(UInt(index))
                    fragmentAttributes = [
                        "\(index)": isTappable,
                        NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue,
                        NSUnderlineColorAttributeName: UIColor.gray7
                    ]
                }
                
                let fragmentAttributedString = NSAttributedString(string: text, attributes: fragmentAttributes)
                attributedString.append(fragmentAttributedString)
            }
        }
        
        if let attributes = attributes {
            attributedString.addAttributes(attributes, range: NSRange(location: 0, length: attributedString.length))
        }
        
        self.tappableIndexes = tappableIndexes
        attributedText = attributedString
    }
}
