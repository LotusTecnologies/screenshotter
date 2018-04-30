//
//  TutorialWelcomeSlideViewController.swift
//  screenshot
//
//  Created by Corey Werner on 10/17/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit
import Appsee
protocol  TutorialWelcomeSlideViewControllerDelegate : class{
    func tutorialWelcomeSlideViewControllerDidComplete(_ viewController:TutorialWelcomeSlideViewController)
}
class TutorialWelcomeSlideViewController : UIViewController {
    private(set) var button = MainButton()
    
    weak var delegate:TutorialWelcomeSlideViewControllerDelegate?
    
    let helperView = HelperView()
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        helperView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(helperView)
        helperView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        helperView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        helperView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        helperView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        
        helperView.layoutMargins = {
            var extraTop = CGFloat(0)
            var extraBottom = CGFloat(0)
            
            if !UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory {
                if UIDevice.is812h || UIDevice.is736h {
                    extraTop = .extendedPadding
                    extraBottom = .extendedPadding
                    
                } else if UIDevice.is667h {
                    extraTop = .padding
                    extraBottom = .padding
                }
            }
            
            let paddingX: CGFloat = .padding
            
            
            return UIEdgeInsets(top: .padding + extraTop, left: paddingX, bottom: .padding + extraBottom, right: paddingX)
        }()
        
        
        helperView.titleLabel.attributedText = titleLabelAttributedText
        helperView.subtitleLabel.text = "tutorial.welcome.detail".localized
        helperView.contentImage = UIImage(named: "TutorialWelcomeScreenshopIcon")
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("tutorial.welcome.start".localized, for: .normal)
        button.backgroundColor = .crazeGreen
        helperView.controlView.addSubview(button)
        button.topAnchor.constraint(equalTo: helperView.controlView.topAnchor).isActive = true
        button.bottomAnchor.constraint(equalTo: helperView.controlView.bottomAnchor).isActive = true
        button.centerXAnchor.constraint(equalTo: helperView.contentView.centerXAnchor).isActive = true
        
        button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        
    }
    @objc func buttonPressed(_ sender:Any) {
        self.delegate?.tutorialWelcomeSlideViewControllerDidComplete(self)
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
        mutableString.addAttributes([NSAttributedStringKey.foregroundColor: UIColor.crazeRed], range: attachmentRange)
        
        return mutableString
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Appsee.startScreen("Tutorial Welcome")
    }
}

