//
//  PartnersViewController.swift
//  screenshot
//
//  Created by Corey Werner on 1/31/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import Foundation
import UIKit

class PartnersViewController : BaseViewController {
    override var title: String? {
        set {}
        get {
            return "partners.title".localized
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let attributedText:NSAttributedString = MessageInboxCollectionViewCell.taggedStringForAttributedString(taggedString: "this is a text <crazeRed>20% off</crazeRed> and can also be <crazeGreen>green</crazeGreen> or <underline>underline</underline> and <bold>bold</bold> or <crazeRed><underline>many at once</underline><crazeRed>   it can also support any color <purple>purple</purple> that is supported by css or  <#aabbcc>hex color</#aabbcc> it can display / find also  ")
        
            
            /*{
            let syteVisualString = "syte.ai"
            let syteDestinationString = "https://www.syte.ai/?utm_campaign=screenshop"
            
            let text = "partners.content".localized(withFormat: syteVisualString)
            if let range = text.range(of: syteVisualString), let url = URL(string: syteDestinationString) {
                let attribute: [NSAttributedStringKey : Any] = [
                    NSAttributedStringKey.link: url
                ]
                let mutableString = NSMutableAttributedString.init(string: text)
                mutableString.addAttributes(attribute, range: NSRange(range, in: text))
                return mutableString
            }else{
                return  NSAttributedString(string:text)
            }
        }()*/
        
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = view.backgroundColor
        textView.attributedText = attributedText
        textView.isEditable = false
        textView.scrollsToTop = false
        textView.textColor = .gray3
        textView.font = .screenshopFont(.hindLight, textStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        textView.contentInset = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
        view.addSubview(textView)
        textView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        textView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        textView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        textView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }
}
