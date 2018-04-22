//
//  CheckoutOrderViewController.swift
//  screenshot
//
//  Created by Corey Werner on 4/9/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import CreditCardValidator

class CheckoutOrderViewController: BaseViewController {
    var cvv: String?
    var confirmPaymentViewController: CheckoutConfirmPaymentViewController?
    fileprivate var cartItems: [CartItem]?
    
    // MARK: View
    
    fileprivate var _view: CheckoutOrderView {
        return view as! CheckoutOrderView
    }
    
    fileprivate var tableView: UITableView {
        return _view.tableView
    }
    
    override func loadView() {
        view = CheckoutOrderView()
    }
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        title = "Place Your Order"
        restorationIdentifier = String(describing: type(of: self))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let cart = DataModel.sharedInstance.retrieveAddableCart(managedObjectContext: DataModel.sharedInstance.mainMoc()) else {
            return
        }
        
        cartItems = (cart.items as? Set<CartItem>)?.sorted(by: { (a, b) -> Bool in
            guard let aDate = a.dateModified, let bDate = b.dateModified else {
                return false
            }
            return aDate > bDate
        })
        
        let localeIdentifier = Locale.identifier(fromComponents: [
            NSLocale.Key.currencyCode.rawValue: "USD",
            NSLocale.Key.languageCode.rawValue: "en"
            ])
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: localeIdentifier)
        
        func formattedPrice(_ price: Float) -> String? {
            return formatter.string(from: NSNumber(value: price))
        }
        
        let shippingAndSubtotal = cart.subtotal + cart.shippingTotal
        let tax: Float = 6
        let taxTotal = (tax / 100) * shippingAndSubtotal
        
        _view.itemsPriceLabel.text = formattedPrice(cart.subtotal)
        _view.shippingPriceLabel.text = formattedPrice(cart.shippingTotal)
        _view.beforeTaxPriceLabel.text = formattedPrice(shippingAndSubtotal)
        _view.estimateTaxLabel.text = "\(tax)%"
        _view.totalPriceLabel.text = formattedPrice(shippingAndSubtotal + taxTotal)
        
        _view.paymentControl.addTarget(self, action: #selector(navigateToPaymentList), for: .touchUpInside)
        _view.shippingControl.addTarget(self, action: #selector(navigateToShippingList), for: .touchUpInside)
        _view.orderButton.addTarget(self, action: #selector(orderAction), for: .touchUpInside)
        _view.cancelButton.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)
        
        // TODO: remove the tableview since its not being used for it reuse functionality. insert normal views
        tableView.dataSource = self
        tableView.register(CheckoutOrderItemTableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let shippingURL = UserDefaults.standard.url(forKey: Constants.checkoutPrimaryAddressURL),
            let objectID = DataModel.sharedInstance.mainMoc().objectId(for: shippingURL),
            let shipping = DataModel.sharedInstance.mainMoc().shippingAddressWith(objectId: objectID)
        {
            _view.nameLabel.text = shipping.fullName
            _view.addressLabel.text = shipping.readableAddress
        }
        
        if let cardURL = UserDefaults.standard.url(forKey: Constants.checkoutPrimaryCardURL),
            let objectID = DataModel.sharedInstance.mainMoc().objectId(for: cardURL),
            let card = DataModel.sharedInstance.mainMoc().cardWith(objectId: objectID),
            let displayNumber = card.displayNumber,
            let cardNumber = CreditCardValidator.shared.lastComponentNumber(displayNumber)
        {
            let brand = "Visa" // TODO:
            _view.cardLabel.text = "\(brand) ending in …\(cardNumber)"
        }
    }
    
    deinit {
        tableView.dataSource = nil
    }
    
    // MARK: Navigation
    
    @objc fileprivate func navigateToPaymentList() {
        let paymentListViewController = CheckoutPaymentListViewController()
        navigationController?.pushViewController(paymentListViewController, animated: true)
    }
    
    @objc fileprivate func navigateToShippingList() {
        let shippingListViewController = CheckoutShippingListViewController()
        navigationController?.pushViewController(shippingListViewController, animated: true)
    }
    
    // MARK: Order
    
    @objc fileprivate func orderAction() {
        if let cvv = cvv {
            _view.orderButton.isLoading = true
            _view.orderButton.isEnabled = false
            
            // TODO: make model request to validate card and place order.
            func pseudoValidateOrder(_ callback: @escaping (Bool)->()) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    callback(true)
                }
            }
            
            pseudoValidateOrder { [weak self] isValid in
                self?._view.orderButton.isLoading = false
                self?._view.orderButton.isEnabled = true
                
                if isValid {
                    self?.navigationController?.pushViewController(CheckoutConfirmationViewController(), animated: true)
                }
                else {
                    // TODO: display errors
                }
            }
        }
        else {
            let confirmPaymentViewController = CheckoutConfirmPaymentViewController()
            confirmPaymentViewController.orderButton.addTarget(self, action: #selector(confirmOrderAction), for: .touchUpInside)
            confirmPaymentViewController.cancelButton.addTarget(self, action: #selector(confirmCancelAction), for: .touchUpInside)
            present(confirmPaymentViewController, animated: true, completion: nil)
            self.confirmPaymentViewController = confirmPaymentViewController
        }
    }
    
    @objc fileprivate func cancelAction() {
        if tabBarController != nil {
            MainTabBarController.resetViewControllerHierarchy(self, select: .screenshots)
        }
        else {
            presentingViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc fileprivate func confirmOrderAction() {
        guard let cvv = confirmPaymentViewController?.cvvTextField.text, !cvv.isEmpty else {
            confirmPaymentViewController?.displayCVVError()
            return
        }
        
        confirmPaymentViewController?.orderButton.isLoading = true
        confirmPaymentViewController?.orderButton.isEnabled = false
        
        // TODO: make model request to validate card and place order.
        func pseudoValidateOrder(_ callback: @escaping (Bool)->()) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                callback(true)
            }
        }
        
        pseudoValidateOrder { [weak self] isValid in
            self?.confirmPaymentViewController?.orderButton.isLoading = false
            self?.confirmPaymentViewController?.orderButton.isEnabled = true
            
            if isValid {
                self?.dismiss(animated: true, completion: nil)
                self?.confirmPaymentViewController = nil
                self?.navigationController?.pushViewController(CheckoutConfirmationViewController(), animated: true)
            }
            else {
                // TODO: display errors
//                confirmPaymentViewController?.displayCVVError()
            }
        }
    }
    
    @objc fileprivate func confirmCancelAction() {
        dismiss(animated: true, completion: nil)
    }
}

extension CheckoutOrderViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cartItems?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        if let cell = cell as? CheckoutOrderItemTableViewCell, let cartItem = cartItems?[indexPath.row] {
            cell.productImageView.setImage(withURLString: cartItem.imageURL)
            cell.titleLabel.text = cartItem.productTitle()
            cell.detailLabel.text = productDescription(cartItem)
        }
        
        return cell
    }
    
    private func productDescription(_ cartItem: CartItem) -> String {
        var description = "Qty: \(Int(cartItem.quantity))"
        
        if let color = cartItem.color {
            description += ", Color: \(color)"
        }
        if let size = cartItem.size {
            description += ", Size: \(size)"
        }
        
        return description
    }
}
