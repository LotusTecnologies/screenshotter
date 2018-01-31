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
        
        let syteUrl = "https://syte.ai"
        
        let attr = NSMutableAttributedString(string: "Visual search powered by \(syteUrl)")
        
        if let range = attr.string.range(of: syteUrl), let url = URL(string: "https://www.syte.ai/?utm_campaign=screenshop") {
            let a: [String : Any] = [
                NSLinkAttributeName: url
            ]
            attr.addAttributes(a, range: NSRange(range, in: attr.string))
        }
        
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.attributedText = attr
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.scrollsToTop = false
        textView.backgroundColor = .yellow
        view.addSubview(textView)
        textView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: .extendedPadding).isActive = true
        textView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor).isActive = true
        textView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor).isActive = true
//        textView.heightAnchor.constraint(equalToConstant: 300).isActive = true
    }
}
