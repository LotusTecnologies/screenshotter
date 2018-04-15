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
        guard let checkoutPaymentFormViewController = checkoutPaymentFormViewController,
            let shipRow = checkoutPaymentFormViewController.form.map?[CheckoutPaymentFormKeys.addressShip.rawValue]
            else {
                return
        }
        
        if let cvvRow = checkoutPaymentFormViewController.form.map?[CheckoutPaymentFormKeys.cardCVV.rawValue] {
            cvv = cvvRow.value
        }
        
        let isShipToSameAddressChecked = FormRow.Checkbox.bool(for: shipRow.value)
        
        if isShipToSameAddressChecked {
            navigateToCheckoutOrder()
        }
        else {
            navigateToCheckoutShippingForm()
        }
        
        //        checkoutPaymentFormViewController = nil // ???: when should the vc be removed
    }
    
    // MARK: Navigation
    
    @objc private func dismissViewController() {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func navigateToCheckoutPaymentForm() {
        let checkoutPaymentFormViewController = CheckoutPaymentFormViewController()
        checkoutPaymentFormViewController.hidesBottomBarWhenPushed = true
        checkoutPaymentFormViewController.doneButton.addTarget(self, action: #selector(paymentFormCompleted), for: .touchUpInside)
        pushViewController(checkoutPaymentFormViewController, animated: true)
        
        self.checkoutPaymentFormViewController = checkoutPaymentFormViewController
    }
    
    fileprivate func navigateToCheckoutShippingForm() {
        pushViewController(CheckoutShippingFormViewController(), animated: true)
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
        let hasPrimaryCard = false // TODO:
        
        if hasPrimaryCard {
            navigateToCheckoutOrder()
        }
        else {
            navigateToCheckoutPaymentForm()
        }
    }
}
