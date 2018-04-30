//
//  TutorialViewController.swift
//  screenshot
//
//  Created by Corey Werner on 10/14/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit

@objc protocol TutorialViewControllerDelegate : class {
    func tutorialViewControllerDidComplete(_ viewController: TutorialViewController)
}

class TutorialViewController : UINavigationController {
    weak var tutorialDelegate: TutorialViewControllerDelegate?
    
   
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        let welcomeSlide = TutorialWelcomeSlideViewController()
        self.viewControllers = [welcomeSlide]
        welcomeSlide.delegate = self
        AnalyticsTrackers.standard.track(.startedTutorial)
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
extension TutorialViewController : UINavigationControllerDelegate {
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



extension TutorialViewController: TutorialWelcomeSlideViewControllerDelegate {
    func tutorialWelcomeSlideViewControllerDidComplete(_ viewController:TutorialWelcomeSlideViewController) {
        let viewController = GiftCardCampaignViewController()
        viewController.delegate = self
        self.pushViewController(viewController, animated: true)
    }
}
extension TutorialViewController: GiftCardCampaignViewControllerDelegate {
    func giftCardCampaignViewControllerDidSkip(_ viewController:GiftCardCampaignViewController){
        let viewController = CampaignPromotionViewController(modal: false)
        viewController.delegate = self
        self.pushViewController(viewController, animated: true)

    }
    func giftCardCampaignViewControllerDidContinue(_ viewController:GiftCardCampaignViewController){
        let viewController = CheckoutPaymentFormViewController(withCard: nil, isEditLayout: true, confirmBeforeSave: false)
        viewController.title = "2018_05_01_campaign.payment".localized
        viewController.delegate = self
        self.pushViewController(viewController, animated: true)
    }
}
extension TutorialViewController: CheckoutFormViewControllerDelegate {
    func checkoutFormViewControllerDidAdd(_ viewController: CheckoutFormViewController){
        let viewController = GiftCardDoneViewController()
        viewController.delegate = self
        self.pushViewController(viewController, animated: true)
    }
}

extension TutorialViewController : GiftCardDoneViewControllerDelegate {
    func giftCardDoneViewControllerDidPressDone(_ viewController:GiftCardDoneViewController){
        let viewController = CampaignPromotionViewController(modal: false)
        viewController.delegate = self
        self.pushViewController(viewController, animated: true)
    }
}

extension TutorialViewController: CampaignPromotionViewControllerDelegate {
    func campaignPromotionViewControllerDidPressLearnMore(_ viewController:CampaignPromotionViewController){
        let learnMore = CampaignPromotionExplanationViewController(modal:false)
        learnMore.delegate = self
        self.pushViewController(learnMore, animated: true)
    }
    
    func campaignPromotionViewControllerDidPressSkip(_ viewController:CampaignPromotionViewController){
        let signup = TutorialEmailSlideViewController()
        signup.delegate = self
        self.pushViewController(signup, animated: true)
    }
}

extension TutorialViewController : CampaignPromotionExplanationViewControllerDelegate {
    func campaignPromotionExplanationViewControllerDidPressDoneButton(_ campaignPromotionExplanationViewController:CampaignPromotionExplanationViewController){
        let signup = TutorialEmailSlideViewController()
        signup.delegate = self
        self.pushViewController(signup, animated: true)
    }
    func campaignPromotionExplanationViewControllerDidPressBackButton(_ campaignPromotionExplanationViewController:CampaignPromotionExplanationViewController){
        self.popViewController(animated: true)
    }

}

extension TutorialViewController: TutorialEmailSlideViewControllerDelegate {
    func tutorialEmailSlideViewDidComplete(_ slideView: TutorialEmailSlideViewController){
        let tryItOut = TutorialTrySlideViewController()
        tryItOut.delegate = self
        self.pushViewController(tryItOut, animated: true)
    }
    func tutorialEmailSlideViewDidTapTermsOfService(_ slideView: TutorialEmailSlideViewController){
        if let viewController = LegalViewControllerFactory.termsOfServiceViewController() {
            present(viewController, animated: true, completion: nil)
        }
    }
    
    func tutorialEmailSlideViewDidTapPrivacyPolicy(_ slideView: TutorialEmailSlideViewController){
        if let viewController = LegalViewControllerFactory.privacyPolicyViewController() {
            present(viewController, animated: true, completion: nil)
        }
    }

}

extension TutorialViewController : TutorialTrySlideViewControllerDelegate {
    func tutorialTrySlideViewDidSkip(_ slideView: TutorialTrySlideViewController){
        tutorialTrySlideViewDidComplete(slideView)
        AnalyticsTrackers.standard.track(.skippedTutorial)
        AppDelegate.shared.shouldLoadDiscoverNextLoad = true

    }
    func tutorialTrySlideViewDidComplete(_ slideView: TutorialTrySlideViewController){
        slideView.delegate = nil
        
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.onboardingCompleted)
        AnalyticsTrackers.standard.track(.finishedTutorial)
        //TODO: why is this extra branch tracking here?
        AnalyticsTrackers.branch.track(.finishedTutorial)
        
        self.tutorialDelegate?.tutorialViewControllerDidComplete(self)
    }
}

