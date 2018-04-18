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
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        restorationIdentifier = String(describing: type(of: self))
        
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
    
    private var cvv: String?
    
    @objc fileprivate func paymentFormCompleted() {
        guard let checkout = checkoutPaymentFormViewController,
            checkout.hasRequiredFields,
            let cardCVV = checkout.formRow(.cardCVV)?.value,
            let addressShip = checkout.formRow(.addressShip)?.value
            else {
                // TODO: highlight error fields
                return
        }
        
        cvv = cardCVV
        
        func performAction(withSavingCard saveCard: Bool) {
            checkout.addCard(shouldSave: saveCard)
            
            let isShipToSameAddressChecked = FormRow.Checkbox.bool(for: addressShip)
            
            if isShipToSameAddressChecked {
                navigateToCheckoutOrder()
            }
            else {
                navigateToCheckoutShippingForm()
            }
        }
        
        let alertController = UIAlertController(title: "Save Card?", message: "You can use this for future purchases. Your information is saved securely on your device.", preferredStyle: .alert)
        let saveAlertAction = UIAlertAction(title: "Save", style: .default) { alertAction in
            performAction(withSavingCard: true)
        }
        alertController.addAction(saveAlertAction)
        alertController.addAction(UIAlertAction(title: "Don't Save", style: .cancel, handler: { alertAction in
            performAction(withSavingCard: false)
        }))
        alertController.preferredAction = saveAlertAction
        present(alertController, animated: true, completion: nil)
        
        //        checkoutPaymentFormViewController = nil // ???: when should the vc be removed
    }
    
    @objc fileprivate func shippingFormCompleted() {
//        DataModel.sharedInstance.saveShippingAddress(firstName: <#T##String?#>, lastName: <#T##String?#>, street: <#T##String#>, city: <#T##String#>, country: <#T##String#>, zipCode: <#T##String#>, state: <#T##String?#>, phone: <#T##String#>)
    }
    
    // MARK: Navigation
    
    @objc private func dismissViewController() {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func navigateToCheckoutPaymentForm() {
        let checkoutPaymentFormViewController = CheckoutPaymentFormViewController()
        checkoutPaymentFormViewController.hidesBottomBarWhenPushed = true
        checkoutPaymentFormViewController.continueButton.addTarget(self, action: #selector(paymentFormCompleted), for: .touchUpInside)
        pushViewController(checkoutPaymentFormViewController, animated: true)
        
        self.checkoutPaymentFormViewController = checkoutPaymentFormViewController
    }
    
    fileprivate func navigateToCheckoutShippingForm() {
        let checkoutShippingFormViewController = CheckoutShippingFormViewController()
        checkoutShippingFormViewController.continueButton.addTarget(self, action: #selector(shippingFormCompleted), for: .touchUpInside)
        pushViewController(checkoutShippingFormViewController, animated: true)
    }
    
    fileprivate func navigateToCheckoutOrder() {
        let checkoutOrderViewController = CheckoutOrderViewController()
        checkoutOrderViewController.cvv = cvv
        checkoutOrderViewController.hidesBottomBarWhenPushed = true
        pushViewController(checkoutOrderViewController, animated: true)
        
        cvv = nil
    }
}

extension CartNavigationController: CartViewControllerDelegate {
    func cartViewControllerDidValidateCart(_ viewController: CartViewController) {
        if DataModel.sharedInstance.hasSavedCards() {
            navigateToCheckoutOrder()
        }
        else {
            navigateToCheckoutPaymentForm()
        }
    }
}
