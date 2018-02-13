//
//  TappableTextView.swift
//  screenshot
//
//  Created by Corey Werner on 12/19/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

fileprivate struct TappableLink {
    let range: NSRange
    let url: URL
}

class TappableTextView : UITextView {
    private var tappableLinks: [TappableLink] = []
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognizerAction(_:))))
    }
    
    @objc private func tapGestureRecognizerAction(_ tapGesture: UITapGestureRecognizer) {
        guard tappableLinks.count > 0 else {
            return
        }
        
        var location = tapGesture.location(in: self)
        location.x -= textContainerInset.left
        location.y -= textContainerInset.top
        
        let characterIndex = layoutManager.characterIndex(for: location, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        
        if textStorage.length > characterIndex {
            for tappableLink in tappableLinks {
                let range = tappableLink.range
                
                if range.location <= characterIndex && range.location + range.length > characterIndex {
                    let shouldOpen = delegate?.textView!(self, shouldInteractWith: tappableLink.url, in: range, interaction: .invokeDefaultAction)
                    
                    if shouldOpen == true {
                        openURL(tappableLink.url)
                    }
                    break
                }
            }
        }
    }
    
    override var attributedText: NSAttributedString! {
        didSet {
            let range = NSRange(location: 0, length: attributedText.length)
            tappableLinks.removeAll()
            
            attributedText.enumerateAttribute(NSLinkAttributeName, in: range, options: .longestEffectiveRangeNotRequired) { value, range, stop in
                guard let value = value else {
                    return
                }
                
                let link: URL?
                
                if let string = value as? NSString {
                    link = URL(string: string as String)
                }
                else if let string = value as? String {
                    link = URL(string: string)
                }
                else if let url = value as? NSURL {
                    link = url as URL
                }
                else if let url = value as? URL {
                    link = url
                }
                else {
                    link = nil
                }
                
                if let link = link {
                    self.tappableLinks.append(TappableLink(range: range, url: link))
                }
            }
        }
    }
    
    fileprivate func openURL(_ url: URL) {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
