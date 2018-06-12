//
//  CartViewController.swift
//  screenshot
//
//  Created by Corey Werner on 2/19/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit
import CoreData
import SDWebImage

protocol CartViewControllerDelegate: NSObjectProtocol {
    func cartViewControllerDidValidateCart(_ viewController: CartViewController)
}

class CartViewController: BaseViewController {
    enum Section: Int {
        case notification
        case product
    }
    
    weak var delegate: CartViewControllerDelegate?
    
    fileprivate let tableView = TableView(frame: .zero, style: .grouped)
    fileprivate let itemCountView = CartItemCountView()
    fileprivate let emptyListView = HelperView()
    fileprivate let checkoutView = CartCheckoutView()
    fileprivate let loadingContainerView = UIView()
    fileprivate let loaderView = Loader()
    
    fileprivate var cartItemFrc: FetchedResultsControllerManager<CartItem>?
    fileprivate var notificationSectionCount = 0
    
    fileprivate lazy var formatter: NumberFormatter = {
        let localeIdentifier = Locale.identifier(fromComponents: [
            NSLocale.Key.currencyCode.rawValue: "USD",
            NSLocale.Key.languageCode.rawValue: "en"
            ])
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: localeIdentifier)
        return formatter
    }()
    
    fileprivate var editingCartItemId: NSManagedObjectID?
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        cartItemFrc = DataModel.sharedInstance.cartItemFrc(delegate: self)
        
        restorationIdentifier = String(describing: type(of: self))
        title = "cart.title".localized
        
        addNavigationItemLogo()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = view.backgroundColor
        tableView.separatorInset = .zero
        tableView.allowsSelection = false
        tableView.layoutMargins = UIEdgeInsets(top: .extendedPadding, left: 0, bottom: .extendedPadding, right: 0) // Needed for emptyListView
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 200
        tableView.register(CartGiftCardTableViewCell.self, forCellReuseIdentifier: "gift")
        tableView.register(CartTableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        let emptyListButton = MainButton()
        emptyListButton.translatesAutoresizingMaskIntoConstraints = false
        emptyListButton.backgroundColor = .crazeGreen
        emptyListButton.setTitle("cart.empty.button".localized, for: .normal)
        emptyListButton.addTarget(self, action: #selector(emptyListAction), for: .touchUpInside)
        emptyListView.controlView.addSubview(emptyListButton)
        emptyListButton.topAnchor.constraint(equalTo: emptyListView.controlView.topAnchor).isActive = true
        emptyListButton.leadingAnchor.constraint(greaterThanOrEqualTo: emptyListView.controlView.layoutMarginsGuide.leadingAnchor).isActive = true
        emptyListButton.bottomAnchor.constraint(equalTo: emptyListView.controlView.bottomAnchor).isActive = true
        emptyListButton.trailingAnchor.constraint(lessThanOrEqualTo: emptyListView.controlView.layoutMarginsGuide.trailingAnchor).isActive = true
        emptyListButton.centerXAnchor.constraint(equalTo: emptyListView.controlView.centerXAnchor).isActive = true
        
        emptyListView.titleLabel.text = "cart.empty.title".localized
        emptyListView.contentImage = UIImage(named: "CartEmptyListGraphic")
        tableView.emptyView = emptyListView
        
        checkoutView.translatesAutoresizingMaskIntoConstraints = false
        checkoutView.backgroundColor = .white
        checkoutView.layoutMargins = UIEdgeInsets(top: .padding / 2, left: .padding, bottom: .padding / 2, right: .padding)
        checkoutView.checkoutButton.addTarget(self, action: #selector(checkoutAction(_:)), for: .touchUpInside)
        view.addSubview(checkoutView)
        checkoutView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        checkoutView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        if #available(iOS 11.0, *) {
            checkoutView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        }
        else {
            checkoutView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor).isActive = true
        }
        
        loadingContainerView.translatesAutoresizingMaskIntoConstraints = false
        loadingContainerView.backgroundColor = UIColor.gray3.withAlphaComponent(0.5)
        loadingContainerView.isHidden = true
        view.addSubview(loadingContainerView)
        loadingContainerView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        loadingContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        loadingContainerView.bottomAnchor.constraint(equalTo: checkoutView.topAnchor).isActive = true
        loadingContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        loaderView.translatesAutoresizingMaskIntoConstraints = false
        loaderView.color = .white
        loadingContainerView.addSubview(loaderView)
        loaderView.centerXAnchor.constraint(equalTo: loadingContainerView.centerXAnchor).isActive = true
        loaderView.centerYAnchor.constraint(equalTo: loadingContainerView.centerYAnchor).isActive = true
        
        syncItemCount()
        syncTotalPrice()
        syncCheckoutViewVisibility()
        notificationSectionCount = expectedNotificationSectionCount
        
        let pinchZoom = UIPinchGestureRecognizer.init(target: self, action: #selector(pinch(gesture:)))
        self.view.addGestureRecognizer(pinchZoom)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        syncNotificationSection()
    }
    
    @objc func pinch( gesture:UIPinchGestureRecognizer) {
        if CrazeImageZoom.shared.isHandlingGesture, let imageView = CrazeImageZoom.shared.hostedImageView  {
            CrazeImageZoom.shared.gestureStateChanged(gesture, imageView: imageView)
            return
        }
        let point = gesture.location(in: self.tableView)
        if let indexPath = self.tableView.indexPathForRow(at: point), let cell = self.tableView.cellForRow(at: indexPath) as? CartTableViewCell{
            CrazeImageZoom.shared.gestureStateChanged(gesture, imageView: cell.productImageView.imageView)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        var bottom = checkoutView.bounds.height
        
        if #available(iOS 11.0, *) {
            bottom -= bottomLayoutGuide.length
        }
        else {
            bottom += bottomLayoutGuide.length
        }
        
        var contentInset = tableView.contentInset
        contentInset.bottom = bottom
        tableView.contentInset = contentInset
        
        var scrollIndicatorInsets = tableView.scrollIndicatorInsets
        scrollIndicatorInsets.bottom = bottom
        tableView.scrollIndicatorInsets = scrollIndicatorInsets
    }
    
    // MARK: Sync Views
    
    private var isPriceAtLeast50 = false
    
    var isGiftCardRedeemable: Bool {
        return isPriceAtLeast50 && !UserDefaults.standard.bool(forKey: UserDefaultsKeys.isGiftCardHidden)
    }
    
    fileprivate func syncTotalPrice() {
        var price: Double = 0
        
        cartItemFrc?.fetchedObjects.forEach({ cartItem in
            price += Double(cartItem.price) * Double(cartItem.quantity)
        })
        
        checkoutView.price = formatter.string(from: NSNumber(value: price))
        isPriceAtLeast50 = price >= 50
        
        if notificationSectionCount > 0, let visibleIndexPaths = tableView.indexPathsForVisibleRows {
            let giftIndexPath = IndexPath(row: 0, section: Section.notification.rawValue)

            if visibleIndexPaths.contains(giftIndexPath) {
                tableView.reloadSections(IndexSet(integer: Section.notification.rawValue), with: .none)
            }
        }
    }
    
    fileprivate func syncCheckoutViewVisibility() {
        func setAlpha() {
            checkoutView.alpha = (numberOfItems > 0) ? 1 : 0
        }
        
        if view.window == nil {
            setAlpha()
        }
        else {
            UIView.animate(withDuration: .defaultAnimationDuration, animations: {
                setAlpha()
            })
        }
    }
    
    fileprivate func syncItemCount() {
        let count = numberOfItems
        
        if itemCountView.itemCount != count {
            itemCountView.itemCount = count
        }
    }
    
    fileprivate func syncNotificationSection() {
        if notificationSectionCount != expectedNotificationSectionCount {
            notificationSectionCount = expectedNotificationSectionCount
            tableView.reloadSections(IndexSet(integer: Section.notification.rawValue), with: .none)
        }
    }
    
    // MARK: Empty List
    
    @objc fileprivate func emptyListAction() {
        Analytics.trackCartEmptyPressedButton()
        MainTabBarController.resetViewControllerHierarchy(self, select: .discover)
    }
}

extension CartViewController: UITableViewDataSource {
    fileprivate var numberOfItems: Int {
        return cartItemFrc?.fetchedObjectsCount ?? 0
    }
    
    fileprivate func cartItem(at index: Int) -> CartItem? {
        let indexPath = IndexPath(row: index, section: 0)
        return cartItemFrc?.object(at: indexPath)
    }
    
    fileprivate var expectedNotificationSectionCount: Int {
        return (!UserDefaults.standard.bool(forKey: UserDefaultsKeys.isGiftCardHidden) && numberOfItems > 0) ? 1 : 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == Section.notification.rawValue {
            return notificationSectionCount
        }
        else {
            return numberOfItems
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == Section.notification.rawValue {
            return self.tableView(tableView, notificationCellForRowAt: indexPath)
        }
        else {
            return self.tableView(tableView, productCellForRowAt: indexPath)
        }
    }
    
    fileprivate func tableView(_ tableView: UITableView, notificationCellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "gift", for: indexPath)
        
        if let cell = cell as? CartGiftCardTableViewCell {
            cell.isAvailable = isPriceAtLeast50
        }
        
        return cell
    }
    
    fileprivate func tableView(_ tableView: UITableView, productCellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        if let cell = cell as? CartTableViewCell, let cartItem = cartItem(at: indexPath.row) {
            cell.contentView.backgroundColor = .cellBackground
            cell.productImageView.setImage(withURLString: cartItem.imageURL)
            cell.titleLabel.text = cartItem.productTitle()
            cell.priceLabel.text = formatter.string(from: NSNumber(value: cartItem.price))
            cell.quantity = Double(cartItem.quantity)
            cell.color = cartItem.color
            cell.size = cartItem.size
            cell.errorMask = CartItem.ErrorMaskOptions(rawValue: cartItem.errorMask)
            cell.removeButton.addTarget(self, action: #selector(cartItemRemoveAction(_:)), for: .touchUpInside)
            cell.editButton.addTarget(self, action: #selector(cartItemEditAction(_:)), for: .touchUpInside)
        }
        
        return cell
    }
    
    func tableView(removeCellForRowAt indexPath: IndexPath) {
        if let cartItem = cartItem(at: indexPath.row) {
            ShoppingCartModel.shared.remove(item: cartItem)
        }
    }
}

extension CartViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == Section.notification.rawValue {
            return 0
        }
        else {
            return numberOfItems == 0 ? 0 : 74
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return itemCountView
    }
}

extension CartViewController: FetchedResultsControllerManagerDelegate {
    func managerDidChangeContent(_ controller: NSObject, change: FetchedResultsControllerManagerChange) {
        if isViewLoaded {
            let animation: UITableViewRowAnimation = change.deletedRows.isEmpty ? .none : .fade
            change.shiftIndexSections(by: Section.product.rawValue)
            change.applyChanges(tableView: tableView, with: animation)
            
            syncItemCount()
            syncTotalPrice()
            syncCheckoutViewVisibility()
            syncNotificationSection()
        }
    }
}

typealias CartViewControllerCartItem = CartViewController
fileprivate extension CartViewControllerCartItem {
    
    func variant(forColor color: String?, size: String?, in product: Product) -> Variant? {
        let variants = product.availableVariants as? Set<Variant>
        return variants?.first { $0.color == color && $0.size == size }
    }
    
    @objc func cartItemEditAction(_ button: UIButton) {
        let position: CGPoint = button.convert(.zero, to: tableView)
        
        guard let indexPath = tableView.indexPathForRow(at: position),
            let cartItem = cartItem(at: indexPath.row),
            let product = cartItem.product,
            let carItemVariant = variant(forColor: cartItem.color, size: cartItem.size, in: product)
            else {
                return
        }
        
        editingCartItemId = cartItem.objectID
        let quantity = Int(cartItem.quantity)
        
        let productVariantsSelectorViewController = ProductVariantsSelectorViewController(product: product, initialVariant: carItemVariant, initialQuantity: quantity)
        productVariantsSelectorViewController.delegate = self
        present(productVariantsSelectorViewController, animated: true, completion: nil)
        
        
        // TODO: remove these analytics
//        if quantity > cartItem.quantity {
//            Analytics.trackProductCartQuanityStepUp(cartItem: cartItem)
//        }else{
//            Analytics.trackProductCartQuanityStepDown(cartItem: cartItem)
//        }
    }
    
    @objc func cartItemRemoveAction(_ button: UIButton) {
        let position: CGPoint = button.convert(.zero, to: tableView)
        
        if let indexPath = tableView.indexPathForRow(at: position) {
            if let cartItem = cartItem(at: indexPath.row) {
                Analytics.trackProductRemovedFromCart(cartItem: cartItem)
            }
            
            tableView(removeCellForRowAt: indexPath)
        }
    }
}

extension CartViewController: ProductVariantsSelectorViewControllerDelegate {
    func productVariantsSelectorViewControllerDidPressCancel(_ productVariantsSelectorViewController: ProductVariantsSelectorViewController) {
        editingCartItemId = nil
        dismiss(animated: true, completion: nil)
    }
    
    func productVariantsSelectorViewControllerDidPressContinue(_ productVariantsSelectorViewController: ProductVariantsSelectorViewController) {
        if let variant = productVariantsSelectorViewController.selectedVariant {
            if let cartItemId = editingCartItemId,
                let cartItem = DataModel.sharedInstance.mainMoc().cartItemWith(objectId: cartItemId)
            {
                let quantity = Int16(productVariantsSelectorViewController.selectedQuantity)
                let isQuantityDifferent = cartItem.quantity != quantity
                let isColorDifferent = cartItem.color != variant.color
                let isSizeDifferent = cartItem.size != variant.size
                
                if isColorDifferent || isSizeDifferent {
                    ShoppingCartModel.shared.remove(item: cartItem)
                }
                if isColorDifferent || isSizeDifferent || isQuantityDifferent {
                    ShoppingCartModel.shared.update(variant: variant, quantity: quantity)
                }
            }
            else {
                // Just in case of an issue, update without logic
                ShoppingCartModel.shared.update(variant: variant, quantity: Int16(productVariantsSelectorViewController.selectedQuantity))
            }
        }
        
        editingCartItemId = nil
        dismiss(animated: true, completion: nil)
    }
}

typealias CartViewControllerCheckout = CartViewController
fileprivate extension CartViewControllerCheckout {
    @objc func checkoutAction(_ button: UIButton) {
        let cart = self.cartItemFrc?.fetchedObjects.first?.cart
        Analytics.trackCartPressedCheckout(cart:cart)

        presentCheckoutLoader()
        
        ShoppingCartModel.shared.checkout()
            .then { [weak self] success -> Void in
                if success {
                    guard let strongSelf = self else {
                        return
                    }
                    
                    strongSelf.dismissCheckoutLoader()
                    strongSelf.delegate?.cartViewControllerDidValidateCart(strongSelf)
                }
                else {
                    self?.dismissCheckoutLoader()
                }
            }
            .catch { [weak self] error in
                let cart = self?.cartItemFrc?.fetchedObjects.first?.cart
                
                let nsError = error as NSError
                let domain = nsError.domain
                let code = nsError.code
                
                Analytics.trackCartError(cart: cart, domain: domain, code: code, localizedDescription: error.localizedDescription)
                
                let alertController = UIAlertController(title: "checkout.error.title".localized, message: "checkout.error.message".localized, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "generic.ok".localized, style: .cancel, handler: nil))
                self?.present(alertController, animated: true, completion: nil)
                
                self?.dismissCheckoutLoader()
        }
    }
    
    func presentCheckoutLoader() {
        checkoutView.checkoutButton.isEnabled = false
        loadingContainerView.isHidden = false
        loaderView.startAnimation()
    }
    
    func dismissCheckoutLoader() {
        checkoutView.checkoutButton.isEnabled = true
        loadingContainerView.isHidden = true
        loaderView.stopAnimation()
    }
}
