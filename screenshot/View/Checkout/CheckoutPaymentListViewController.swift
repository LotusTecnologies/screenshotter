//
//  CheckoutPaymentListViewController.swift
//  screenshot
//
//  Created by Corey Werner on 4/10/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import CreditCardValidator
import UIKit
import CoreData

class CheckoutPaymentListViewController: CheckoutListViewController {
    fileprivate var cardFrc: FetchedResultsControllerManager<Card>?
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        title = "checkout.list.payment.title".localized
        restorationIdentifier = String(describing: type(of: self))
        
        cardFrc = DataModel.sharedInstance.cardFrc(delegate: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 150
        tableView.register(CheckoutCreditCardTableViewCell.self, forCellReuseIdentifier: "cell")
        
        addButton.setTitle("checkout.list.payment.add_card".localized, for: .normal)
        addButton.setImage(UIImage(named: "CheckoutCreditCard"), for: .normal)
        addButton.addTarget(self, action: #selector(addButtonAction), for: .touchUpInside)
        addButton.sizeToFit()
    }
    
    deinit {
        tableView.dataSource = nil
        tableView.delegate = nil
    }
    
    // MARK: Actions
    
    @objc fileprivate func addButtonAction() {
        let paymentFormViewController = CheckoutPaymentFormViewController()
        paymentFormViewController.delegate = self
        navigationController?.pushViewController(paymentFormViewController, animated: true)
    }
    
    @objc fileprivate func editButtonAction(_ button: UIButton, event: UIEvent) {
        guard let indexPath = tableView.indexPath(for: event) else {
            return
        }
        
        let card = cardFrc?.object(at: indexPath)
        let paymentFormViewController = CheckoutPaymentFormViewController(withCard: card)
        paymentFormViewController.delegate = self
        navigationController?.pushViewController(paymentFormViewController, animated: true)
    }
    
    // MARK: Selection
    
    override func indexPathForSelectedCell() -> IndexPath? {
        let card: Card? = {
            if let url = DataModel.sharedInstance.selectedCardURL,
                let objectID = DataModel.sharedInstance.mainMoc().objectId(for: url),
                let card = DataModel.sharedInstance.mainMoc().cardWith(objectId: objectID)
            {
                return card
            }
            
            if let card = cardFrc?.fetchedObjects.first {
                DataModel.sharedInstance.selectedCardURL = card.objectID.uriRepresentation()
                return card
            }
            
            return nil
        }()
        
        if let card = card {
            return cardFrc?.indexPath(forObject: card)
        }
        else {
            return nil
        }
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
            cell.cardNumberLabel.text = card.displayNumber
            cell.editButton.addTarget(self, action: #selector(editButtonAction(_:event:)), for: .touchUpInside)
            cell.isTempCard = !card.isSaved
            
            let month = Int(card.expirationMonth)
            let year = Int(card.expirationYear)
            cell.setExpiration(month: month, year: year)
            cell.isExpired = CreditCardValidator.shared.isExpired(month: month, year: year)
            
            if let brandString = card.brand, let brand = CreditCardBrand(rawValue: brandString) {
                cell.setBrandImage(brand)
            }
            else {
                cell.setBrandImage(.unknown)
            }
        }
        
        return cell
    }
}

extension CheckoutPaymentListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let card = cardFrc?.object(at: indexPath) {
            DataModel.sharedInstance.selectedCardURL = card.objectID.uriRepresentation()
        }
    }
}
