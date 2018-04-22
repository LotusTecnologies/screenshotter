//
//  CheckoutShippingListViewController.swift
//  screenshot
//
//  Created by Corey Werner on 4/11/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import CoreData

class CheckoutShippingListViewController: BaseViewController {
    fileprivate var shippingFrc: FetchedResultsControllerManager<ShippingAddress>?
    
    // MARK: View
    
    fileprivate let tableView = UITableView()
    
    override func loadView() {
        view = tableView
    }
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        title = "Shipping Addresses"
        restorationIdentifier = String(describing: type(of: self))
        
        shippingFrc = DataModel.sharedInstance.shippingAddressFrc(delegate: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorInset = .zero
        tableView.estimatedRowHeight = 120
        tableView.register(CheckoutShippingTableViewCell.self, forCellReuseIdentifier: "cell")
        
        let addButton = UIButton()
        addButton.contentEdgeInsets = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
        addButton.setTitle("Add a new shipping address", for: .normal)
        addButton.setTitleColor(.gray3, for: .normal)
        addButton.setTitleColor(.black, for: .highlighted)
        addButton.setImage(UIImage(named: "CheckoutLocation"), for: .normal)
        addButton.adjustInsetsForImage(withPadding: 6)
        addButton.addTarget(self, action: #selector(addShippingAddressAction), for: .touchUpInside)
        addButton.sizeToFit()
        tableView.tableFooterView = addButton
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let shippingURL = UserDefaults.standard.url(forKey: Constants.checkoutPrimaryAddressURL),
            let objectID = DataModel.sharedInstance.mainMoc().objectId(for: shippingURL),
            let shipping = DataModel.sharedInstance.mainMoc().shippingAddressWith(objectId: objectID),
            let indexPath = shippingFrc?.indexPath(forObject: shipping)
        {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
    }
    
    deinit {
        tableView.dataSource = nil
        tableView.delegate = nil
    }
    
    @objc fileprivate func addShippingAddressAction() {
        let shippingFormViewController = CheckoutShippingFormViewController()
        navigationController?.pushViewController(shippingFormViewController, animated: true)
    }
}

extension CheckoutShippingListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shippingFrc?.fetchedObjectsCount ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.backgroundColor = view.backgroundColor
        cell.selectionStyle = .none
        
        if let cell = cell as? CheckoutShippingTableViewCell, let shipping = shippingFrc?.object(at: indexPath) {
            cell.nameLabel.text = shipping.fullName
            cell.addressLabel.text = shipping.readableAddress
            cell.editButton.addTarget(self, action: #selector(editButtonAction(_:event:)), for: .touchUpInside)
        }
        
        return cell
    }
    
    @objc fileprivate func editButtonAction(_ button: UIButton, event: UIEvent) {
        guard let indexPath = tableView.indexPath(for: event) else {
            return
        }
        
        let shippingAddress = shippingFrc?.object(at: indexPath)
        let shippingFormViewController = CheckoutShippingFormViewController(withShippingAddress: shippingAddress)
        navigationController?.pushViewController(shippingFormViewController, animated: true)
    }
}

extension CheckoutShippingListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let shipping = shippingFrc?.object(at: indexPath) {
            let shippingURL = shipping.objectID.uriRepresentation()
            UserDefaults.standard.set(shippingURL, forKey: Constants.checkoutPrimaryAddressURL)
            UserDefaults.standard.synchronize()
        }
    }
}

extension CheckoutShippingListViewController: FetchedResultsControllerManagerDelegate {
    func managerDidChangeContent(_ controller: NSObject, change: FetchedResultsControllerManagerChange) {
        if isViewLoaded {
            change.applyChanges(tableView: tableView)
        }
    }
}
