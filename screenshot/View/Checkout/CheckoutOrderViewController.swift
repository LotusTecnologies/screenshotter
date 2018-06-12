//
//  CheckoutOrderViewController.swift
//  screenshot
//
//  Created by Corey Werner on 4/9/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
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
    var isGiftCardRedeemable = false
    
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
        
        title = "checkout.order.title".localized
        restorationIdentifier = String(describing: type(of: self))
        
        cardFrc = DataModel.sharedInstance.cardFrc(delegate: self)
        shippingAddressFrc = DataModel.sharedInstance.shippingAddressFrc(delegate: self)
        
        let backBarButtonItem = UIBarButtonItem()
        backBarButtonItem.title = ""
        navigationItem.backBarButtonItem = backBarButtonItem
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
        

        _view.itemsPriceLabel.text = formattedPrice(cart.subtotal)
        _view.shippingPriceLabel.text = formattedPrice(cart.shippingTotal)
        _view.beforeTaxPriceLabel.text = formattedPrice(cart.subtotal + cart.shippingTotal)
        _view.estimateTaxLabel.text = formattedPrice(cart.estimatedTax)
        _view.totalPriceLabel.text = formattedPrice(cart.estimatedTotalOrder)
        _view.legalTextView.delegate = self
        
        _view.paymentControl.addTarget(self, action: #selector(navigateToPaymentList), for: .touchUpInside)
        _view.shippingControl.addTarget(self, action: #selector(navigateToShippingList), for: .touchUpInside)
        _view.orderButton.addTarget(self, action: #selector(orderAction), for: .touchUpInside)
        _view.cancelButton.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)
        
        // TODO: remove the tableview since its not being used for it reuse functionality. insert normal views
        tableView.dataSource = self
        tableView.register(CheckoutOrderItemTableViewCell.self, forCellReuseIdentifier: "cell")
        
        let pinchZoom = UIPinchGestureRecognizer.init(target: self, action: #selector(pinch(gesture:)))
        self.view.addGestureRecognizer(pinchZoom)
    }
    
    
    @objc func pinch( gesture:UIPinchGestureRecognizer) {
        if CrazeImageZoom.shared.isHandlingGesture, let imageView = CrazeImageZoom.shared.hostedImageView  {
            CrazeImageZoom.shared.gestureStateChanged(gesture, imageView: imageView)
            return
        }
        let point = gesture.location(in: self.tableView)
        if let indexPath = self.tableView.indexPathForRow(at: point), let cell = self.tableView.cellForRow(at: indexPath) as? CheckoutOrderItemTableViewCell{
            CrazeImageZoom.shared.gestureStateChanged(gesture, imageView: cell.productImageView.imageView)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        syncPrimaryCard()
        syncPrimaryShippingAddress()
    }
    
    deinit {
        tableView.dataSource = nil
        DataModel.sharedInstance.deleteAllTemporaryCards()
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
    
    @objc fileprivate func cancelAction() {
        let cart = DataModel.sharedInstance.retrieveAddableCart(managedObjectContext: DataModel.sharedInstance.mainMoc())
        Analytics.trackCartPressedCancelCheckout(cart: cart)
        if tabBarController != nil {
            MainTabBarController.resetViewControllerHierarchy(self, select: .screenshots)
        }
        else {
            presentingViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: Primary Selection
    
    fileprivate func syncPrimaryCard() {
        self.card = nil
        _view.cardLabel.text = nil
        
        // There is a race condition with savign the first card and the view appearing.
        // If the FRC has only one item, use that as the primary.
        var card: Card?
        
        if let cardURL = DataModel.sharedInstance.selectedCardURL,
            let objectID = DataModel.sharedInstance.mainMoc().objectId(for: cardURL)
        {
            card = DataModel.sharedInstance.mainMoc().cardWith(objectId: objectID)
        }
        
        if card == nil {
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
                        return "checkout.card.default_brand".localized
                    }
                }()
                
                _view.cardLabel.text = "checkout.card.brand_last_digits".localized(withFormat: brand, cardNumber)
            }
        }
    }
    
    fileprivate func syncPrimaryShippingAddress() {
        self.shippingAddress = nil
        _view.nameLabel.text = nil
        _view.addressLabel.text = nil
        
        var shippingAddress: ShippingAddress?
        
        if let shippingURL = DataModel.sharedInstance.selectedShippingAddressURL,
            let objectID = DataModel.sharedInstance.mainMoc().objectId(for: shippingURL)
        {
            shippingAddress = DataModel.sharedInstance.mainMoc().shippingAddressWith(objectId: objectID)
        }
        
        if shippingAddress == nil {
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
        let alertController = UIAlertController(title: "checkout.order.error.card.title".localized, message: "checkout.order.error.card.message".localized, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "generic.ok".localized, style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func presentNeedsPrimaryShippingAddressAlert() {
        let alertController = UIAlertController(title: "checkout.order.error.shipping.title".localized, message: "checkout.order.error.shipping.message".localized, preferredStyle: .alert)
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
        var description = "checkout.order.description.quantity".localized(withFormat: Int(cartItem.quantity))
        
        if let color = cartItem.color {
            description += ", " + "checkout.order.description.color".localized(withFormat: color)
        }
        if let size = cartItem.size {
            description += ", " + "checkout.order.description.size".localized(withFormat: size)
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

extension CheckoutOrderViewController: UITextViewDelegate {
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        switch URL.absoluteString {
        case _view.legalLinkTOS:
            if let viewController = LegalViewControllerFactory.termsOfServiceViewController() {
                present(viewController, animated: true, completion: nil)
            }
            
        default:
            break
        }
        
        return false
    }
}

typealias CheckoutOrderViewControllerOrder = CheckoutOrderViewController
extension CheckoutOrderViewControllerOrder {
    @objc fileprivate func orderAction() {
        let cart = DataModel.sharedInstance.retrieveAddableCart(managedObjectContext: DataModel.sharedInstance.mainMoc())

        guard let card = card else {
            Analytics.trackCartPressedPlaceOrder(cart: cart, result: .needsCreditCard)
            presentNeedsPrimaryCardAlert()
            return
        }
        
        guard let shippingAddress = shippingAddress else {
            Analytics.trackCartPressedPlaceOrder(cart: cart, result: .needsShippingAddress)
            presentNeedsPrimaryShippingAddressAlert()
            return
        }
        
        let selectedCardURL = DataModel.sharedInstance.selectedCardURL
        
        if let cvvMap = cvvMap, cvvMap.url == selectedCardURL {
            Analytics.trackCartPressedPlaceOrder(cart: cart, result: .continue)
            
            performCheckout(with: card, cvv: cvvMap.cvv, shippingAddress: shippingAddress, orderButton: _view.orderButton)
        }
        else {
            Analytics.trackCartPressedPlaceOrder(cart: cart, result: .needsCvv)

            let confirmPaymentViewController = CheckoutConfirmPaymentViewController()
            confirmPaymentViewController.continueButton.addTarget(self, action: #selector(confirmOrderAction), for: .touchUpInside)
            confirmPaymentViewController.cancelButton.addTarget(self, action: #selector(confirmCancelAction), for: .touchUpInside)
            present(confirmPaymentViewController, animated: true, completion: nil)
            self.confirmPaymentViewController = confirmPaymentViewController
        }
    }
    
    @objc fileprivate func confirmOrderAction() {
        let cart = DataModel.sharedInstance.retrieveAddableCart(managedObjectContext: DataModel.sharedInstance.mainMoc())
        
        guard let cvv = confirmPaymentViewController?.cvvTextField.text, !cvv.isEmpty else {
            Analytics.trackCartCvvEntered(cart: cart, result: .cvvInvalidOrEmpty)
            confirmPaymentViewController?.displayCVVError()
            return
        }
        
        guard let card = card else {
            Analytics.trackCartCvvEntered(cart: cart, result: .needsCreditCard)
            dismissConfirmPaymentViewController()
            presentNeedsPrimaryCardAlert()
            return
        }
        
        guard let shippingAddress = shippingAddress else {
            Analytics.trackCartCvvEntered(cart: cart, result: .needsShippingAddress)
            dismissConfirmPaymentViewController()
            presentNeedsPrimaryShippingAddressAlert()
            return
        }
        
        Analytics.trackCartCvvEntered(cart: cart, result: .continue)
        performCheckout(with: card, cvv: cvv, shippingAddress: shippingAddress, orderButton: confirmPaymentViewController?.continueButton)
    }
    
    @objc fileprivate func confirmCancelAction() {
        guard confirmPaymentViewController?.continueButton.isLoading == false else {
            return
        }
        
        dismissConfirmPaymentViewController()
        let cart = DataModel.sharedInstance.retrieveAddableCart(managedObjectContext: DataModel.sharedInstance.mainMoc())
        Analytics.trackCartCvvCanceled(cart: cart)
    }
    
    private func performCheckout(with card: Card, cvv: String, shippingAddress: ShippingAddress, orderButton: MainButton?) {
        orderButton?.isLoading = true
        orderButton?.isEnabled = false
        let cardEmail = card.email
        let cardName = card.fullName
        
        ShoppingCartModel.shared.nativeCheckout(card: card, cvv: cvv, shippingAddress: shippingAddress)
            .then { orderNumber, remoteId -> Void in
                
                DataModel.sharedInstance.performBackgroundTask({ (managedObjectContext) in
                    let cart = DataModel.sharedInstance.retrieveCart(managedObjectContext: managedObjectContext, remoteId: remoteId)
                    cart?.orderNumber = orderNumber //do not need ot save -- this assignement is just to ensure being passed ot anaytlics
                    Analytics.trackCartPurchaseCompleted(cart: cart, cardEmail: cardEmail, cardFullName: cardName)
                    
                })
                
                
                self.dismissConfirmPaymentViewController()
                
                let confirmationViewController = CheckoutConfirmationViewController()
                confirmationViewController.email = card.email
                confirmationViewController.orderNumber = orderNumber
                
                if self.isGiftCardRedeemable {
                    UserDefaults.standard.set(true, forKey: UserDefaultsKeys.isGiftCardHidden)
                    confirmationViewController.shouldPresentGiftCardModal = true
                }
                
                self.navigationController?.pushViewController(confirmationViewController, animated: true)
            }
            .catch { error in
                let error = error as NSError
                Analytics.trackCartError(cart: nil, domain: error.domain, code: error.code, localizedDescription: error.localizedDescription)
                
                if let error = error as NSError?,
                    error.domain == "Shoppable",
                    let errors = error.userInfo["errors"] as? [[String: String]],
                    !errors.isEmpty
                {
                    let errorKeys = errors.flatMap({ error -> [String] in
                        return error.compactMap({ (key, value) -> String? in
                            return key == "field" ? value : nil
                        })
                    })
                    
                    if errorKeys.count == 1,
                        errorKeys.contains("payment.card_cvv"), // TODO: get correct cvv key
                        let confirmPaymentViewController = self.confirmPaymentViewController
                    {
                        confirmPaymentViewController.displayCVVError()
                    }
                    else {
                        self.dismissConfirmPaymentViewController()
                        
                        let message = self.confirmPaymentErrorMessage(errorKeys)
                        let alertController = UIAlertController(title: "checkout.error.title".localized, message: message, preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "generic.ok".localized, style: .cancel, handler: nil))
                        self.present(alertController, animated: true, completion: nil)
                    }
                }
                else {
                    let alertController = UIAlertController(title: "checkout.error.title".localized, message: "checkout.error.message".localized, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "generic.ok".localized, style: .cancel, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }
                
                ActionFeedbackGenerator().actionOccurred(.nope)
            }
            .always {
                orderButton?.isLoading = false
                orderButton?.isEnabled = true
        }
    }
    
    private func dismissConfirmPaymentViewController() {
        if confirmPaymentViewController != nil {
            dismiss(animated: true, completion: nil)
            confirmPaymentViewController = nil
        }
    }
    
    private func confirmPaymentErrorMessage(_ errorKeys: [String]) -> String {
        // TODO: need correct copy and keys to map out
        var message = "Please fix these issues.\n\n"
        
        for errorKey in errorKeys {
            message += "\(errorKey)\n"
        }
        
        return message
    }
}
