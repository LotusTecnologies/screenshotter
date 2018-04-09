//
//  CheckoutPaymentViewController.swift
//  screenshot
//
//  Created by Corey Werner on 4/8/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

enum CheckoutPaymentFormKeys: Int {
    case addressCity
    case addressCountry
    case addressShip
    case addressState
    case addressStreet
    case addressZip
    
    case cardCVV
    case cardExp
    case cardName
    case cardNumber
    
    case email
    case phoneNumber
}

class CheckoutPaymentViewController: FormViewController {
    let doneButton = MainButton()
    
    convenience init() {
        var formRows: [FormRow] = []
        
        let cardName = FormRow.Text(CheckoutPaymentFormKeys.cardName.rawValue)
        cardName.placeholder = "Name on Card"
        formRows.append(cardName)
        
        let cardNumber = FormRow.Card(CheckoutPaymentFormKeys.cardNumber.rawValue)
        cardNumber.placeholder = "Card Number"
        formRows.append(cardNumber)
        
        let exp = FormRow.Date(CheckoutPaymentFormKeys.cardExp.rawValue)
        exp.placeholder = "Exp"
        formRows.append(exp)
        
        let cvv = FormRow.Number(CheckoutPaymentFormKeys.cardCVV.rawValue)
        cvv.placeholder = "CVV"
        formRows.append(cvv)
        
        let street = FormRow.Text(CheckoutPaymentFormKeys.addressStreet.rawValue)
        street.placeholder = "Street Address"
        formRows.append(street)
        
        let city = FormRow.Text(CheckoutPaymentFormKeys.addressCity.rawValue)
        city.placeholder = "City"
        formRows.append(city)
        
        let country = FormRow.Selection(CheckoutPaymentFormKeys.addressCountry.rawValue)
        country.placeholder = "Country"
        country.options = [
            "United States",
            "Agartha",
            "Antartica",
            "Atlantis",
            "Bermuda",
            "Categat",
            "Pangea"
        ]
        formRows.append(country)
        
        let state = FormRow.Selection(CheckoutPaymentFormKeys.addressState.rawValue)
        state.condition = FormCondition(displayWhen: country, hasValue: "United States")
        state.isVisible = false
        state.placeholder = "State"
        state.options = [
            "United States",
            "Agartha",
            "Antartica",
            "Atlantis",
            "Bermuda",
            "Categat",
            "Pangea"
        ]
        formRows.append(state)
        
        let zip = FormRow.Number(CheckoutPaymentFormKeys.addressZip.rawValue)
        zip.placeholder = "Zip Code"
        formRows.append(zip)
        
        let email = FormRow.Email(CheckoutPaymentFormKeys.email.rawValue)
        email.placeholder = "Email"
        formRows.append(email)
        
        let phone = FormRow.Phone(CheckoutPaymentFormKeys.phoneNumber.rawValue)
        phone.placeholder = "Phone Number"
        formRows.append(phone)
        
        let ship = FormRow.Checkbox(CheckoutPaymentFormKeys.addressShip.rawValue)
        ship.placeholder = "Ship to this address"
        formRows.append(ship)
        
        let section = FormSection()
        section.rows = formRows
        
        self.init(with: Form(with: [section]))
        
        title = "Add A Card"
        restorationIdentifier = String(describing: type(of: self))
        
        var contentInset = tableView.contentInset
        contentInset.bottom = 20
        tableView.contentInset = contentInset
        
        var tableFooterRect: CGRect = .zero
        tableFooterRect.size.height = doneButton.intrinsicContentSize.height
        let tableFooterView = UIView(frame: tableFooterRect)
        tableView.tableFooterView = tableFooterView
        
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.backgroundColor = .crazeGreen
        doneButton.setTitle("Done", for: .normal)
        tableFooterView.addSubview(doneButton)
        doneButton.topAnchor.constraint(equalTo: tableFooterView.topAnchor).isActive = true
        doneButton.bottomAnchor.constraint(equalTo: tableFooterView.bottomAnchor).isActive = true
        doneButton.centerXAnchor.constraint(equalTo: tableFooterView.centerXAnchor).isActive = true
    }
}
