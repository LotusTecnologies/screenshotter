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
    fileprivate var checkoutPaymentViewController: CheckoutPaymentViewController?
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        restorationIdentifier = String(describing: type(of: self))
        
        // !!!: DEBUG
        
        let checkoutPaymentViewController = CheckoutPaymentViewController()
        checkoutPaymentViewController.doneButton.addTarget(self, action: #selector(paymentDoneAction), for: .touchUpInside)
        self.checkoutPaymentViewController = checkoutPaymentViewController
        
        viewControllers = [
            CheckoutOrderViewController(),
//            CheckoutPaymentListViewController(),
//            CheckoutShippingListViewController(),
//            checkoutPaymentViewController,
//            cartViewController
        ]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .background
    }
    
    // MARK:
    
    @objc fileprivate func paymentDoneAction() {
        guard let checkoutPaymentViewController = checkoutPaymentViewController,
            let shipRow = checkoutPaymentViewController.form.map?[CheckoutPaymentFormKeys.addressShip.rawValue]
            else {
                return
        }
        
        let isShipToSameAddressChecked = FormRow.Checkbox.bool(for: shipRow.value)
        
        if isShipToSameAddressChecked {
            
        }
        else {
            pushViewController(CheckoutShippingViewController(), animated: true)
        }
        
        //        self.checkoutPaymentViewController = nil // ???: when should the vc be removed
    }
}
