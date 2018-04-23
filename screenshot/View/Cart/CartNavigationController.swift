//
//  CartNavigationController.swift
//  screenshot
//
//  Created by Corey Werner on 2/19/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class CartNavigationController: UINavigationController {
    let cartViewController = CartViewController()
    fileprivate var checkoutPaymentFormViewController: CheckoutPaymentFormViewController?
    fileprivate var checkoutShippingFormViewController: CheckoutShippingFormViewController?
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        restorationIdentifier = String(describing: type(of: self))
        delegate = self
        
        cartViewController.delegate = self
        
        viewControllers = [
            cartViewController
        ]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .background
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if presentingViewController != nil {
            let dismissBarButtonItem = UIBarButtonItem(title: "generic.cancel".localized, style: .plain, target: nil, action: nil)
            dismissBarButtonItem.target = self
            dismissBarButtonItem.action = #selector(dismissViewController)
            cartViewController.navigationItem.leftBarButtonItem = dismissBarButtonItem
        }
    }
    
    deinit {
        cartViewController.delegate = nil
    }
    
    // MARK: Form
    
    @objc fileprivate func paymentFormCompleted() {
        guard let checkout = checkoutPaymentFormViewController,
            checkout.form.hasRequiredFields
            else {
                // TODO: highlight error fields
                return
        }
        
        let addressShip = checkout.formRow(.addressShip)?.value
        let isShipToSameAddressChecked = FormRow.Checkbox.bool(for: addressShip)
        
        let canSave = checkout.addCard { [weak self] didSave in
            if isShipToSameAddressChecked || DataModel.sharedInstance.hasShippingAddresses() {
                self?.navigateToCheckoutOrder()
            }
            else {
                self?.navigateToCheckoutShippingForm()
            }
        }
        
        if canSave {
            checkoutPaymentFormViewController = nil
        }
    }
    
    @objc fileprivate func shippingFormCompleted() {
        guard let shipping = checkoutShippingFormViewController,
            shipping.form.hasRequiredFields
            else {
                // TODO: highlight error fields
                return
        }
        
        let didSave = shipping.addShippingAddress()
        
        if didSave {
            navigateToCheckoutOrder()
            checkoutShippingFormViewController = nil
        }
    }
    
    // MARK: Navigation
    
    @objc private func dismissViewController() {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func navigateToCheckoutPaymentForm() {
        let backBarButtonItem = UIBarButtonItem()
        backBarButtonItem.title = cartViewController.title
        
        let checkoutPaymentFormViewController = CheckoutPaymentFormViewController()
        checkoutPaymentFormViewController.hidesBottomBarWhenPushed = true
        checkoutPaymentFormViewController.navigationItem.backBarButtonItem = backBarButtonItem
        checkoutPaymentFormViewController.continueButton.addTarget(self, action: #selector(paymentFormCompleted), for: .touchUpInside)
        pushViewController(checkoutPaymentFormViewController, animated: true)
        
        self.checkoutPaymentFormViewController = checkoutPaymentFormViewController
    }
    
    fileprivate func navigateToCheckoutShippingForm() {
        let backBarButtonItem = UIBarButtonItem()
        backBarButtonItem.title = cartViewController.title
        
        let checkoutShippingFormViewController = CheckoutShippingFormViewController()
        checkoutShippingFormViewController.hidesBottomBarWhenPushed = true
        checkoutShippingFormViewController.navigationItem.backBarButtonItem = backBarButtonItem
        checkoutShippingFormViewController.continueButton.addTarget(self, action: #selector(shippingFormCompleted), for: .touchUpInside)
        pushViewController(checkoutShippingFormViewController, animated: true)
        
        self.checkoutShippingFormViewController = checkoutShippingFormViewController
    }
    
    fileprivate func navigateToCheckoutOrder() {
        let checkoutOrderViewController = CheckoutOrderViewController()
        checkoutOrderViewController.hidesBottomBarWhenPushed = true
        pushViewController(checkoutOrderViewController, animated: true)
    }
}

extension CartNavigationController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if viewController.isKind(of: CheckoutShippingFormViewController.self) {
            removeFormViewControllerFromStack([
                CheckoutPaymentFormViewController.self
                ])
        }
        else if viewController.isKind(of: CheckoutOrderViewController.self) {
            removeFormViewControllerFromStack([
                CheckoutPaymentFormViewController.self,
                CheckoutShippingFormViewController.self
                ])
        }
    }
    
    private func removeFormViewControllerFromStack(_ formViewControllerTypes: [CheckoutFormViewController.Type]) {
        for i in viewControllers.startIndex..<viewControllers.endIndex {
            let viewController = viewControllers[i]
            
            for formViewControllerType in formViewControllerTypes {
                if viewController.isKind(of: formViewControllerType) {
                    var vcs = viewControllers
                    vcs.remove(at: i)
                    setViewControllers(vcs, animated: false)
                    break
                }
            }
        }
    }
}

extension CartNavigationController: CartViewControllerDelegate {
    func cartViewControllerDidValidateCart(_ viewController: CartViewController) {
        let hasCard = DataModel.sharedInstance.hasSavedCards()
        let hasAddress = DataModel.sharedInstance.hasShippingAddresses()
        
        if hasCard && hasAddress {
            navigateToCheckoutOrder()
        }
        else if hasCard {
            navigateToCheckoutShippingForm()
        }
        else {
            navigateToCheckoutPaymentForm()
        }
    }
}
