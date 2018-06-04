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
        
        let registerViewController = RegisterViewController()
        registerViewController.delegate = self
        pushViewController(registerViewController, animated: true)
    }
}

extension TutorialNavigationController: RegisterViewControllerDelegate {
    func registerViewControllerDidSkip(_ viewController: RegisterViewController) {
        pushTutorialTrySlide()
    }
    
    func registerViewControllerDidLogin(_ viewController: RegisterViewController) {
        tutorialCompleted()
    }
    
    func registerViewControllerDidSignup(_ viewController: RegisterViewController) {
        presentRegisterConfirmationViewController(navigateToDetails: true)
    }
    
    func registerViewControllerDidFacebookLogin(_ viewController: RegisterViewController) {
        tutorialCompleted()
    }
    
    func registerViewControllerDidFacebookSignup(_ viewController: RegisterViewController) {
        presentRegisterConfirmationViewController()
    }
    
    private func presentRegisterConfirmationViewController(navigateToDetails: Bool = false) {
        let selector = navigateToDetails ? #selector(dismissRegisterNavigateToDetails) : #selector(dismissRegisterNavigateToTry)
        let tapGesture = UITapGestureRecognizer(target: self, action: selector)
        
        let registerConfirmationViewController = RegisterConfirmationViewController()
        registerConfirmationViewController.view.addGestureRecognizer(tapGesture)
        present(registerConfirmationViewController, animated: true)
        
        Timer.scheduledTimer(timeInterval: 3, target: self, selector: selector, userInfo: nil, repeats: false)
    }
    
    @objc private func dismissRegisterNavigateToDetails() {
        if let viewController = presentedViewController as? RegisterConfirmationViewController,
            !viewController.isBeingDismissed
        {
            dismiss(animated: true)
            pushOnboardingDetailsViewController()
        }
    }
    
    @objc private func dismissRegisterNavigateToTry() {
        if let viewController = presentedViewController as? RegisterConfirmationViewController,
            !viewController.isBeingDismissed
        {
            dismiss(animated: true)
            pushTutorialTrySlide()
        }
    }
}

extension TutorialNavigationController: OnboardingDetailsViewControllerDelegate {
    private func pushOnboardingDetailsViewController() {
        let onboardingDetailsViewController = OnboardingDetailsViewController()
        onboardingDetailsViewController.delegate = self
        pushViewController(onboardingDetailsViewController, animated: true)
    }
    
    func onboardingDetailsViewControllerDidSkip(_ viewController: OnboardingDetailsViewController) {
        pushTutorialTrySlide()
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
            pushTutorialTrySlide()
        }
        else {
            let alertController = UIAlertController(title: "onboarding.details.save_alert.title".localized, message: "onboarding.details.save_alert.message".localized, preferredStyle: .alert)
            let continueAction = UIAlertAction(title: "generic.continue".localized, style: .default, handler: { alertAction in
                saveData()
                self.pushTutorialTrySlide()
            })
            alertController.addAction(continueAction)
            alertController.addAction(UIAlertAction(title: "generic.cancel".localized, style: .cancel, handler: nil))
            alertController.preferredAction = continueAction
            present(alertController, animated: true)
        }
    }
}

extension TutorialNavigationController: TutorialTrySlideViewControllerDelegate {
    private func pushTutorialTrySlide() {
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
