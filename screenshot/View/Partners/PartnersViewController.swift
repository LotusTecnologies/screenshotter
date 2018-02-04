//
//  PartnersViewController.swift
//  screenshot
//
//  Created by Corey Werner on 1/31/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation

class PartnersViewController : BaseViewController {
    override var title: String? {
        set {}
        get {
            return "partners.title".localized
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let syteVisualString = "https://syte.ai"
        let syteDestinationString = "https://www.syte.ai/?utm_campaign=screenshop"
        let attributedText = NSMutableAttributedString(string: "partners.content".localized(withFormat: syteVisualString))
        
        if let range = attributedText.string.range(of: syteVisualString), let url = URL(string: syteDestinationString) {
            let attribute: [String : Any] = [
                NSLinkAttributeName: url
            ]
            attributedText.addAttributes(attribute, range: NSRange(range, in: attributedText.string))
        }
        
        let textView = TextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = view.backgroundColor
        textView.attributedText = attributedText
        textView.isEditable = false
        textView.isHighlightable = false
        textView.scrollsToTop = false
        textView.textColor = .gray3
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        textView.contentInset = UIEdgeInsets(top: .extendedPadding, left: 0, bottom: .extendedPadding, right: 0)
        view.addSubview(textView)
        textView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        textView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor).isActive = true
        textView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor).isActive = true
        textView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor).isActive = true
    }
}
