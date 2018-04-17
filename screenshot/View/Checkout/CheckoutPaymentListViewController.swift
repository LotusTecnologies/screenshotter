//
//  CheckoutPaymentListViewController.swift
//  screenshot
//
//  Created by Corey Werner on 4/10/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import CreditCardValidator
import UIKit
import CoreData

class CheckoutPaymentListViewController: BaseViewController {
    fileprivate var cardFrc: FetchedResultsControllerManager<Card>?
    
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
        
        title = "Payment Methods"
        restorationIdentifier = String(describing: type(of: self))
        
        cardFrc = DataModel.sharedInstance.cardFrc(delegate: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorInset = .zero
        tableView.estimatedRowHeight = 150
        tableView.register(CheckoutCreditCardTableViewCell.self, forCellReuseIdentifier: "cell")
        
        let addButton = UIButton()
        addButton.contentEdgeInsets = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
        addButton.setTitle("Add a new card", for: .normal)
        addButton.setTitleColor(.gray3, for: .normal)
        addButton.setTitleColor(.black, for: .highlighted)
        addButton.setImage(UIImage(named: "CheckoutCreditCard"), for: .normal)
        addButton.adjustInsetsForImage(withPadding: 6)
        addButton.addTarget(self, action: #selector(addCreditCardAction), for: .touchUpInside)
        addButton.sizeToFit()
        tableView.tableFooterView = addButton
    }
    
    deinit {
        tableView.dataSource = nil
        tableView.delegate = nil
    }
    
    @objc fileprivate func addCreditCardAction() {
        let paymentFormViewController = CheckoutPaymentFormViewController()
        navigationController?.pushViewController(paymentFormViewController, animated: true)
    }
}

extension CheckoutPaymentListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cardFrc?.fetchedObjectsCount ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.backgroundColor = view.backgroundColor
        cell.selectionStyle = .none
        
        if let cell = cell as? CheckoutCreditCardTableViewCell, let card = cardFrc?.object(at: indexPath) {
            cell.nameLabel.text = card.fullName
            cell.editButton.addTarget(self, action: #selector(editButtonAction(_:event:)), for: .touchUpInside)
            
            let month = Int(card.expirationMonth)
            let year = Int(card.expirationYear)
            cell.setExpiration(month: month, year: year)
            cell.isExpired = CreditCardValidator.shared.isExpired(month: month, year: year)
        }
        
        return cell
    }
    
    @objc fileprivate func editButtonAction(_ button: UIButton, event: UIEvent) {
        guard let indexPath = tableView.indexPath(for: event),
            let card = cardFrc?.object(at: indexPath)
            else {
                return
        }
        
        let expirationDate = FormRow.Expiration.Date(month: Int(card.expirationMonth), year: Int(card.expirationYear))
        
        let formDefaultValues: [CheckoutPaymentFormKeys: String?] = [
            .addressCity: card.city,
            .addressCountry: card.country,
            .addressState: card.state,
            .addressStreet: card.street,
            .addressZip: card.zipCode,
//            .cardCVV: card.cvv,
            .cardExp: FormRow.Expiration.value(for: expirationDate),
            .cardName: card.fullName,
            .cardNumber: card.number,
            .email: card.email,
            .phoneNumber: card.phone
        ]
        
        let paymentFormViewController = CheckoutPaymentFormViewController(withDefaultValues: formDefaultValues)
        navigationController?.pushViewController(paymentFormViewController, animated: true)
    }
}

extension CheckoutPaymentListViewController: UITableViewDelegate {
    
}

extension CheckoutPaymentListViewController: FetchedResultsControllerManagerDelegate {
    func managerDidChangeContent(_ controller: NSObject, change: FetchedResultsControllerManagerChange) {
        if isViewLoaded {
            change.applyChanges(tableView: tableView)
        }
    }
}
