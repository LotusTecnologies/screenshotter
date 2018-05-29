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
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        let welcomeViewController = OnboardingWelcomeViewController()
        welcomeViewController.delegate = self
        viewControllers = [welcomeViewController]
        
        Analytics.trackStartedTutorialVideo()
        
        view.backgroundColor = .white
        self.isNavigationBarHidden = true
        self.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Analytics.trackStartedTutorial()
    }
    
    private func tutorialCompleted() {
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.onboardingCompleted)
        tutorialDelegate?.tutorialNavigationControllerDidComplete(self)
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

extension TutorialNavigationController: OnboardingWelcomeViewControllerDelegate {
    func onboardingWelcomeViewControllerDidComplete(_ viewController: OnboardingWelcomeViewController) {
        Analytics.trackOnboardingWelcome()
        
        // !!!: DEBUG
        let onboardingDetailsViewController = OnboardingDetailsViewController()
        onboardingDetailsViewController.delegate = self
        pushViewController(onboardingDetailsViewController, animated: true)
        
        
//        let authorizeViewController = AuthorizeViewController()
//        authorizeViewController.delegate = self
//        pushViewController(authorizeViewController, animated: true)
        
        // !!!: DEBUG
//        let signup = TutorialEmailSlideViewController()
//        signup.delegate = self
//        self.pushViewController(signup, animated: true)
    }
}

extension TutorialNavigationController: AuthorizeViewControllerDelegate {
    func authorizeViewControllerDidSkip(_ viewController: AuthorizeViewController) {
        presentTutorialTrySlide()
    }
    
    func authorizeViewControllerDidLogin(_ viewController: AuthorizeViewController) {
        tutorialCompleted()
    }
    
    func authorizeViewControllerDidSignup(_ viewController: AuthorizeViewController) {
        
    }
    
    func authorizeViewControllerDidFacebookLogin(_ viewController: AuthorizeViewController) {
        tutorialCompleted()
    }
    
    func authorizeViewControllerDidFacebookSignup(_ viewController: AuthorizeViewController) {
        
    }
}

extension TutorialNavigationController: OnboardingDetailsViewControllerDelegate {
    func onboardingDetailsViewControllerDidSkip(_ viewController: OnboardingDetailsViewController) {
        presentTutorialTrySlide()
    }
    
    func onboardingDetailsViewControllerDidContinue(_ viewController: OnboardingDetailsViewController) {
        let name = viewController.name
        let gender = viewController.gender
        let size = viewController.size
        
        func saveData() {
            // TODO: save info
        }
        
        if name != nil && gender != nil && size != nil {
            saveData()
            presentTutorialTrySlide()
        }
        else {
            let alertController = UIAlertController(title: "onboarding.details.save_alert.title".localized, message: "onboarding.details.save_alert.message".localized, preferredStyle: .alert)
            let continueAction = UIAlertAction(title: "generic.continue".localized, style: .default, handler: { alertAction in
                saveData()
                self.presentTutorialTrySlide()
            })
            alertController.addAction(continueAction)
            alertController.addAction(UIAlertAction(title: "generic.cancel".localized, style: .cancel, handler: nil))
            alertController.preferredAction = continueAction
            present(alertController, animated: true)
        }
    }
}

extension TutorialNavigationController: TutorialEmailSlideViewControllerDelegate {
    func tutorialEmailSlideViewDidComplete(_ slideView: TutorialEmailSlideViewController){
        presentTutorialTrySlide()
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

extension TutorialNavigationController: TutorialTrySlideViewControllerDelegate {
    private func presentTutorialTrySlide() {
        let tryItOut = TutorialTrySlideViewController()
        tryItOut.delegate = self
        pushViewController(tryItOut, animated: true)
    }
    
    func tutorialTrySlideViewDidSkip(_ slideView: TutorialTrySlideViewController){
        Analytics.trackOnboardingTryItOutSkipped()
        tutorialTrySlideViewDidComplete(slideView)
        AppDelegate.shared.shouldLoadDiscoverNextLoad = true
    }
    
    func tutorialTrySlideViewDidComplete(_ slideView: TutorialTrySlideViewController){
        Analytics.trackOnboardingTryItOutScreenshot()
        slideView.delegate = nil
        tutorialCompleted()
    }
}
