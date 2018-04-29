//
//  GiftCardDoneViewController.swift
//  screenshot
//
//  Created by Jonathan Rose on 4/26/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class GiftCardDoneViewController: UIViewController {
    let campaign = CampaignDescription(
        headline: "2018_05_01_campaign.done.headline".localized,
        message: "2018_05_01_campaign.done.message".localized,
        buttonText: "2018_05_01_campaign.done.button".localized)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let sizes:ElementSizes = {
            if UIDevice.is320w {
                return ElementSizes(headlineFontSize: 25, messageFontSize: 20)
            }else{
                return ElementSizes(headlineFontSize: 30, messageFontSize: 23)
            }
        }()
        
        self.view.backgroundColor = .white

        
        
        let topLine = UIImageView.init(image: UIImage(named: "redgradientTopLine"))
        topLine.contentMode = .scaleToFill

        let background = UIImageView.init(image: UIImage.init(named: "confetti"))

        let headline = UILabel.init()
        headline.text = self.campaign.headline
        headline.textAlignment = .center
        headline.textColor = .gray4
        headline.font = UIFont.screenshopFont(.hindBold, size: sizes.headlineFontSize)
        headline.numberOfLines = 0
        
        let giftCardImage = UIImageView.init(image: UIImage.init(named: "giftCard25USD"))

        let message = UILabel.init()
        message.text = self.campaign.message
        message.textAlignment = .center
        message.textColor = .gray4
        message.font = UIFont.screenshopFont(.hindBold, size: sizes.messageFontSize)
        message.minimumScaleFactor = 0.5
        message.numberOfLines = 0
        
        let button = MainButton()
        button.setTitle(self.campaign.buttonText, for: .normal)
        button.backgroundColor = .crazeGreen
        
        
        let container = self.view!

        let views = ["topLine":topLine,
                     "background":background,
                     "headline":headline,
                     "giftCardImage":giftCardImage,
                     "button":button,
                     "message":message]
        
        [topLine, background, headline, giftCardImage, button, message].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview($0)
            $0.centerXAnchor.constraint(equalTo: container.centerXAnchor).isActive = true
        }
        //full width objects:
        [topLine, background].forEach {
            $0.widthAnchor.constraint(equalTo: container.widthAnchor).isActive = true
        }
        
        // objects that respect margin:
        [ headline, message].forEach {
            let padding:CGFloat = 30
            $0.widthAnchor.constraint(equalTo: container.widthAnchor, constant: -2*padding).isActive = true
        }
        
        container.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[topLine(6)][background]|", options: [], metrics: nil, views: views))


        let centerMessage = message.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        centerMessage.priority = UILayoutPriority.init(500)
        centerMessage.isActive = true
        button.topAnchor.constraint(greaterThanOrEqualTo: message.bottomAnchor).isActive = true
        giftCardImage.bottomAnchor.constraint(lessThanOrEqualTo: message.topAnchor).isActive = true
        headline.bottomAnchor.constraint(lessThanOrEqualTo: giftCardImage.topAnchor).isActive = true

        
        
        //center headline in area above imageView
        let guide1 = UIView()
        guide1.translatesAutoresizingMaskIntoConstraints = false
        guide1.isHidden = true
        container.addSubview(guide1)
        guide1.topAnchor.constraint(equalTo: topLine.bottomAnchor).isActive = true
        guide1.bottomAnchor.constraint(equalTo: giftCardImage.topAnchor).isActive = true
        headline.centerYAnchor.constraint(equalTo: guide1.centerYAnchor).isActive = true
        guide1.heightAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true
        
        
        let guide2 = UIView()
        guide2.translatesAutoresizingMaskIntoConstraints = false
        guide2.isHidden = true
        container.addSubview(guide2)
        guide2.topAnchor.constraint(equalTo: giftCardImage.bottomAnchor).isActive = true
        guide2.bottomAnchor.constraint(equalTo: button.topAnchor).isActive = true
        
        
        let position = guide2.heightAnchor.constraint(equalTo: container.heightAnchor, multiplier:0.3)
        position.priority = .defaultLow
        position.isActive = true
        
        let guide3 = UIView()
        guide3.translatesAutoresizingMaskIntoConstraints = false
        guide3.isHidden = true
        container.addSubview(guide3)
        guide3.topAnchor.constraint(equalTo: giftCardImage.bottomAnchor).isActive = true
        guide3.bottomAnchor.constraint(equalTo: message.topAnchor).isActive = true
        
        
        let guide4 = UIView()
        guide4.translatesAutoresizingMaskIntoConstraints = false
        guide4.isHidden = true
        container.addSubview(guide4)
        guide4.topAnchor.constraint(equalTo: message.bottomAnchor).isActive = true
        guide4.bottomAnchor.constraint(equalTo: button.topAnchor).isActive = true
        
        guide3.heightAnchor.constraint(equalTo: guide4.heightAnchor).isActive = true
        
        guide3.heightAnchor.constraint(greaterThanOrEqualToConstant: 40.0).isActive = true
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    struct CampaignDescription {
        var headline:String
        var message:String
        var buttonText:String
    }
    
    struct ElementSizes {
        var headlineFontSize:CGFloat
        var messageFontSize:CGFloat
    }
}
