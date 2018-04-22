//
//  CampaignPromotionExplanationViewController.swift
//  screenshot
//
//  Created by Jonathan Rose on 4/22/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

protocol CampaignPromotionExplanationViewControllerDelegate : class {
    func campaignPromotionExplanationViewControllerDidPressClose(_ campaignPromotionExplanationViewController:CampaignPromotionExplanationViewController)
    func campaignPromotionExplanationViewControllerDidPressMainButton(_ campaignPromotionExplanationViewController:CampaignPromotionExplanationViewController)

}

class CampaignPromotionExplanationViewController: UIViewController, UITextViewDelegate{

    var delegate:CampaignPromotionExplanationViewControllerDelegate?
    
    var campaign = CampaignPromotionExplanation(
        headline: "2018_04_20_campaign.instructions.headline".localized,
        footer: "2018_04_20_campaign.instructions.footer".localized,
        buttonText: "2018_04_20_campaign.instructions.button".localized,
        campaignNameForAnalytics: "2018_04_20 campaign agree button pushed",
        instructions: ["2018_04_20_campaign.instructions.step_1".localized,
                       "2018_04_20_campaign.instructions.step_2".localized,
                       "2018_04_20_campaign.instructions.step_3".localized,
                       "2018_04_20_campaign.instructions.step_4".localized,
                       "2018_04_20_campaign.instructions.step_5".localized

                       ])
    
    struct CampaignPromotionExplanation {
        var headline:String
        var footer:String
        var buttonText:String
        var campaignNameForAnalytics:String
        var instructions:[String]
    }
    fileprivate let legalLinkTOS = "TOS"
    fileprivate let legalLinkPP = "PP"
    
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
                c.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 34).isActive = true
                c.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -34).isActive = true
                c.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor, constant: 40).isActive = true
                c.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -40).isActive = true
                return c
            }
        }()
        
        container.layoutMargins = UIEdgeInsets(top: 25, left: 25, bottom: 25, right: 25)

        
        let closeButton = UIButton()
        closeButton.setImage(UIImage(named:"ShareToMatchsticksClose"), for: .normal)
        closeButton.showsTouchWhenHighlighted = true
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeButtonPressed), for: .touchUpInside)
        container.addSubview(closeButton)
        closeButton.topAnchor.constraint(equalTo: container.topAnchor, constant:3.0).isActive = true
        closeButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant:-3.0).isActive = true

        
       
        
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
            countLabel.text = String(index + 1)
            countLabel.textAlignment = .center
            countLabel.font = UIFont.screenshopFont(.hind, textStyle: .title3, staticSize: true)
            countLabel.textColor = .crazeRed
            countLabel.translatesAutoresizingMaskIntoConstraints = false
            instructionsContainer.addSubview(countLabel)
            countLabel.leadingAnchor.constraint(equalTo: instructionsContainer.leadingAnchor).isActive = true
            countLabel.topAnchor.constraint(equalTo: instructionsContainer.topAnchor, constant:-3.0).isActive = true
            countLabels.append(countLabel)
            
            let instructionLabel = UILabel()
            instructionLabel.numberOfLines = 0
            instructionLabel.textColor = .gray2
            instructionLabel.text = instruction
            instructionLabel.font = UIFont.screenshopFont(.hind, textStyle: .body, staticSize: true)
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
        
        
        let footer = UITextView()
        footer.isEditable = false
        footer.textAlignment = .center
        footer.isScrollEnabled = false
        footer.font = UIFont.screenshopFont(.hind, textStyle: .body, staticSize: true)
        footer.textColor = .gray2
        footer.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(footer)
        footer.leadingAnchor.constraint(equalTo: container.layoutMarginsGuide.leadingAnchor).isActive = true
        footer.trailingAnchor.constraint(equalTo: container.layoutMarginsGuide.trailingAnchor).isActive = true
        footer.topAnchor.constraint(equalTo: mainButton.bottomAnchor).isActive = true
        footer.bottomAnchor.constraint(equalTo: container.layoutMarginsGuide.bottomAnchor).isActive = true
        footer.setContentHuggingPriority(.required, for: .vertical)
        footer.delegate = self
        footer.attributedText = {
            let textViewFont: UIFont = .preferredFont(forTextStyle: .footnote)
            
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            
            func attributes(_ link: String? = nil) -> [NSAttributedStringKey : Any] {
                var attributes: [NSAttributedStringKey : Any] = [
                    NSAttributedStringKey.font: textViewFont,
                    NSAttributedStringKey.paragraphStyle: paragraph
                ]
                
                if let link = link {
                    attributes[NSAttributedStringKey.link] = link
                }
                
                return attributes
            }
            
            return NSMutableAttributedString(segmentedString: "campaign.instructions.footer", attributes: [
                attributes(),
                attributes(legalLinkTOS),
                attributes(),
                ])
        }()
        
        
        
        
        
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
            first.heightAnchor.constraint(greaterThanOrEqualToConstant: 3.0);
            let asBigAsPossible = first.heightAnchor.constraint(equalToConstant: 100)
            asBigAsPossible.priority = UILayoutPriority.init(rawValue: 2)
            asBigAsPossible.isActive = true
        }
    }
    
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        
        switch URL.absoluteString {
        case legalLinkTOS:
            if let viewController = LegalViewControllerFactory.termsOfServiceViewController(withDoneTarget: self, action: #selector(dismissViewController)) {
                present(viewController, animated: true, completion: nil)
            }
            break;

        default:
            break
        }
        
        return false
    }
    @objc func dismissViewController(){
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func agreeButtonPressed(){
        self.delegate?.campaignPromotionExplanationViewControllerDidPressMainButton(self)
    }
    
    @objc func closeButtonPressed(){
        self.delegate?.campaignPromotionExplanationViewControllerDidPressClose(self)

    }
}
