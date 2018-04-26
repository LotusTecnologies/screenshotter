//
//  GiftCardCampaignViewController.swift
//  screenshot
//
//  Created by Jonathan Rose on 4/26/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class GiftCardCampaignViewController: UIViewController {

    let campaign = CampaignDescription(
        headline: "2018_05_01_campaign.headline".localized,
        message: "2018_05_01_campaign.message".localized,
        messageDetail: "2018_05_01_campaign.message.detail".localized,
        buttonText: "2018_05_01_campaign.button".localized,
        skipText: "2018_05_01_campaign.skip".localized)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .white
        
        let topBackground = UIView()
        topBackground.backgroundColor = .white

        let topLine = UIImageView.init(image: UIImage(named: "redgradientTopLine"))
        topLine.contentMode = .scaleToFill
        
        let bottomBackground = UIImageView.init(image: UIImage.init(named: "halfconfetti"))
        
        let backgroundLine = UIView()
        backgroundLine.backgroundColor = .gray9
        
        let giftCardImage = UIImageView.init(image: UIImage.init(named: "giftCard25USD"))
        
        let headline = UILabel.init()
        headline.text = self.campaign.headline
        headline.textAlignment = .center
        headline.textColor = .gray4
        headline.font = UIFont.screenshopFont(.hindBold, size: 30)
        headline.numberOfLines = 0
        
        
        let message = UILabel.init()
        message.text = self.campaign.message
        message.textAlignment = .center
        message.textColor = .gray4
        message.font = UIFont.screenshopFont(.hindBold, size: 23)
        message.minimumScaleFactor = 0.5
        message.numberOfLines = 0
        
        let separatorLine = UIView()
        separatorLine.backgroundColor = .gray9
        
        let messageDetail = UILabel.init()
        messageDetail.text = self.campaign.messageDetail
        messageDetail.textAlignment = .center
        messageDetail.textColor = .gray6
        messageDetail.font = UIFont.screenshopFont(.hindBold, size: 23)
        messageDetail.minimumScaleFactor = 0.5
        messageDetail.numberOfLines = 0
        
        
        
        let button = MainButton()
        button.setTitle(self.campaign.buttonText, for: .normal)
        button.backgroundColor = .crazeGreen
        
        
        let skip = UIButton()
        let underlineString = NSAttributedString.init(string: self.campaign.skipText, attributes:
            [NSAttributedStringKey.underlineStyle : NSUnderlineStyle.styleSingle.rawValue,
             NSAttributedStringKey.underlineColor : UIColor.gray4,
             NSAttributedStringKey.foregroundColor: UIColor.gray4])
        skip.setAttributedTitle(underlineString, for: .normal)
        button.backgroundColor = .crazeGreen
        
        
        
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
                     "messageDetail":messageDetail,
                     "separatorLine":separatorLine]
        
        //everything is centeredX (don't use dictionary - order is important)
        [topLine, topBackground, backgroundLine, bottomBackground, headline, giftCardImage, skip, button, message, messageDetail, separatorLine].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview($0)
            $0.centerXAnchor.constraint(equalTo: container.centerXAnchor).isActive = true
        }
        
        //full width objects:
        [topLine, topBackground, backgroundLine, bottomBackground].forEach {
            $0.widthAnchor.constraint(equalTo: container.widthAnchor).isActive = true
        }
        
        // objects that respect margin:
        [ headline, skip, message, messageDetail].forEach {
            let padding:CGFloat = 30
            $0.widthAnchor.constraint(equalTo: container.widthAnchor, constant: -2*padding).isActive = true
        }
        
        //Custom width:
        separatorLine.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: 0.25).isActive = true

        //background V layout
        container.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[topLine(6)][topBackground][backgroundLine(1)][bottomBackground]|", options: [], metrics: nil, views: views))
        
        topBackground.heightAnchor.constraint(equalTo: container.heightAnchor, multiplier: 0.27).isActive = true
        
        
        //forground V layout:
        container.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[giftCardImage][message][separatorLine(2)][messageDetail(==message)][button]-30-[skip]-60-|", options: [], metrics: nil, views: views))

        let guide = UIView()
        guide.translatesAutoresizingMaskIntoConstraints = false
        guide.isHidden = true
        container.addSubview(guide)
        guide.topAnchor.constraint(equalTo: topLine.bottomAnchor).isActive = true
        guide.bottomAnchor.constraint(equalTo: giftCardImage.topAnchor).isActive = true

        headline.centerYAnchor.constraint(equalTo: guide.centerYAnchor).isActive = true

        
        giftCardImage.topAnchor.constraint(equalTo: backgroundLine.topAnchor, constant: -40).isActive = true
        
    }
    

    struct CampaignDescription {
        var headline:String
        var message:String
        var messageDetail:String
        var buttonText:String
        var skipText:String
    }

}
