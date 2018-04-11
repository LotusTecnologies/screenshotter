//
//  CheckoutPaymentListViewController.swift
//  screenshot
//
//  Created by Corey Werner on 4/10/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import CreditCardValidator
import UIKit

class CheckoutPaymentListViewController: BaseViewController {
    
    // MARK: View
    
    fileprivate let tableView = UITableView()
    
    override func loadView() {
        view = tableView
    }
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorInset = .zero
        tableView.register(CheckoutCreditCardTableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.tableFooterView = UIView()
    }
    
    deinit {
        tableView.dataSource = nil
        tableView.delegate = nil
    }
}

extension CheckoutPaymentListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.backgroundColor = view.backgroundColor
        cell.selectionStyle = .none
        
        if let cell = cell as? CheckoutCreditCardTableViewCell {
            if indexPath.row == 0 {
                cell.nameLabel.text = "Corey Werner"
            }
            else {
                cell.nameLabel.text = "Herbert Neninger"
            }
            
            let month = 3
            let year = 2019
            
            cell.setExpiration(month: month, year: year)
            cell.isExpired = CreditCardValidator.shared.isExpired(month: month, year: year)
        }
        
        return cell
    }
}

extension CheckoutPaymentListViewController: UITableViewDelegate {
    
}
