//
//  CurrencyViewController.swift
//  screenshot
//
//  Created by Corey Werner on 11/27/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

class CurrencyViewController : BaseViewController {
    var selectedCurrencyCode: String?
    
    fileprivate let currencyMap = CurrencyMap()
    fileprivate let tableView = UITableView()
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if tableView.indexPathForSelectedRow == nil,
            let code = selectedCurrencyCode,
            let index = currencyMap.index(forCode: code)
        {
            tableView.selectRow(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: .middle)
        }
    }
}

extension CurrencyViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currencyMap.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? createTableViewCell()
        cell.textLabel?.text = currencyMap.items[indexPath.row].currency
        cell.detailTextLabel?.text = currencyMap.items[indexPath.row].code
        return cell
    }
    
    func createTableViewCell() -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
        cell.textLabel?.highlightedTextColor = .white
        
        cell.detailTextLabel?.highlightedTextColor = .white
        cell.detailTextLabel?.minimumScaleFactor = 0.7
        cell.detailTextLabel?.adjustsFontSizeToFitWidth = true
        
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = .crazeGreen
        cell.selectedBackgroundView = selectedBackgroundView
        
        return cell
    }
}

extension CurrencyViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        UserDefaults.standard.set(currencyMap.items[indexPath.row].code, forKey: UserDefaultsKeys.productCurrency)
    }
}
