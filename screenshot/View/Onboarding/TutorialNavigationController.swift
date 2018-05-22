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
        
        let authorizeViewController = AuthorizeViewController()
        authorizeViewController.delegate = self
        pushViewController(authorizeViewController, animated: true)
        
//        let signup = RegisterViewController()
//        pushViewController(signup, animated: true)
        
        // !!!: DEBUG
//        let signup = TutorialEmailSlideViewController()
//        signup.delegate = self
//        self.pushViewController(signup, animated: true)
    }
}

extension TutorialNavigationController: AuthorizeViewControllerDelegate {
    func authorizeViewControllerDidSkip(_ viewController: AuthorizeViewController) {
        let tryItOut = TutorialTrySlideViewController()
        tryItOut.delegate = self
        pushViewController(tryItOut, animated: true)
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

