//
//  CartViewController.swift
//  screenshot
//
//  Created by Corey Werner on 2/19/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import CoreData
import SDWebImage

class CartViewController: BaseViewController {
    fileprivate let tableView = TableView(frame: .zero, style: .grouped)
    fileprivate let itemCountView = CartItemCountView()
    fileprivate let emptyListView = HelperView()
    fileprivate let checkoutView = CartCheckoutView()
    
    fileprivate var cartItemFrc: FetchedResultsControllerManager<CartItem>?
    
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
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        cartItemFrc = DataModel.sharedInstance.cartItemFrc(delegate: self)
        
        restorationIdentifier = String(describing: type(of: self))
        
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
        tableView.register(CartTableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        emptyListView.titleLabel.text = "cart.empty.title".localized
        tableView.emptyView = emptyListView
        
        checkoutView.translatesAutoresizingMaskIntoConstraints = false
        checkoutView.backgroundColor = .white
        checkoutView.layoutMargins = {
            var insets = UIEdgeInsets(top: .padding / 2, left: .padding, bottom: .padding / 2, right: .padding)
            
            // TODO: bottom safe area for iPhone X
            
            return insets
        }()
        view.addSubview(checkoutView)
        checkoutView.topAnchor.constraint(equalTo: tableView.bottomAnchor).isActive = true
        checkoutView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        checkoutView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor).isActive = true
        checkoutView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        syncTotalPrice()
    }
}

extension CartViewController: UITableViewDataSource {
    fileprivate var numberOfItems: Int {
        return cartItemFrc?.fetchedObjectsCount ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = numberOfItems
        itemCountView.itemCount = UInt(count)
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        if let cell = cell as? CartTableViewCell, let cartItem = cartItemFrc?.object(at: indexPath) {
            let url = URL(string: cartItem.imageURL ?? "")
            cell.productImageView.sd_setImage(with: url, placeholderImage: nil)
            
            cell.titleLabel.text = cartItem.productTitle()
            cell.priceLabel.text = formatter.string(from: NSNumber(value: cartItem.retailPrice))
            cell.quantity = Double(cartItem.quantity)
            cell.color = cartItem.color
            cell.size = cartItem.size
            cell.removeButton.addTarget(self, action: #selector(cartItemRemoveAction(_:)), for: .touchUpInside)
            cell.quantityStepper.addTarget(self, action: #selector(cartItemQuantityChanged(_:)), for: .valueChanged)
        }
        
        return cell
    }
    
    func tableView(removeCellForRowAt indexPath: IndexPath) {
        if let cartItem = cartItemFrc?.object(at: indexPath) {
            ShoppingCartModel.shared.remove(item: cartItem)
        }
    }
}

extension CartViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return numberOfItems == 0 ? 0 : 74
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return itemCountView
    }
}

extension CartViewController: FetchedResultsControllerManagerDelegate {
    func managerDidChangeContent(_ controller: NSObject, change: FetchedResultsControllerManagerChange) {
        if isViewLoaded {
            let animation: UITableViewRowAnimation = change.deletedRows.isEmpty ? .none : .fade
            
            change.applyChanges(tableView: tableView, with: animation)
            syncTotalPrice()
        }
    }
}

typealias CartViewControllerCartItem = CartViewController
fileprivate extension CartViewControllerCartItem {
    @objc func cartItemQuantityChanged(_ stepper: UIStepper) {
        let position: CGPoint = stepper.convert(.zero, to: tableView)
        
        guard let indexPath = tableView.indexPathForRow(at: position),
            let cartItem = cartItemFrc?.object(at: indexPath) else {
            return
        }
        
        let quantity = Int16(stepper.value)
        ShoppingCartModel.shared.update(cartItem: cartItem, quantity: quantity)
    }
    
    @objc func cartItemRemoveAction(_ button: UIButton) {
        let position: CGPoint = button.convert(.zero, to: tableView)
        
        if let indexPath = tableView.indexPathForRow(at: position) {
            tableView(removeCellForRowAt: indexPath)
        }
        
        // TODO: analytic event for did tap remove
    }
    
    func syncTotalPrice() {
        var price: Double = 0
        
        cartItemFrc?.fetchedObjects.forEach({ cartItem in
            price += Double(cartItem.retailPrice)
        })
        
        checkoutView.price = formatter.string(from: NSNumber(value: price))
    }
}
