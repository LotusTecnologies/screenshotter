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
    func applyTappableText(_ texts: [[String : UInt]], with attributes: [String : AnyObject]?)
}

protocol TappableTextDelegate : NSObjectProtocol {
    // The index is from the order used with -applyTappableText:
    func tappableText(view: TappableTextProtocol, tappedTextAt index: UInt)
}

class __TappableTextView : UITextView, TappableTextProtocol {
    weak var tappableTextDelegate: TappableTextDelegate?
    private var tappableIndexes: [UInt]?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognizerAction(_:))))
    }
    
    func tapGestureRecognizerAction(_ tapGesture: UITapGestureRecognizer) {
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
    
    func applyTappableText(_ texts: [[String : UInt]], with attributes: [String : AnyObject]? = nil) {
//        NSMutableArray *tappableIndexes = [NSMutableArray array];
//        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
//        
//        for (NSUInteger i = 0; i < texts.count; i++) {
//            NSDictionary *dictionary = texts[i];
//            NSString *text = [[dictionary allKeys] firstObject];
//            BOOL isTappable = [[[dictionary allValues] firstObject] boolValue];
//            NSDictionary *fragmentAttributes;
//            
//            if (isTappable) {
//                [tappableIndexes addObject:@(i)];
//                fragmentAttributes = @{[NSString stringWithFormat:@"%lu", (unsigned long)i]: @(isTappable),
//                    NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
//                    NSUnderlineColorAttributeName: [UIColor gray7]
//                };
//            }
//            
//            NSAttributedString *fragmentAttributedString = [[NSAttributedString alloc] initWithString:text attributes:fragmentAttributes];
//            [attributedString appendAttributedString:fragmentAttributedString];
//        }
//        
//        if (attributes) {
//            [attributedString addAttributes:attributes range:NSMakeRange(0, attributedString.length)];
//        }
//        
//        self.tappableIndexes = tappableIndexes;
//        self.attributedText = attributedString;
    }
}
