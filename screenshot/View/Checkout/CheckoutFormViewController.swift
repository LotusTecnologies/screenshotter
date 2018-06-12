//
//  CheckoutFormViewController.swift
//  screenshot
//
//  Created by Corey Werner on 4/17/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit

protocol CheckoutFormViewControllerDelegate: NSObjectProtocol {
    func checkoutFormViewControllerDidAdd(_ viewController: CheckoutFormViewController)
    func checkoutFormViewControllerDidEdit(_ viewController: CheckoutFormViewController)
    func checkoutFormViewControllerDidRemove(_ viewController: CheckoutFormViewController)
}

extension CheckoutFormViewControllerDelegate {
    func checkoutFormViewControllerDidAdd(_ viewController: CheckoutFormViewController) {}
    func checkoutFormViewControllerDidEdit(_ viewController: CheckoutFormViewController) {}
    func checkoutFormViewControllerDidRemove(_ viewController: CheckoutFormViewController) {}
}

class CheckoutFormViewController: FormViewController {
    weak var delegate: CheckoutFormViewControllerDelegate?
    let continueButton = MainButton()
    private(set) var deleteButton: MainButton?
    
    func generateButtons(withEditLayout isEditLayout: Bool) {
        var contentInset = tableView.contentInset
        contentInset.bottom = 20
        tableView.contentInset = contentInset
        
        var tableFooterRect: CGRect = .zero
        tableFooterRect.size.height = continueButton.intrinsicContentSize.height
        let tableFooterView = UIView(frame: tableFooterRect)
        tableFooterView.layoutMargins = UIEdgeInsets(top: 0, left: .padding, bottom: 0, right: .padding)
        tableView.tableFooterView = tableFooterView
        
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.backgroundColor = .crazeGreen
        tableFooterView.addSubview(continueButton)
        
        if isEditLayout {
            let deleteButton = MainButton()
            deleteButton.translatesAutoresizingMaskIntoConstraints = false
            deleteButton.backgroundColor = .white
            deleteButton.setTitleColor(.gray6, for: .normal)
            deleteButton.setTitle("generic.delete".localized, for: .normal)
            tableFooterView.addSubview(deleteButton)
            deleteButton.topAnchor.constraint(equalTo: tableFooterView.topAnchor).isActive = true
            deleteButton.leadingAnchor.constraint(equalTo: tableFooterView.layoutMarginsGuide.leadingAnchor).isActive = true
            deleteButton.bottomAnchor.constraint(equalTo: tableFooterView.bottomAnchor).isActive = true
            deleteButton.trailingAnchor.constraint(equalTo: tableFooterView.layoutMarginsGuide.centerXAnchor, constant: -.padding / 2).isActive = true
            self.deleteButton = deleteButton
            
            continueButton.setTitle("generic.save".localized, for: .normal)
            continueButton.topAnchor.constraint(equalTo: tableFooterView.topAnchor).isActive = true
            continueButton.leadingAnchor.constraint(equalTo: deleteButton.trailingAnchor, constant: .padding).isActive = true
            continueButton.bottomAnchor.constraint(equalTo: tableFooterView.bottomAnchor).isActive = true
            continueButton.trailingAnchor.constraint(equalTo: tableFooterView.layoutMarginsGuide.trailingAnchor).isActive = true
        }
        else {
            continueButton.setTitle("generic.done".localized, for: .normal)
            continueButton.topAnchor.constraint(equalTo: tableFooterView.topAnchor).isActive = true
            continueButton.leadingAnchor.constraint(greaterThanOrEqualTo: tableFooterView.layoutMarginsGuide.leadingAnchor).isActive = true
            continueButton.bottomAnchor.constraint(equalTo: tableFooterView.bottomAnchor).isActive = true
            continueButton.trailingAnchor.constraint(lessThanOrEqualTo: tableFooterView.layoutMarginsGuide.trailingAnchor).isActive = true
            continueButton.centerXAnchor.constraint(equalTo: tableFooterView.centerXAnchor).isActive = true
        }
    }
}
