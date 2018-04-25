//
//  CampaignPromotionExplanationViewController.swift
//  screenshot
//
//  Created by Jonathan Rose on 4/22/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

protocol CampaignPromotionExplanationViewControllerDelegate : class {
    func campaignPromotionExplanationViewControllerDidPressDoneButton(_ campaignPromotionExplanationViewController:CampaignPromotionExplanationViewController)
    func campaignPromotionExplanationViewControllerDidPressBackButton(_ campaignPromotionExplanationViewController:CampaignPromotionExplanationViewController)

}

class CampaignPromotionExplanationViewController: UIViewController{

    var delegate:CampaignPromotionExplanationViewControllerDelegate?
    
    var campaign = CampaignPromotionExplanation(
        headline: "2018_04_20_campaign.instructions.headline".localized,
        buttonText: "2018_04_20_campaign.instructions.button".localized,
        secondButtonText: "2018_04_20_campaign.instructions.secondButton".localized,
        instructions: ["2018_04_20_campaign.instructions.step_1".localized,
                       "2018_04_20_campaign.instructions.step_2".localized,
                       "2018_04_20_campaign.instructions.step_3".localized,
                       "2018_04_20_campaign.instructions.step_4".localized,
                       "2018_04_20_campaign.instructions.step_5".localized

                       ])
    
    struct CampaignPromotionExplanation {
        var headline:String
        var buttonText:String
        var secondButtonText:String
        var instructions:[String]
    }
    
    var willPresentInModal:Bool = false
    
    private let transitioning = ViewControllerTransitioningDelegate.init(presentation: .intrinsicContentSize, transition: .modal)

    init(modal:Bool) {
        super.init(nibName: nil, bundle: nil)
        self.willPresentInModal = modal
        if modal {
            transitioningDelegate = transitioning
            modalPresentationStyle = .custom
            
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let container:UIView = {
            if willPresentInModal {
                self.view.layer.masksToBounds = true
                self.view.layer.cornerRadius = 8
                self.view.backgroundColor = .white
                return self.view
            }else{
                self.view.backgroundColor = .gray9
                let c = UIView.init()
                c.backgroundColor = .white
                let layer = c.layer
                layer.masksToBounds = true
                layer.shadowColor = Shadow.basic.color.cgColor
                layer.shadowOffset = Shadow.basic.offset
                layer.shadowRadius = Shadow.basic.radius
                layer.cornerRadius = 8
                c.translatesAutoresizingMaskIntoConstraints = false
                self.view.addSubview(c)
                if UIDevice.is320w {
                    c.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 15).isActive = true
                    c.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -15).isActive = true
                    c.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor, constant: 20).isActive = true
                    c.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -20).isActive = true
                }else{
                    c.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 34).isActive = true
                    c.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -34).isActive = true
                    c.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor, constant: 40).isActive = true
                    c.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -40).isActive = true
                }
                return c
            }
        }()
        if UIDevice.is320w {
            container.layoutMargins = UIEdgeInsets(top: 5, left: 15, bottom: 5, right: 15)
        }else{
            container.layoutMargins = UIEdgeInsets(top: 25, left: 25, bottom: 25, right: 25)
        }
        
        
        let secondButton = UIButton.init()
        secondButton.translatesAutoresizingMaskIntoConstraints = false
        secondButton.titleLabel?.textAlignment = .center
        secondButton.titleLabel?.font = UIFont.screenshopFont(.hind, textStyle: .body, staticSize: true)
        secondButton.addTarget(self, action: #selector(tappedSecondaryButton), for: .touchUpInside)
        container.addSubview(secondButton)
        secondButton.setTitle(self.campaign.secondButtonText, for: .normal)
        secondButton.setTitleColor(.gray3, for: .normal)
        secondButton.setTitleColor(.gray5, for: .highlighted)
        secondButton.centerXAnchor.constraint(equalTo: container.centerXAnchor).isActive = true
        secondButton.bottomAnchor.constraint(equalTo: container.layoutMarginsGuide.bottomAnchor).isActive = true
        secondButton.setContentCompressionResistancePriority(.required, for: .vertical)
       
        
        let headline = UILabel()
        headline.translatesAutoresizingMaskIntoConstraints = false
        headline.textAlignment = .center
        headline.text = self.campaign.headline
        headline.font = UIFont.screenshopFont(.hind, textStyle: .title2, staticSize: true)
        headline.textColor = .gray2
        headline.numberOfLines = 0
        container.addSubview(headline)
        headline.topAnchor.constraint(equalTo: container.layoutMarginsGuide.topAnchor).isActive = true
        headline.leadingAnchor.constraint(equalTo: container.layoutMarginsGuide.leadingAnchor).isActive = true
        headline.trailingAnchor.constraint(equalTo: container.layoutMarginsGuide.trailingAnchor).isActive = true
        
        
        var countLabels:[UILabel] = []
        var instructionLabels:[UILabel] = []
        var instructionsContainers:[UIView] = []
        for (index, instruction) in self.campaign.instructions.enumerated() {
            
            let instructionsContainer = UIView()
            instructionsContainer.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(instructionsContainer)
            instructionsContainer.leadingAnchor.constraint(equalTo: container.layoutMarginsGuide.leadingAnchor).isActive = true
            instructionsContainer.trailingAnchor.constraint(equalTo: container.layoutMarginsGuide.trailingAnchor).isActive = true
            instructionsContainers.append(instructionsContainer)
            
            let countLabel = UILabel()
            countLabel.text = String(index + 1).appending(".")
            countLabel.textAlignment = .center
            if UIDevice.is320w {
                countLabel.font = UIFont.screenshopFont(.hind, size: 15)
            }else if UIDevice.is375w{
                countLabel.font = UIFont.screenshopFont(.hind, size: 16)
            }else{
                countLabel.font = UIFont.screenshopFont(.hind, size: 18)
            }
            countLabel.textColor = .gray2
            countLabel.translatesAutoresizingMaskIntoConstraints = false
            instructionsContainer.addSubview(countLabel)
            countLabel.leadingAnchor.constraint(equalTo: instructionsContainer.leadingAnchor).isActive = true
            countLabel.topAnchor.constraint(equalTo: instructionsContainer.topAnchor, constant:0).isActive = true
            countLabels.append(countLabel)
            
            let instructionLabel = UILabel()
            instructionLabel.numberOfLines = 0
            instructionLabel.textColor = .gray2
            instructionLabel.text = instruction
            if UIDevice.is320w {
                instructionLabel.font = UIFont.screenshopFont(.hind, size: 15)
            }else if UIDevice.is375w{
                instructionLabel.font = UIFont.screenshopFont(.hind, size: 16)
            }else{
                instructionLabel.font = UIFont.screenshopFont(.hind, size: 18)
            }
            instructionLabel.translatesAutoresizingMaskIntoConstraints = false
            instructionsContainer.addSubview(instructionLabel)
            instructionLabel.trailingAnchor.constraint(equalTo: instructionsContainer.trailingAnchor).isActive = true
            instructionLabel.topAnchor.constraint(equalTo: instructionsContainer.topAnchor).isActive = true
            instructionLabels.append(instructionLabel)
            
            instructionsContainer.heightAnchor.constraint(greaterThanOrEqualTo: countLabel.heightAnchor).isActive = true
            instructionsContainer.heightAnchor.constraint(greaterThanOrEqualTo: instructionLabel.heightAnchor).isActive = true
            
            let asSmallAsPossible = instructionsContainer.heightAnchor.constraint(equalToConstant: 0)
            asSmallAsPossible.priority = UILayoutPriority.init(rawValue: 1)
            asSmallAsPossible.isActive = true

            
        }
       
        
        for instructionLabel in instructionLabels {
            for countlabel in countLabels {
                instructionLabel.leadingAnchor.constraint(greaterThanOrEqualTo: countlabel.trailingAnchor, constant: 10.0).isActive = true
            }
            for otherInstructionLabel in instructionLabels {
                if instructionLabel != otherInstructionLabel {
                    instructionLabel.leadingAnchor.constraint(equalTo: otherInstructionLabel.leadingAnchor).isActive = true
                }
            }
            
        }

       
        
        
        
        let mainButton = MainButton.init()
        mainButton.translatesAutoresizingMaskIntoConstraints = false
        mainButton.backgroundColor = .crazeRed
        mainButton.addTarget(self, action: #selector(agreeButtonPressed), for: .touchUpInside)
        container.addSubview(mainButton)
        mainButton.setTitle(self.campaign.buttonText, for: .normal)
        mainButton.leadingAnchor.constraint(equalTo: container.layoutMarginsGuide.leadingAnchor).isActive = true
        mainButton.trailingAnchor.constraint(equalTo: container.layoutMarginsGuide.trailingAnchor).isActive = true
        mainButton.setContentCompressionResistancePriority(.required, for: .vertical)
        mainButton.bottomAnchor.constraint(equalTo: secondButton.topAnchor, constant:-3).isActive = true
        
        
        var last:UIView?
        var pads:[UIView] = []
        func pad(topView:UIView, bottomView:UIView) {
            let pad = UIView()
            pad.isHidden = true
            pad.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(pad)
            pad.topAnchor.constraint(equalTo: topView.bottomAnchor).isActive = true
            pad.bottomAnchor.constraint(equalTo: bottomView.topAnchor).isActive = true
            pads.append(pad)
        }
        
        for instructionsContainer in instructionsContainers {
            if let last = last {
                pad(topView: last, bottomView: instructionsContainer)
            }
            last = instructionsContainer
        }
        if let first = instructionsContainers.first {
            pad(topView: headline, bottomView: first)
        }
        if let last = instructionsContainers.last {
            pad(topView: last, bottomView: mainButton)
        }
        if let first = pads.first {
            for pad in pads {
                if pad != first {
                    pad.heightAnchor.constraint(equalTo: first.heightAnchor).isActive = true
                }
                
            }
            if UIDevice.is320w {
                first.heightAnchor.constraint(greaterThanOrEqualToConstant: 3.0);
            }else{
                first.heightAnchor.constraint(greaterThanOrEqualToConstant: 1.0);
            }
            let asBigAsPossible = first.heightAnchor.constraint(equalToConstant: 100)
            asBigAsPossible.priority = UILayoutPriority.init(rawValue: 2)
            asBigAsPossible.isActive = true
        }
    }
    
    
    @objc func tappedSecondaryButton() {
        self.delegate?.campaignPromotionExplanationViewControllerDidPressBackButton(self)

    }
    
    @objc func agreeButtonPressed(){
        self.delegate?.campaignPromotionExplanationViewControllerDidPressDoneButton(self)

    }
}
