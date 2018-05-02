//
//  TutorialNavigationController.swift
//  screenshot
//
//  Created by Corey Werner on 10/14/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit

@objc protocol TutorialNavigationControllerDelegate : class {
    func tutorialNavigationControllerDidComplete(_ viewController: TutorialNavigationController)
}

class TutorialNavigationController : UINavigationController {
    weak var tutorialDelegate: TutorialNavigationControllerDelegate?
    
   
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Analytics.trackStartedTutorial()
    }
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        let welcomeSlide = TutorialWelcomeSlideViewController()
        self.viewControllers = [welcomeSlide]
        welcomeSlide.delegate = self
        Analytics.trackStartedTutorialVideo()
        view.backgroundColor = .white
        self.isNavigationBarHidden = true
        self.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - Slides
    
    private func slideLayoutMargins(_ slide: UIViewController) -> UIEdgeInsets {
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
        
        var paddingX: CGFloat = .padding
        
        if slide.isKind(of: TutorialTrySlideViewController.self) {
            // TODO: when supporting localization, this should be if isEnglish
            // Only customize insets for default font size
            if UIApplication.shared.preferredContentSizeCategory == UIContentSizeCategory.large {
                if UIDevice.is375w {
                    paddingX = 30
                    
                } else if UIDevice.is414w {
                    paddingX = 45
                }
            }
        }
        
        return UIEdgeInsets(top: .padding + extraTop, left: paddingX, bottom: .padding + extraBottom, right: paddingX)
    }
}
extension TutorialNavigationController : UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool){
        if self.interactivePopGestureRecognizer?.state == UIGestureRecognizerState.possible {
            self.isNavigationBarHidden = !(viewController is CheckoutPaymentFormViewController)
        }
    }
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool){
        if self.interactivePopGestureRecognizer?.state == UIGestureRecognizerState.possible {
            self.isNavigationBarHidden = !(viewController is CheckoutPaymentFormViewController)
        }
    }

}



extension TutorialNavigationController: TutorialWelcomeSlideViewControllerDelegate {
    func tutorialWelcomeSlideViewControllerDidComplete(_ viewController:TutorialWelcomeSlideViewController) {
        Analytics.trackOnboardingWelcome()
        let viewController = GiftCardCampaignViewController()
        viewController.delegate = self
        self.pushViewController(viewController, animated: true)
    }
}
extension TutorialNavigationController: GiftCardCampaignViewControllerDelegate {
    func giftCardCampaignViewControllerDidSkip(_ viewController:GiftCardCampaignViewController){
        Analytics.trackOnboardingCampainCreditCardSkip()
        let viewController = CampaignPromotionViewController(modal: false)
        viewController.delegate = self
        self.pushViewController(viewController, animated: true)

    }
    func giftCardCampaignViewControllerDidContinue(_ viewController:GiftCardCampaignViewController){
        Analytics.trackOnboardingCampainCreditCardLetsGo()
        let viewController = CheckoutPaymentFormViewController(withCard: nil, isEditLayout: true, confirmBeforeSave: false, autoSaveBillAddressAsShippingAddress:true)
        viewController.title = "2018_05_01_campaign.payment".localized
        viewController.delegate = self
        self.pushViewController(viewController, animated: true)
    }
}
extension TutorialNavigationController: CheckoutFormViewControllerDelegate {
    func checkoutFormViewControllerDidAdd(_ viewController: CheckoutFormViewController){
        Analytics.trackOnboardingCampainCreditCardEnteredCard()
        let viewController = GiftCardDoneViewController()
        viewController.delegate = self
        self.pushViewController(viewController, animated: true)
    }
}

extension TutorialNavigationController : GiftCardDoneViewControllerDelegate {
    func giftCardDoneViewControllerDidPressDone(_ viewController:GiftCardDoneViewController){
        Analytics.trackOnboardingCampainCreditCardDone()
        UserDefaults.standard.set(UserDefaultsKeys.CampaignCompleted.campaign_2018_04_20.rawValue, forKey: UserDefaultsKeys.lastCampaignCompleted)
        let viewController = CampaignPromotionViewController(modal: false)
        viewController.delegate = self
        self.pushViewController(viewController, animated: true)
    }
}

extension TutorialNavigationController: CampaignPromotionViewControllerDelegate {
    func campaignPromotionViewControllerDidPressLearnMore(_ viewController:CampaignPromotionViewController){
        Analytics.trackOnboardingCampaignVideoLearnMore(campaign: .campaign2018204)
        let learnMore = CampaignPromotionExplanationViewController(modal:false)
        learnMore.delegate = self
        self.pushViewController(learnMore, animated: true)
    }
    
    func campaignPromotionViewControllerDidPressSkip(_ viewController:CampaignPromotionViewController){
        Analytics.trackOnboardingCampaignVideoSkip(campaign: .campaign2018204)
        let signup = TutorialEmailSlideViewController()
        signup.delegate = self
        self.pushViewController(signup, animated: true)
    }
}

extension TutorialNavigationController : CampaignPromotionExplanationViewControllerDelegate {
    func campaignPromotionExplanationViewControllerDidPressDoneButton(_ campaignPromotionExplanationViewController:CampaignPromotionExplanationViewController){
        Analytics.trackOnboardingCampaignTextDone(campaign: .campaign2018204)
        let signup = TutorialEmailSlideViewController()
        signup.delegate = self
        self.pushViewController(signup, animated: true)
    }
    func campaignPromotionExplanationViewControllerDidPressBackButton(_
        campaignPromotionExplanationViewController:CampaignPromotionExplanationViewController){
        Analytics.trackOnboardingCampaignTextBack(campaign: .campaign2018204)
        self.popViewController(animated: true)
    }

}

extension TutorialNavigationController: TutorialEmailSlideViewControllerDelegate {
    func tutorialEmailSlideViewDidComplete(_ slideView: TutorialEmailSlideViewController){
        let tryItOut = TutorialTrySlideViewController()
        tryItOut.delegate = self
        self.pushViewController(tryItOut, animated: true)
    }
    func tutorialEmailSlideViewDidTapTermsOfService(_ slideView: TutorialEmailSlideViewController){
        Analytics.trackOnboardingSubmittedEmailTOS()
        if let viewController = LegalViewControllerFactory.termsOfServiceViewController() {
            present(viewController, animated: true, completion: nil)
        }
    }
    
    func tutorialEmailSlideViewDidTapPrivacyPolicy(_ slideView: TutorialEmailSlideViewController){
        Analytics.trackOnboardingSubmittedEmailPrivacy()
        if let viewController = LegalViewControllerFactory.privacyPolicyViewController() {
            present(viewController, animated: true, completion: nil)
        }
    }

}

extension TutorialNavigationController : TutorialTrySlideViewControllerDelegate {
    func tutorialTrySlideViewDidSkip(_ slideView: TutorialTrySlideViewController){
        Analytics.trackOnboardingTryItOutSkipped()
        tutorialTrySlideViewDidComplete(slideView)
        AppDelegate.shared.shouldLoadDiscoverNextLoad = true

    }
    func tutorialTrySlideViewDidComplete(_ slideView: TutorialTrySlideViewController){
        Analytics.trackOnboardingTryItOutScreenshot()

        slideView.delegate = nil
        
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.onboardingCompleted)
        
        self.tutorialDelegate?.tutorialNavigationControllerDidComplete(self)
    }
}

