//
//  CheckoutShippingListViewController.swift
//  screenshot
//
//  Created by Corey Werner on 4/11/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import CoreData

class CheckoutShippingListViewController: CheckoutListViewController {
    fileprivate var shippingFrc: FetchedResultsControllerManager<ShippingAddress>?
    
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
        tableView.estimatedRowHeight = 120
        tableView.register(CheckoutShippingTableViewCell.self, forCellReuseIdentifier: "cell")
        
        addButton.setTitle("Add a new shipping address", for: .normal)
        addButton.setImage(UIImage(named: "CheckoutLocation"), for: .normal)
        addButton.addTarget(self, action: #selector(addButtonAction), for: .touchUpInside)
        addButton.sizeToFit()
    }
    
    deinit {
        tableView.dataSource = nil
        tableView.delegate = nil
    }
    
    // MARK: Actions
    
    @objc fileprivate func addButtonAction() {
        let shippingFormViewController = CheckoutShippingFormViewController()
        shippingFormViewController.delegate = self
        navigationController?.pushViewController(shippingFormViewController, animated: true)
    }
    
    @objc fileprivate func editButtonAction(_ button: UIButton, event: UIEvent) {
        guard let indexPath = tableView.indexPath(for: event) else {
            return
        }
        
        let shippingAddress = shippingFrc?.object(at: indexPath)
        let shippingFormViewController = CheckoutShippingFormViewController(withShippingAddress: shippingAddress)
        shippingFormViewController.delegate = self
        navigationController?.pushViewController(shippingFormViewController, animated: true)
    }
    
    // MARK: Selection
    
    override func indexPathForSelectedCell() -> IndexPath? {
        let shippingAddress: ShippingAddress? = {
            if let url = DataModel.sharedInstance.selectedShippingAddressURL,
                let objectID = DataModel.sharedInstance.mainMoc().objectId(for: url),
                let shippingAddress = DataModel.sharedInstance.mainMoc().shippingAddressWith(objectId: objectID)
            {
                return shippingAddress
            }
            
            if let shippingAddress = shippingFrc?.fetchedObjects.first {
                DataModel.sharedInstance.selectedShippingAddressURL = shippingAddress.objectID.uriRepresentation()
                return shippingAddress
            }
            
            return nil
        }()
        
        if let shippingAddress = shippingAddress {
            return shippingFrc?.indexPath(forObject: shippingAddress)
        }
        else {
            return nil
        }
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
}

extension CheckoutShippingListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let shipping = shippingFrc?.object(at: indexPath) {
            DataModel.sharedInstance.selectedShippingAddressURL = shipping.objectID.uriRepresentation()
        }
    }
}
