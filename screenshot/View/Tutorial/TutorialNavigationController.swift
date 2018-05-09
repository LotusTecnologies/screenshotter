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
        
        let signup = TutorialEmailSlideViewController()
        signup.delegate = self
        self.pushViewController(signup, animated: true)
    }
    
    func giftCardCampaignViewControllerDidContinue(_ viewController:GiftCardCampaignViewController){
        Analytics.trackOnboardingCampainCreditCardLetsGo()
        let viewController = CheckoutPaymentFormViewController(withCard: nil, isEditLayout: true, confirmBeforeSave: false, autoSaveBillAddressAsShippingAddress:true)
        viewController.title = "2018_05_01_campaign.payment".localized
        viewController.delegate = self
        self.pushViewController(viewController, animated: true)
        
        let alertConroller = UIAlertController(title: "2018_05_01_campaign.alert.title".localized, message: "2018_05_01_campaign.alert.message".localized, preferredStyle: .alert)
        alertConroller.addAction(UIAlertAction(title: "generic.ok".localized, style: .cancel, handler: nil))
        viewController.present(alertConroller, animated: true, completion: nil)
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
        let frc = DataModel.sharedInstance.cardFrc(delegate: nil).fetchedObjects.first
        Analytics.trackOnboardingCampainCreditCardDone(email: frc?.email, phone: frc?.phone)
        
        let signup = TutorialEmailSlideViewController()
        signup.delegate = self
        self.pushViewController(signup, animated: true)
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

