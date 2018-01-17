//
//  TutorialWelcomeSlideView.swift
//  screenshot
//
//  Created by Corey Werner on 10/17/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit
import Appsee

class TutorialWelcomeSlideView : HelperView {
    private(set) var button = MainButton()
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        titleLabel.attributedText = titleLabelAttributedText
        subtitleLabel.text = "tutorial.welcome.detail".localized
        contentImage = UIImage(named: "TutorialWelcomeScreenshopIcon")
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("tutorial.welcome.start".localized, for: .normal)
        button.backgroundColor = .crazeGreen
        controlView.addSubview(button)
        button.topAnchor.constraint(equalTo: controlView.topAnchor).isActive = true
        button.bottomAnchor.constraint(equalTo: controlView.bottomAnchor).isActive = true
        button.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
    }
    
    // MARK: - Private
    
    // https://useyourloaf.com/blog/using-a-custom-font-with-dynamic-type/
    // TODO: create custom font class
//    func font(forTextStyle textStyle: UIFontTextStyle) -> UIFont {
//        guard let fontDescription = styleDictionary?[textStyle.rawValue],
//            let font = UIFont(name: fontDescription.fontName, size: fontDescription.fontSize) else {
//                return UIFont.preferredFont(forTextStyle: textStyle)
//        }
//
//        let fontMetrics = UIFontMetrics(forTextStyle: textStyle)
//        return fontMetrics.scaledFont(for: font)
//    }
    
    private var titleLabelAttributedText: NSAttributedString {
        let attachment = NSTextAttachment()
        attachment.image = UIImage(named: "Logo20h")?.withRenderingMode(.alwaysTemplate)
        
//        let font = UIFont(name: "DINCondensed-Bold", size: 28) ?? UIFont.systemFont(ofSize: 28)
        
        
        let prefix = "tutorial.welcome.title".localized
        let attachmentString = NSAttributedString(attachment: attachment)
        let attachmentRange = NSMakeRange(prefix.count - 1, attachmentString.length)
        let mutableString = NSMutableAttributedString(string: prefix)
//        , attributes: [
//            NSFontAttributeName: font,
//            NSKernAttributeName: 2.6
//            ])
        
        mutableString.append(attachmentString)
        mutableString.addAttributes([NSForegroundColorAttributeName: UIColor.crazeRed], range: attachmentRange)
        
        return mutableString
    }
}

extension TutorialWelcomeSlideView : TutorialSlideViewProtocol {
    func didEnterSlide() {
        Appsee.startScreen("Tutorial Welcome")
    }
    
    func willLeaveSlide() {
        
    }
}
