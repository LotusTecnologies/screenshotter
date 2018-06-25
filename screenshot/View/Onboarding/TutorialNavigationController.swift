//
//  TutorialNavigationController.swift
//  screenshot
//
//  Created by Corey Werner on 10/14/17.
//  Copyright (c) 2017 crazeapp. All rights reserved.
//

import UIKit

@objc protocol TutorialNavigationControllerDelegate : class {
    func tutorialNavigationControllerDidComplete(_ viewController: TutorialNavigationController)
}

class TutorialNavigationController : UINavigationController {
    weak var tutorialDelegate: TutorialNavigationControllerDelegate?
    var showProfilePage = false
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        let registerVC = RegisterViewController.init()
        registerVC.delegate = self
        registerVC.isOnboardingLayout = true
        viewControllers = [registerVC]
        
        view.backgroundColor = .white
        self.isNavigationBarHidden = true
        self.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Analytics.trackStartedOnboarding()
    }
    
    private func tutorialCompleted() {
        AppDelegate.shared.shouldLoadDiscoverNextLoad = true
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

extension TutorialNavigationController: RegisterViewControllerDelegate {
    func registerViewControllerDidSkip(_ viewController: RegisterViewController) {
        pushGDPRViewController()
        Analytics.trackOnboardingSkipped()
    }
    
    func registerViewControllerNeedEmailConfirmation(_ viewController: RegisterViewController) {
        let confirm = ConfirmCodeViewController()
        confirm.email = viewController.email
        confirm.delegate = self
        self.pushViewController(confirm, animated: true)
        Analytics.trackOnboardingRegisterEmailSent()
    }
    
    func registerViewControllerDidSignin(_ viewController: RegisterViewController) {
        pushGDPRViewController()
        Analytics.trackOnboardingLoginSucess()
    }
    
    func registerViewControllerDidFacebookLogin(_ viewController: RegisterViewController) {
        pushGDPRViewController()
        Analytics.trackOnboardingFacebookSuccess(isReturning: true)
    }
    
    func registerViewControllerDidFacebookSignup(_ viewController: RegisterViewController) {
        showProfilePage = true
        self.presentRegisterConfirmationViewController()
        Analytics.trackOnboardingFacebookSuccess(isReturning: false)
        
    }
    private func pushGDPRViewController() {
        let vc = OnboardingGDPRViewController.init()
        vc.delegate = self
        self.pushViewController(vc, animated: true)
    }
}

extension TutorialNavigationController : OnboardingGDPRViewControllerDelegate {
    func onboardingGDPRViewControllerDidComplete(_ viewController: OnboardingGDPRViewController) {
        if showProfilePage {
            pushOnboardingDetailsViewController()
        }else{
            tutorialCompleted()
        }
    }
}

extension TutorialNavigationController : ConfirmCodeViewControllerDelegate {
    
    func confirmCodeViewControllerDidConfirm(_ viewController: ConfirmCodeViewController){
        Analytics.trackOnboardingRegisterSucess()
        showProfilePage = true
        self.presentRegisterConfirmationViewController()
    }
    func confirmCodeViewControllerDidCancel(_ viewController: ConfirmCodeViewController){
        Analytics.trackOnboardingRegisterEmailCancel()
        self.popViewController(animated: true)
    }
    
    private func presentRegisterConfirmationViewController() {
        let selector = #selector(dismissRegisterNavigateToGDPR)
        let tapGesture = UITapGestureRecognizer(target: self, action: selector)
        
        let registerConfirmationViewController = RegisterConfirmationViewController()
        registerConfirmationViewController.view.addGestureRecognizer(tapGesture)
        present(registerConfirmationViewController, animated: true)
        
        Timer.scheduledTimer(timeInterval: 3, target: self, selector: selector, userInfo: nil, repeats: false)
    }
    
    @objc private func dismissRegisterNavigateToGDPR() {
        if let viewController = presentedViewController as? RegisterConfirmationViewController,
            !viewController.isBeingDismissed
        {
            dismiss(animated: true)
            pushGDPRViewController()
        }
    }
    

}

extension TutorialNavigationController: OnboardingDetailsViewControllerDelegate {
    private func pushOnboardingDetailsViewController() {
        let onboardingDetailsViewController = OnboardingDetailsViewController()
        onboardingDetailsViewController.delegate = self
        onboardingDetailsViewController._view.nameTextField.text = UserAccountManager.shared.user?.displayName
        pushViewController(onboardingDetailsViewController, animated: true)
    }
    
    func onboardingDetailsViewControllerDidSkip(_ viewController: OnboardingDetailsViewController) {
        Analytics.trackOnboardingProfileSkip()
        tutorialCompleted()
    }
    
    func onboardingDetailsViewControllerDidContinue(_ viewController: OnboardingDetailsViewController) {
        let name = viewController.name
        let gender = viewController.gender
        let size = viewController.size
        
        func saveData() {
            UserAccountManager.shared.setProfile(displayName: name, gender: gender, size: size, unverifiedEmail: nil)
            Analytics.trackOnboardingProfileSubmit(name: name, gender: gender, size: size)
        }
        
        if name != nil && gender != nil && size != nil {
            saveData()
            tutorialCompleted()
        }
        else {
            let alertController = UIAlertController(title: "onboarding.details.save_alert.title".localized, message: "onboarding.details.save_alert.message".localized, preferredStyle: .alert)
            let continueAction = UIAlertAction(title: "generic.continue".localized, style: .default, handler: { alertAction in
                saveData()
                self.tutorialCompleted()
            })
            alertController.addAction(continueAction)
            alertController.addAction(UIAlertAction(title: "generic.cancel".localized, style: .cancel, handler: nil))
            alertController.preferredAction = continueAction
            present(alertController, animated: true)
        }
    }
}
