//
//  CheckoutShippingListViewController.swift
//  screenshot
//
//  Created by Corey Werner on 4/11/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class CheckoutShippingListViewController: BaseViewController {
    
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
        addButton.addTarget(self, action: #selector(addCreditCardAction), for: .touchUpInside)
        addButton.sizeToFit()
        tableView.tableFooterView = addButton
    }
    
    deinit {
        tableView.dataSource = nil
        tableView.delegate = nil
    }
    
    @objc fileprivate func addCreditCardAction() {
        
    }
}

extension CheckoutShippingListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.backgroundColor = view.backgroundColor
        cell.selectionStyle = .none
        
        if let cell = cell as? CheckoutShippingTableViewCell {
            if indexPath.row == 0 {
                cell.nameLabel.text = "Corey Werner"
                cell.addressLabel.text = """
                2337 S Broadway St
                Apt 303
                New York, NY 15522
                """
            }
            else {
                cell.nameLabel.text = "Herbert Neninger"
                cell.addressLabel.text = """
                455 Plummers Lane
                New Haven, CT 65520
                """
            }
        }
        
        return cell
    }
}

extension CheckoutShippingListViewController: UITableViewDelegate {
    
}
