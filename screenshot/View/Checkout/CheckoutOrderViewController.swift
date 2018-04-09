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
    let shippingControl: UIControl = Control()
    let nameLabel = UILabel()
    let addressLabel = UILabel()
    let itemsLabel = UILabel()
    let tableView: UITableView = AutoresizingTableView()
    let orderButton = MainButton()
    let cancelButton = BorderButton()
    let legalTextView = UITextView()
    
    // MARK: View
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // TODO: test with ios10
        layoutMargins = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
        
        let bottomImageView = UIImageView(image: UIImage(named: "CheckoutOrderConfetti"))
        bottomImageView.translatesAutoresizingMaskIntoConstraints = false
        bottomImageView.contentMode = .scaleAspectFill
        addSubview(bottomImageView)
        bottomImageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        bottomImageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        bottomImageView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        orderLabel.translatesAutoresizingMaskIntoConstraints = false
        orderLabel.text = "Order Summary"
        orderLabel.textColor = .gray3
        orderLabel.font = .screenshopFont(.hindLight, textStyle: .title2)
        orderLabel.adjustsFontForContentSizeCategory = true
        addSubview(orderLabel)
        orderLabel.topAnchor.constraint(equalTo: topAnchor, constant: layoutMargins.top).isActive = true
        orderLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        orderLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        let summaryView = UIView()
        summaryView.translatesAutoresizingMaskIntoConstraints = false
        summaryView.backgroundColor = .white
        summaryView.layoutMargins = UIEdgeInsetsMake(.padding, .padding, .padding, .padding)
        summaryView.layer.borderColor = UIColor.cellBorder.cgColor
        summaryView.layer.borderWidth = 1
        summaryView.layer.cornerRadius = .defaultCornerRadius
        summaryView.layer.masksToBounds = true
        addSubview(summaryView)
        summaryView.topAnchor.constraint(equalTo: orderLabel.bottomAnchor, constant: .padding / 2).isActive = true
        summaryView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        summaryView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        shippingControl.translatesAutoresizingMaskIntoConstraints = false
        summaryView.addSubview(shippingControl)
        shippingControl.topAnchor.constraint(equalTo: summaryView.topAnchor).isActive = true
        shippingControl.leadingAnchor.constraint(equalTo: summaryView.leadingAnchor).isActive = true
        shippingControl.bottomAnchor.constraint(equalTo: summaryView.bottomAnchor).isActive = true
        shippingControl.trailingAnchor.constraint(equalTo: summaryView.trailingAnchor).isActive = true
        
        let shippingLabel = UILabel()
        shippingLabel.translatesAutoresizingMaskIntoConstraints = false
        shippingLabel.font = .screenshopFont(.hindSemibold, textStyle: .body)
        shippingLabel.adjustsFontForContentSizeCategory = true
        shippingLabel.textColor = .gray3
        shippingLabel.text = "Shipping to:"
        shippingControl.addSubview(shippingLabel)
        shippingLabel.topAnchor.constraint(equalTo: shippingControl.topAnchor, constant: summaryView.layoutMargins.top).isActive = true
        shippingLabel.leadingAnchor.constraint(equalTo: summaryView.layoutMarginsGuide.leadingAnchor).isActive = true
        shippingLabel.trailingAnchor.constraint(equalTo: shippingControl.layoutMarginsGuide.trailingAnchor).isActive = true
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.textColor = .gray3
        nameLabel.font = .screenshopFont(.hindLight, textStyle: .callout)
        nameLabel.adjustsFontForContentSizeCategory = true
        shippingControl.addSubview(nameLabel)
        nameLabel.topAnchor.constraint(equalTo: shippingLabel.bottomAnchor).isActive = true
        nameLabel.leadingAnchor.constraint(equalTo: summaryView.layoutMarginsGuide.leadingAnchor).isActive = true
        nameLabel.trailingAnchor.constraint(equalTo: shippingControl.layoutMarginsGuide.trailingAnchor).isActive = true
        
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        addressLabel.textColor = .gray3
        addressLabel.font = .screenshopFont(.hindLight, textStyle: .callout)
        addressLabel.adjustsFontForContentSizeCategory = true
        addressLabel.numberOfLines = 0
        shippingControl.addSubview(addressLabel)
        addressLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor).isActive = true
        addressLabel.leadingAnchor.constraint(equalTo: summaryView.layoutMarginsGuide.leadingAnchor).isActive = true
        addressLabel.bottomAnchor.constraint(equalTo: shippingControl.bottomAnchor, constant: -summaryView.layoutMargins.bottom).isActive = true
        addressLabel.trailingAnchor.constraint(equalTo: shippingControl.layoutMarginsGuide.trailingAnchor).isActive = true
        
        itemsLabel.translatesAutoresizingMaskIntoConstraints = false
        itemsLabel.text = "Items"
        itemsLabel.textColor = .gray3
        itemsLabel.font = .screenshopFont(.hindLight, textStyle: .title2)
        itemsLabel.adjustsFontForContentSizeCategory = true
        addSubview(itemsLabel)
        itemsLabel.topAnchor.constraint(equalTo: summaryView.bottomAnchor, constant: .padding).isActive = true
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
        
        let dividerView = UIView()
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dividerView)
        dividerView.topAnchor.constraint(equalTo: orderButtonHeightGuide.bottomAnchor, constant: .padding).isActive = true
        dividerView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        dividerView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        let dividerLabel = UILabel()
        dividerLabel.translatesAutoresizingMaskIntoConstraints = false
        dividerLabel.text = "or"
        dividerLabel.textColor = .gray3
        dividerLabel.font = .screenshopFont(.hindMedium, size: 16)
        dividerLabel.textAlignment = .center
        dividerView.addSubview(dividerLabel)
        dividerLabel.topAnchor.constraint(equalTo: dividerView.topAnchor).isActive = true
        dividerLabel.bottomAnchor.constraint(equalTo: dividerView.bottomAnchor).isActive = true
        dividerLabel.centerXAnchor.constraint(equalTo: dividerView.centerXAnchor).isActive = true
        
        func createDividerFragment() -> UIView {
            let dividerFragment = UIView()
            dividerFragment.translatesAutoresizingMaskIntoConstraints = false
            dividerFragment.backgroundColor = .cellBorder
            dividerView.addSubview(dividerFragment)
            dividerFragment.centerYAnchor.constraint(equalTo: dividerView.centerYAnchor).isActive = true
            dividerFragment.heightAnchor.constraint(equalToConstant: 1).isActive = true
            return dividerFragment
        }
        
        let leftDividerFragment = createDividerFragment()
        leftDividerFragment.leadingAnchor.constraint(equalTo: dividerView.leadingAnchor).isActive = true
        leftDividerFragment.trailingAnchor.constraint(equalTo: dividerLabel.leadingAnchor, constant: -.padding).isActive = true
        
        let rightDividerFragment = createDividerFragment()
        rightDividerFragment.leadingAnchor.constraint(equalTo: dividerLabel.trailingAnchor, constant: .padding).isActive = true
        rightDividerFragment.trailingAnchor.constraint(equalTo: dividerView.trailingAnchor).isActive = true
        
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setTitle("Cancel and Continue Shopping", for: .normal)
        cancelButton.setTitleColor(.crazeGreen, for: .normal)
        addSubview(cancelButton)
        cancelButton.topAnchor.constraint(equalTo: dividerView.bottomAnchor, constant: .padding).isActive = true
        cancelButton.leadingAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.leadingAnchor).isActive = true
        cancelButton.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor).isActive = true
        cancelButton.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor).isActive = true
        cancelButton.widthAnchor.constraint(equalTo: orderButton.widthAnchor).isActive = true
        
        legalTextView.translatesAutoresizingMaskIntoConstraints = false
        legalTextView.scrollsToTop = false
        legalTextView.isScrollEnabled = false
        legalTextView.backgroundColor = .clear
        legalTextView.textColor = .gray3
        legalTextView.font = .screenshopFont(.hindLight, textStyle: .footnote)
        legalTextView.adjustsFontForContentSizeCategory = true
        addSubview(legalTextView)
        legalTextView.topAnchor.constraint(equalTo: cancelButton.bottomAnchor, constant: .padding).isActive = true
        legalTextView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        legalTextView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -layoutMargins.bottom).isActive = true
        legalTextView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    }
}

fileprivate extension CheckoutOrderView {
    class Control: UIControl {
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            let image = UIImage(named: "CheckoutOrderChevron")
            let imagePadding: CGFloat = .padding
            
            layoutMargins = UIEdgeInsetsMake(0, 0, 0, (image?.size.width ?? 0) + (imagePadding * 2))
            
            let chevronImageView = UIImageView(image: image)
            chevronImageView.translatesAutoresizingMaskIntoConstraints = false
            chevronImageView.contentMode = .scaleAspectFit
            addSubview(chevronImageView)
            chevronImageView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor).isActive = true
            chevronImageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor).isActive = true
            chevronImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -imagePadding).isActive = true
            chevronImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        }
        
        override var isHighlighted: Bool {
            didSet {
                backgroundColor = isHighlighted ? .gray9 : nil
            }
        }
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
        
        _view.nameLabel.text = "Corey Werner"
        _view.addressLabel.text = "326 N. Blaine Ave, Santa Rosa, CA  80002"
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        _view.legalTextView.text = """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam quis risus eget urna mollis ornare vel eu leo. Vestibulum id ligula porta felis euismod semper. Etiam porta sem malesuada magna mollis euismod. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam id dolor id nibh ultricies vehicula ut id elit. Morbi leo risus, porta ac consectetur ac, vestibulum at eros.
        
        Aenean eu leo quam. Pellentesque ornare sem lacinia quam venenatis vestibulum. Vivamus sagittis lacus vel augue laoreet rutrum faucibus dolor auctor.
        """
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
