//
//  CurrencyViewController.swift
//  screenshot
//
//  Created by Corey Werner on 11/27/17.
//  Copyright (c) 2017 crazeapp. All rights reserved.
//

import Foundation
import UIKit

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
        
        let code = selectedCurrencyCode ?? CurrencyMap.autoCode
        
        if tableView.indexPathForSelectedRow == nil, let index = currencyMap.index(forCode: code) {
            tableView.selectRow(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: .middle)
        }
    }
    
    // MARK: Currency
    
    static var currentCurrency: String {
        if let code = UserDefaults.standard.string(forKey: UserDefaultsKeys.productCurrency) {
            if  code != CurrencyMap.autoCode {
                return code
            }
        }
        return "currency.auto".localized
        
    }
}

extension CurrencyViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currencyMap.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? createTableViewCell()
        cell.textLabel?.text = cellText(indexPath)
        cell.textLabel?.font = .screenshopFont(.hindLight, textStyle: .body)
        cell.detailTextLabel?.text = cellDetailText(indexPath)
        cell.detailTextLabel?.font = .screenshopFont(.hindSemibold, textStyle: .body)
        return cell
    }
    
    private func createTableViewCell() -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
        cell.textLabel?.highlightedTextColor = .white
        
        cell.detailTextLabel?.highlightedTextColor = .white
        cell.detailTextLabel?.minimumScaleFactor = 0.7
        cell.detailTextLabel?.baselineAdjustment = .alignCenters
        cell.detailTextLabel?.adjustsFontSizeToFitWidth = true
        
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = .crazeGreen
        cell.selectedBackgroundView = selectedBackgroundView
        
        return cell
    }
    
    private func cellText(_ indexPath: IndexPath) -> String {
        if indexPath.row == 0 {
            return "currency.auto".localized
            
        } else {
            return currencyMap.items[indexPath.row].currency
        }
    }
    
    private func cellDetailText(_ indexPath: IndexPath) -> String {
        if indexPath.row == 0 {
            return ""
            
        } else {
            return currencyMap.items[indexPath.row].code
        }
    }
}

extension CurrencyViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        UserDefaults.standard.set(currencyMap.items[indexPath.row].code, forKey: UserDefaultsKeys.productCurrency)
    }
}
