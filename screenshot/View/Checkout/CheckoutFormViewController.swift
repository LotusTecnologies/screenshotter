//
//  CheckoutFormViewController.swift
//  screenshot
//
//  Created by Corey Werner on 4/17/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class CheckoutFormViewController: FormViewController {
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
            tableFooterView.addSubview(deleteButton)
            deleteButton.topAnchor.constraint(equalTo: tableFooterView.topAnchor).isActive = true
            deleteButton.leadingAnchor.constraint(equalTo: tableFooterView.layoutMarginsGuide.leadingAnchor).isActive = true
            deleteButton.bottomAnchor.constraint(equalTo: tableFooterView.bottomAnchor).isActive = true
            deleteButton.trailingAnchor.constraint(equalTo: tableFooterView.layoutMarginsGuide.centerXAnchor, constant: -.padding / 2).isActive = true
            self.deleteButton = deleteButton
            
            continueButton.topAnchor.constraint(equalTo: tableFooterView.topAnchor).isActive = true
            continueButton.leadingAnchor.constraint(equalTo: deleteButton.trailingAnchor, constant: .padding).isActive = true
            continueButton.bottomAnchor.constraint(equalTo: tableFooterView.bottomAnchor).isActive = true
            continueButton.trailingAnchor.constraint(equalTo: tableFooterView.layoutMarginsGuide.trailingAnchor).isActive = true
        }
        else {
            continueButton.topAnchor.constraint(equalTo: tableFooterView.topAnchor).isActive = true
            continueButton.leadingAnchor.constraint(greaterThanOrEqualTo: tableFooterView.layoutMarginsGuide.leadingAnchor).isActive = true
            continueButton.bottomAnchor.constraint(equalTo: tableFooterView.bottomAnchor).isActive = true
            continueButton.trailingAnchor.constraint(lessThanOrEqualTo: tableFooterView.layoutMarginsGuide.trailingAnchor).isActive = true
            continueButton.centerXAnchor.constraint(equalTo: tableFooterView.centerXAnchor).isActive = true
        }
    }
}
