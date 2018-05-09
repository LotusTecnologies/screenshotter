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
    fileprivate var cvvMap: (url: URL, cvv: String)?
    fileprivate var isPriceAtLeast50 = false
    
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
    
    // MARK: Navigation
    
    @objc private func dismissViewController() {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func navigateToCheckoutPaymentForm() {
        let backBarButtonItem = UIBarButtonItem()
        backBarButtonItem.title = cartViewController.title
        
        let checkoutPaymentFormViewController = CheckoutPaymentFormViewController()
        checkoutPaymentFormViewController.delegate = self
        checkoutPaymentFormViewController.hidesBottomBarWhenPushed = true
        checkoutPaymentFormViewController.navigationItem.backBarButtonItem = backBarButtonItem
        pushViewController(checkoutPaymentFormViewController, animated: true)
    }
    
    fileprivate func navigateToCheckoutShippingForm() {
        let backBarButtonItem = UIBarButtonItem()
        backBarButtonItem.title = cartViewController.title
        
        let checkoutShippingFormViewController = CheckoutShippingFormViewController()
        checkoutShippingFormViewController.delegate = self
        checkoutShippingFormViewController.hidesBottomBarWhenPushed = true
        checkoutShippingFormViewController.navigationItem.backBarButtonItem = backBarButtonItem
        pushViewController(checkoutShippingFormViewController, animated: true)
    }
    
    fileprivate func navigateToCheckoutOrder() {
        let checkoutOrderViewController = CheckoutOrderViewController()
        checkoutOrderViewController.cvvMap = cvvMap
        checkoutOrderViewController.isPriceAtLeast50 = isPriceAtLeast50
        checkoutOrderViewController.hidesBottomBarWhenPushed = true
        pushViewController(checkoutOrderViewController, animated: true)
        
        cvvMap = nil
    }
}

extension CartNavigationController: CheckoutFormViewControllerDelegate {
    func checkoutFormViewControllerDidAdd(_ viewController: CheckoutFormViewController) {
        if let checkout = viewController as? CheckoutPaymentFormViewController {
            let cart = DataModel.sharedInstance.retrieveAddableCart(managedObjectContext: DataModel.sharedInstance.mainMoc())
            Analytics.trackCartCreditCardAdded(cart: cart, source: .manual)
            
            let addressShip = checkout.formRow(.addressShip)?.value
            let isShipToSameAddressChecked = FormRow.Checkbox.bool(for: addressShip)
            
            if let url = DataModel.sharedInstance.selectedCardURL,
                let cvv = checkout.formRow(.cardCVV)?.value
            {
                cvvMap = (url: url, cvv: cvv)
            }
            
            if isShipToSameAddressChecked || DataModel.sharedInstance.hasShippingAddresses() {
                navigateToCheckoutOrder()
            }
            else {
                navigateToCheckoutShippingForm()
            }
        }
        else if let _ = viewController as? CheckoutShippingFormViewController {
            let cart = DataModel.sharedInstance.retrieveAddableCart(managedObjectContext: DataModel.sharedInstance.mainMoc())
            Analytics.trackCartShippingAdded(cart: cart, source: .manual)

            navigateToCheckoutOrder()
        }
    }
    func checkoutFormViewControllerDidEdit(_ viewController: CheckoutFormViewController) {
        if let _ = viewController as? CheckoutPaymentFormViewController {
            let cart = DataModel.sharedInstance.retrieveAddableCart(managedObjectContext: DataModel.sharedInstance.mainMoc())
            Analytics.trackCartCreditCardEdited(cart: cart)
            
        }
        else if let _ = viewController as? CheckoutShippingFormViewController {
            let cart = DataModel.sharedInstance.retrieveAddableCart(managedObjectContext: DataModel.sharedInstance.mainMoc())
            Analytics.trackCartShippingEdited(cart: cart)
        }
    }
    
    func checkoutFormViewControllerDidRemove(_ viewController: CheckoutFormViewController) {
        if let _ = viewController as? CheckoutPaymentFormViewController {
            let cart = DataModel.sharedInstance.retrieveAddableCart(managedObjectContext: DataModel.sharedInstance.mainMoc())
            Analytics.trackCartCreditCardRemoved(cart: cart)
            
        }
        else if let _ = viewController as? CheckoutShippingFormViewController {
            let cart = DataModel.sharedInstance.retrieveAddableCart(managedObjectContext: DataModel.sharedInstance.mainMoc())
            Analytics.trackCartShippingRemoved(cart: cart)
        }
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
        let cart = DataModel.sharedInstance.retrieveAddableCart(managedObjectContext: DataModel.sharedInstance.mainMoc())
        isPriceAtLeast50 = viewController.isPriceAtLeast50
        
        if hasCard && hasAddress {
            Analytics.trackCartPressedCheckoutValidated(cart: cart, result: .continue)
            navigateToCheckoutOrder()
        }
        else if hasCard {
            Analytics.trackCartPressedCheckoutValidated(cart: cart, result: .needsShippingAddress)
            navigateToCheckoutShippingForm()
        }
        else {
            Analytics.trackCartPressedCheckoutValidated(cart: cart, result: .needsCreditCard)
            navigateToCheckoutPaymentForm()
        }
    }
}
