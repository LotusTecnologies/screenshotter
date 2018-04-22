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
        addButton.addTarget(self, action: #selector(addButtonAction), for: .touchUpInside)
        addButton.sizeToFit()
        tableView.tableFooterView = addButton
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let cardURL = UserDefaults.standard.url(forKey: Constants.checkoutPrimaryCardURL),
            let objectID = DataModel.sharedInstance.mainMoc().objectId(for: cardURL),
            let card = DataModel.sharedInstance.mainMoc().cardWith(objectId: objectID),
            let indexPath = cardFrc?.indexPath(forObject: card)
        {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
    }
    
    deinit {
        tableView.dataSource = nil
        tableView.delegate = nil
    }
    
    @objc fileprivate func addButtonAction() {
        let paymentFormViewController = CheckoutPaymentFormViewController()
        paymentFormViewController.continueButton.addTarget(self, action: #selector(addCardAction), for: .touchUpInside)
        navigationController?.pushViewController(paymentFormViewController, animated: true)
    }
    
    @objc fileprivate func addCardAction() {
        guard let paymentFormViewController = navigationController?.topViewController as? CheckoutPaymentFormViewController else {
            return
        }
        
        paymentFormViewController.addCard { [weak self] didSave in
            self?.navigationController?.popViewController(animated: true)
        }
    }
    
    @objc fileprivate func updateCardAction() {
        guard let paymentFormViewController = navigationController?.topViewController as? CheckoutPaymentFormViewController else {
            return
        }
        
        let didUpdateCard = paymentFormViewController.updateCard()
        
        if didUpdateCard {
            navigationController?.popViewController(animated: true)
        }
    }
    
    @objc fileprivate func deleteCardAction() {
        guard let paymentFormViewController = navigationController?.topViewController as? CheckoutPaymentFormViewController else {
            return
        }
        
        let didDeleteCard = paymentFormViewController.deleteCard()
        
        if didDeleteCard {
            navigationController?.popViewController(animated: true)
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
            
            let month = Int(card.expirationMonth)
            let year = Int(card.expirationYear)
            cell.setExpiration(month: month, year: year)
            cell.isExpired = CreditCardValidator.shared.isExpired(month: month, year: year)
            
            // TODO: gershon needs to allow for saving card brand in db
            cell.setBrandImage(.JCB)
        }
        
        return cell
    }
    
    @objc fileprivate func editButtonAction(_ button: UIButton, event: UIEvent) {
        guard let indexPath = tableView.indexPath(for: event) else {
            return
        }
        
        let card = cardFrc?.object(at: indexPath)
        let paymentFormViewController = CheckoutPaymentFormViewController(withCard: card)
        paymentFormViewController.continueButton.addTarget(self, action: #selector(updateCardAction), for: .touchUpInside)
        paymentFormViewController.deleteButton?.addTarget(self, action: #selector(deleteCardAction), for: .touchUpInside)
        navigationController?.pushViewController(paymentFormViewController, animated: true)
    }
}

extension CheckoutPaymentListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let card = cardFrc?.object(at: indexPath) {
            let cardURL = card.objectID.uriRepresentation()
            UserDefaults.standard.set(cardURL, forKey: Constants.checkoutPrimaryCardURL)
            UserDefaults.standard.synchronize()
        }
    }
}

extension CheckoutPaymentListViewController: FetchedResultsControllerManagerDelegate {
    func managerDidChangeContent(_ controller: NSObject, change: FetchedResultsControllerManagerChange) {
        if isViewLoaded {
            change.applyChanges(tableView: tableView)
        }
    }
}
