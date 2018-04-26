//
//  CheckoutOrderViewController.swift
//  screenshot
//
//  Created by Corey Werner on 4/9/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import CreditCardValidator
import CoreData

class CheckoutOrderViewController: BaseViewController {
    fileprivate var card: Card?
    fileprivate var shippingAddress: ShippingAddress?
    fileprivate var confirmPaymentViewController: CheckoutConfirmPaymentViewController?
    fileprivate var cartItems: [CartItem]?
    fileprivate var cardFrc: FetchedResultsControllerManager<Card>?
    fileprivate var shippingAddressFrc: FetchedResultsControllerManager<ShippingAddress>?
    var cvvMap: (url: URL, cvv: String)?
    
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
        
        cardFrc = DataModel.sharedInstance.cardFrc(delegate: self)
        shippingAddressFrc = DataModel.sharedInstance.shippingAddressFrc(delegate: self)
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
        _view.estimateTaxLabel.text = formattedPrice(taxTotal)
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
        
        syncPrimaryCard()
        syncPrimaryShippingAddress()
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
        guard let card = card else {
            presentNeedsPrimaryCardAlert()
            return
        }
        
        guard let shippingAddress = shippingAddress else {
            presentNeedsPrimaryShippingAddressAlert()
            return
        }
        
        let selectedCardURL = UserDefaults.standard.url(forKey: Constants.checkoutPrimaryCardURL)
        
        if let cvvMap = cvvMap, cvvMap.url == selectedCardURL {
            _view.orderButton.isLoading = true
            _view.orderButton.isEnabled = false
            
            ShoppingCartModel.shared.nativeCheckout(card: card, shippingAddress: shippingAddress)
                .then { [weak self] someBool -> Void in
                    self?.navigationController?.pushViewController(CheckoutConfirmationViewController(), animated: true)
                }
                .catch { [weak self] error in
                    // TODO: handle this
                    TapticHelper.nope()
                }
                .always { [weak self] in
                    self?._view.orderButton.isLoading = false
                    self?._view.orderButton.isEnabled = true
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
        
        guard let card = card else {
            dismiss(animated: true, completion: nil)
            confirmPaymentViewController = nil
            presentNeedsPrimaryCardAlert()
            return
        }
        
        guard let shippingAddress = shippingAddress else {
            dismiss(animated: true, completion: nil)
            confirmPaymentViewController = nil
            presentNeedsPrimaryShippingAddressAlert()
            return
        }
        
        confirmPaymentViewController?.orderButton.isLoading = true
        confirmPaymentViewController?.orderButton.isEnabled = false
        
        card.cvv = cvv
        
        ShoppingCartModel.shared.nativeCheckout(card: card, shippingAddress: shippingAddress)
            .then { [weak self] someBool -> Void in
                self?.dismiss(animated: true, completion: nil)
                self?.confirmPaymentViewController = nil
                self?.navigationController?.pushViewController(CheckoutConfirmationViewController(), animated: true)
            }
            .catch { [weak self] error in
                // TODO: handle this
                TapticHelper.nope()
            }
            .always { [weak self] in
                self?.confirmPaymentViewController?.orderButton.isLoading = false
                self?.confirmPaymentViewController?.orderButton.isEnabled = true
        }
    }
    
    @objc fileprivate func confirmCancelAction() {
        dismiss(animated: true, completion: nil)
        confirmPaymentViewController = nil
        
        // TODO: analytics
    }
    
    // MARK: Primary Selection
    
    fileprivate func syncPrimaryCard() {
        self.card = nil
        _view.cardLabel.text = nil
        
        // There is a race condition with savign the first card and the view appearing.
        // If the FRC has only one item, use that as the primary.
        var card: Card?
        
        if let cardURL = UserDefaults.standard.url(forKey: Constants.checkoutPrimaryCardURL),
            let objectID = DataModel.sharedInstance.mainMoc().objectId(for: cardURL)
        {
            card = DataModel.sharedInstance.mainMoc().cardWith(objectId: objectID)
        }
        else if cardFrc?.fetchedObjectsCount == 1 {
            card = cardFrc?.fetchedObjects.first
        }
        
        if let card = card {
            self.card = card
            
            if let displayNumber = card.displayNumber,
                let cardNumber = CreditCardValidator.shared.lastComponentNumber(displayNumber)
            {
                let brand: String = {
                    if let brand = card.brand, !brand.isEmpty {
                        return brand
                    }
                    else {
                        return "Card"
                    }
                }()
                
                _view.cardLabel.text = "\(brand) ending in …\(cardNumber)"
            }
        }
    }
    
    fileprivate func syncPrimaryShippingAddress() {
        self.shippingAddress = nil
        _view.nameLabel.text = nil
        _view.addressLabel.text = nil
        
        var shippingAddress: ShippingAddress?
        
        if let shippingURL = UserDefaults.standard.url(forKey: Constants.checkoutPrimaryAddressURL),
            let objectID = DataModel.sharedInstance.mainMoc().objectId(for: shippingURL)
        {
            shippingAddress = DataModel.sharedInstance.mainMoc().shippingAddressWith(objectId: objectID)
        }
        else if shippingAddressFrc?.fetchedObjectsCount == 1 {
            shippingAddress = shippingAddressFrc?.fetchedObjects.first
        }
        
        if let shippingAddress = shippingAddress {
            self.shippingAddress = shippingAddress
            _view.nameLabel.text = shippingAddress.fullName
            _view.addressLabel.text = shippingAddress.readableAddress
        }
    }
    
    // MARK: Alerts
    
    fileprivate func presentNeedsPrimaryCardAlert() {
        let alertController = UIAlertController(title: "Add A Card", message: "Select a credit card to complete your purchase.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "generic.ok".localized, style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func presentNeedsPrimaryShippingAddressAlert() {
        let alertController = UIAlertController(title: "Add A Shipping Address", message: "Let us know where to send your items!", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "generic.ok".localized, style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
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

extension CheckoutOrderViewController: FetchedResultsControllerManagerDelegate {
    func managerDidChangeContent(_ controller: NSObject, change: FetchedResultsControllerManagerChange) {
        if isViewLoaded {
            if controller == cardFrc {
                syncPrimaryCard()
            }
            else if controller == shippingAddressFrc {
                syncPrimaryShippingAddress()
            }
        }
    }
}
