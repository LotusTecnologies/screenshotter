//
//  CartViewController.swift
//  screenshot
//
//  Created by Corey Werner on 2/19/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import CoreData

class CartViewController: BaseViewController {
    fileprivate let tableView = UITableView()
    
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
        
        ShoppingCartModel.shared.getAddableCart().then(execute: { cart -> Void in
            self.cartItemFrc = DataModel.sharedInstance.cartItemFrc(delegate: self, cart: cart)
            
            if self.isViewLoaded {
                self.tableView.reloadData()
            }
        })
        
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
        tableView.register(CartTableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }
}

extension CartViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cartItemFrc?.fetchedObjectsCount ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        if let cell = cell as? CartTableViewCell, let cartItem =  cartItemFrc?.object(at: indexPath) {
            
            
            cell.productImageView.backgroundColor = .red
            cell.titleLabel.text = "Anthropologie Tweed Long-Sleeve"
            cell.priceLabel.text = formatter.string(from: NSNumber(value: cartItem.retailPrice))
            cell.quantity = Double(cartItem.quantity)
            cell.color = cartItem.color
            cell.size = cartItem.size
        }
        
        return cell
    }
}

extension CartViewController: UITableViewDelegate {
    
}

extension CartViewController: FetchedResultsControllerManagerDelegate {
    func managerDidChangeContent(_ controller: NSObject, change: FetchedResultsControllerManagerChange) {
        if isViewLoaded {
            change.applyChanges(tableView: tableView)
        }
    }
}
