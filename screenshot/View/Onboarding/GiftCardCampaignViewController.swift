//
//  GiftCardCampaignViewController.swift
//  screenshot
//
//  Created by Jonathan Rose on 4/26/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit
protocol GiftCardCampaignViewControllerDelegate : class {
    func giftCardCampaignViewControllerDidSkip(_ viewController:GiftCardCampaignViewController)
    func giftCardCampaignViewControllerDidContinue(_ viewController:GiftCardCampaignViewController);
}


class GiftCardCampaignViewController: UIViewController {

    weak var delegate:GiftCardCampaignViewControllerDelegate?
    
    let campaign = CampaignDescription(
        headline: "2018_05_01_campaign.headline".localized,
        message: "2018_05_01_campaign.message".localized,
        buttonText: "2018_05_01_campaign.button".localized,
        skipText: "2018_05_01_campaign.skip".localized)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let sizes:ElementSizes = {
            if UIDevice.is320w {
                return ElementSizes(
                    headlineFontSize: 20,
                    messageFontSize: 15,
                    skipTextFontSize: 12,
                    aboveSkipPad: 10,
                    belowSkipPad: 20)
            }else{
                return ElementSizes(
                    headlineFontSize: 30,
                    messageFontSize: 23,
                    skipTextFontSize: 15,
                    aboveSkipPad: 30,
                    belowSkipPad: 60)
            }
          
        }()
        
        
        self.view.backgroundColor = .white
        
        let topBackground = UIView()
        topBackground.backgroundColor = .white

        let topLine = UIImageView.init(image: UIImage(named: "BrandGradientBorder"))
        topLine.contentMode = .scaleToFill
        
        let bottomBackground = UIImageView.init(image: UIImage.init(named: "BrandConfettiContentBackground"))
        
        let backgroundLine = UIView()
        backgroundLine.backgroundColor = .gray9
        
        let giftCardImage = UIImageView.init(image: UIImage.init(named: "giftCard25USD"))
        giftCardImage.contentMode = .scaleAspectFit
        
        let headline = UILabel.init()
        headline.text = self.campaign.headline
        headline.textAlignment = .center
        headline.textColor = .gray4
        headline.font = UIFont.screenshopFont(.hindMedium, size: sizes.headlineFontSize)
        headline.numberOfLines = 0
        
        
        let message = UILabel.init()
        message.text = self.campaign.message
        message.textAlignment = .center
        message.textColor = .gray4
        message.font = UIFont.screenshopFont(.hindMedium, size: sizes.messageFontSize)
        message.minimumScaleFactor = 0.1
        message.numberOfLines = 0
        
        let separatorLine = UIView()
        separatorLine.backgroundColor = .gray9
        
        
        
        let button = MainButton()
        button.setTitle(self.campaign.buttonText, for: .normal)
        button.backgroundColor = .crazeGreen
        button.addTarget(self, action: #selector(continueAction(_:)), for: .touchUpInside)
        
        let skip = UIButton()
        let underlineString = NSAttributedString.init(string: self.campaign.skipText, attributes:
            [NSAttributedStringKey.underlineStyle : NSUnderlineStyle.styleSingle.rawValue,
             NSAttributedStringKey.underlineColor : UIColor.gray4,
             NSAttributedStringKey.foregroundColor: UIColor.gray4])
        skip.contentEdgeInsets = UIEdgeInsets(top: 5, left: .padding, bottom: 5, right: .padding)
        skip.titleLabel?.font = UIFont.screenshopFont(.hind, size: sizes.skipTextFontSize)
        skip.setAttributedTitle(underlineString, for: .normal)
        skip.addTarget(self, action: #selector(skipAction(_:)), for: .touchUpInside)
        
        
        
        //layout
        let container = self.view!
        
        let views = ["topLine":topLine,
                     "topBackground":topBackground,
                     "backgroundLine":backgroundLine,
                     "bottomBackground":bottomBackground,
                     "headline":headline,
                     "giftCardImage":giftCardImage,
                     "skip":skip,
                     "button":button,
                     "message":message,
                     "separatorLine":separatorLine]
        
        //everything is centeredX (don't use dictionary - order is important)
        [topLine, topBackground, backgroundLine, bottomBackground, headline, giftCardImage, skip, button, message, separatorLine].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview($0)
            $0.centerXAnchor.constraint(equalTo: container.centerXAnchor).isActive = true
        }
        
        //full width objects:
        [topLine, topBackground, backgroundLine, bottomBackground].forEach {
            $0.widthAnchor.constraint(equalTo: container.widthAnchor).isActive = true
        }
        
        // objects that respect margin:
        [ headline, skip, message].forEach {
            let padding:CGFloat = 30
            $0.widthAnchor.constraint(equalTo: container.widthAnchor, constant: -2*padding).isActive = true
        }
        
        //Custom width:
        separatorLine.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: 0.25).isActive = true

        //background V layout
        container.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[topLine(6)][topBackground][backgroundLine(1)][bottomBackground]|", options: [], metrics: nil, views: views))
        
        topBackground.heightAnchor.constraint(equalTo: container.heightAnchor, multiplier: 0.27).isActive = true
        
        
        //forground V layout:
//        container.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[giftCardImage][message][separatorLine(2)][button]-aboveSkipPad-[skip]-belowSkipPad-|", options: [], metrics: ["aboveSkipPad":sizes.aboveSkipPad, "belowSkipPad":sizes.belowSkipPad], views: views))
        
        message.topAnchor.constraint(equalTo: giftCardImage.bottomAnchor, constant: .padding).isActive = true
        
        button.topAnchor.constraint(equalTo: message.bottomAnchor, constant: .extendedPadding).isActive = true
        
        skip.topAnchor.constraint(equalTo: button.bottomAnchor, constant: .padding).isActive = true

        let guide = UIView()
        guide.translatesAutoresizingMaskIntoConstraints = false
        guide.isHidden = true
        container.addSubview(guide)
        guide.topAnchor.constraint(equalTo: topLine.bottomAnchor).isActive = true
        guide.bottomAnchor.constraint(equalTo: giftCardImage.topAnchor).isActive = true

        headline.centerYAnchor.constraint(equalTo: guide.centerYAnchor).isActive = true

        
        giftCardImage.topAnchor.constraint(equalTo: backgroundLine.topAnchor, constant: -40).isActive = true
        
        let gotchaLabel = UILabel()
        gotchaLabel.translatesAutoresizingMaskIntoConstraints = false
        gotchaLabel.text = "2018_05_01_campaign.star".localized
        gotchaLabel.textAlignment = .center
        gotchaLabel.font = .screenshopFont(.hindLight, size: 14)
        container.addSubview(gotchaLabel)
        gotchaLabel.topAnchor.constraint(greaterThanOrEqualTo: skip.bottomAnchor, constant: .padding).isActive = true
        gotchaLabel.leadingAnchor.constraint(equalTo: container.layoutMarginsGuide.leadingAnchor).isActive = true
        gotchaLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -.padding).isActive = true
        gotchaLabel.trailingAnchor.constraint(equalTo: container.layoutMarginsGuide.trailingAnchor).isActive = true
    }
    

    @objc func skipAction(_ sender:Any){
        self.delegate?.giftCardCampaignViewControllerDidSkip(self)
    }
    @objc func continueAction(_ sender:Any){
        self.delegate?.giftCardCampaignViewControllerDidContinue(self)
    }
    
    struct CampaignDescription {
        var headline:String
        var message:String
        var buttonText:String
        var skipText:String
    }
    
    struct ElementSizes {
        var headlineFontSize:CGFloat
        var messageFontSize:CGFloat
        var skipTextFontSize:CGFloat
        var aboveSkipPad:CGFloat
        var belowSkipPad:CGFloat
    }
    func didEnterSlide(){
        
    }
    func willLeaveSlide(){
        
    }

}
