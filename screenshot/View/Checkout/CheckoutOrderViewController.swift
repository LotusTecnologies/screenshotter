//
//  CheckoutOrderViewController.swift
//  screenshot
//
//  Created by Corey Werner on 4/9/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class CheckoutOrderView: UIScrollView {
    let orderLabel = UILabel()
    let itemsLabel = UILabel()
    let tableView: UITableView = AutoresizingTableView()
    let orderButton = MainButton()
    
    // MARK: View
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // TODO: test with ios10
        layoutMargins = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
        
        orderLabel.translatesAutoresizingMaskIntoConstraints = false
        orderLabel.text = "Order Summary"
        orderLabel.textColor = .gray3
        orderLabel.font = UIFont.screenshopFont(.hindLight, textStyle: .title2)
        orderLabel.adjustsFontForContentSizeCategory = true
        addSubview(orderLabel)
        orderLabel.topAnchor.constraint(equalTo: topAnchor, constant: layoutMargins.top).isActive = true
        orderLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        orderLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        let box1 = UIView()
        box1.translatesAutoresizingMaskIntoConstraints = false
        box1.backgroundColor = .red
        addSubview(box1)
        box1.topAnchor.constraint(equalTo: orderLabel.bottomAnchor, constant: .padding / 2).isActive = true
        box1.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        box1.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        box1.heightAnchor.constraint(equalToConstant: 500).isActive = true
        
        itemsLabel.translatesAutoresizingMaskIntoConstraints = false
        itemsLabel.text = "Items"
        itemsLabel.textColor = .gray3
        itemsLabel.font = UIFont.screenshopFont(.hindLight, textStyle: .title2)
        itemsLabel.adjustsFontForContentSizeCategory = true
        addSubview(itemsLabel)
        itemsLabel.topAnchor.constraint(equalTo: box1.bottomAnchor, constant: .padding).isActive = true
        itemsLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        itemsLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .green
        tableView.scrollsToTop = false
        tableView.isScrollEnabled = false
        tableView.separatorInset = .zero
        tableView.separatorColor = .cellBorder
        tableView.layer.borderColor = UIColor.cellBorder.cgColor
        tableView.layer.borderWidth = 1
        tableView.layer.cornerRadius = .defaultCornerRadius
        tableView.layer.masksToBounds = true
        addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: itemsLabel.bottomAnchor, constant: .padding / 2).isActive = true
        tableView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        let orderButtonHeightGuide = UIView()
        orderButtonHeightGuide.translatesAutoresizingMaskIntoConstraints = false
        orderButtonHeightGuide.isHidden = true
        addSubview(orderButtonHeightGuide)
        orderButtonHeightGuide.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: .padding).isActive = true
        
        orderButton.translatesAutoresizingMaskIntoConstraints = false
        orderButton.backgroundColor = .crazeGreen
        orderButton.setTitle("Place Your Order", for: .normal)
        addSubview(orderButton)
        orderButton.leadingAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.leadingAnchor).isActive = true
        orderButton.bottomAnchor.constraint(lessThanOrEqualTo: orderButtonHeightGuide.bottomAnchor).isActive = true
        orderButton.bottomAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.bottomAnchor).isActive = true
        orderButton.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor).isActive = true
        orderButton.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor).isActive = true
        
        orderButtonHeightGuide.heightAnchor.constraint(equalTo: orderButton.heightAnchor).isActive = true
        
        let box2 = UIView()
        box2.backgroundColor = .green
        box2.translatesAutoresizingMaskIntoConstraints = false
        addSubview(box2)
        box2.topAnchor.constraint(equalTo: orderButtonHeightGuide.bottomAnchor, constant: .padding).isActive = true
        box2.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        box2.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -layoutMargins.bottom).isActive = true
        box2.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        box2.heightAnchor.constraint(equalToConstant: 10).isActive = true
    }
}

class CheckoutOrderViewController: BaseViewController {
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    deinit {
        tableView.dataSource = nil
        tableView.delegate = nil
    }
}

extension CheckoutOrderViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.textLabel?.text = "Cell #\(indexPath.row + 1)"
        
        return cell
    }
}

extension CheckoutOrderViewController: UITableViewDelegate {

}
