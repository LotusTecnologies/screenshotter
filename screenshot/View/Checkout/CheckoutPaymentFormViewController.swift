//
//  CheckoutPaymentFormViewController.swift
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

class CheckoutPaymentFormViewController: FormViewController {
    let doneButton = MainButton()
    
    convenience init() {
        var cardRows: [FormRow] = []
        var billingRows: [FormRow] = []
        
        let cardName = FormRow.Text(CheckoutPaymentFormKeys.cardName.rawValue)
        cardName.placeholder = "Name on Card"
        cardRows.append(cardName)
        
        let cardNumber = FormRow.Card(CheckoutPaymentFormKeys.cardNumber.rawValue)
        cardNumber.placeholder = "Card Number"
        cardRows.append(cardNumber)
        
        let exp = FormRow.Expiration(CheckoutPaymentFormKeys.cardExp.rawValue)
        exp.placeholder = "Exp"
        exp.value = "04/2020" // !!!: DEBUG
        cardRows.append(exp)
        
        let cvv = FormRow.CVV(CheckoutPaymentFormKeys.cardCVV.rawValue)
        cvv.placeholder = "CVV"
        cardRows.append(cvv)
        
        let street = FormRow.Text(CheckoutPaymentFormKeys.addressStreet.rawValue)
        street.placeholder = "Street Address"
        billingRows.append(street)
        
        let city = FormRow.Text(CheckoutPaymentFormKeys.addressCity.rawValue)
        city.placeholder = "City"
        billingRows.append(city)
        
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
        billingRows.append(country)
        
        let state = FormRow.Selection(CheckoutPaymentFormKeys.addressState.rawValue)
        state.condition = FormCondition(displayWhen: country, hasValue: "United States")
        state.isVisible = false
        state.placeholder = "State"
        state.options = [
            "Maryland",
            "Agartha",
            "Antartica",
            "Atlantis",
            "Bermuda",
            "Categat",
            "Pangea"
        ]
        billingRows.append(state)
        
        let zip = FormRow.Zip(CheckoutPaymentFormKeys.addressZip.rawValue)
        zip.placeholder = "Zip Code"
        billingRows.append(zip)
        
        let email = FormRow.Email(CheckoutPaymentFormKeys.email.rawValue)
        email.placeholder = "Email"
        billingRows.append(email)
        
        let phone = FormRow.Phone(CheckoutPaymentFormKeys.phoneNumber.rawValue)
        phone.placeholder = "Phone Number"
        billingRows.append(phone)
        
        let ship = FormRow.Checkbox(CheckoutPaymentFormKeys.addressShip.rawValue)
        ship.placeholder = "Ship to this address"
        billingRows.append(ship)
        
        let cardSection = FormSection()
        cardSection.rows = cardRows
        
        let billingSection = FormSection()
        billingSection.title = "BILLING ADDRESS"
        billingSection.rows = billingRows
        
        self.init(with: Form(with: [cardSection, billingSection]))
        
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
    
    func formRow(_ key: CheckoutPaymentFormKeys) -> FormRow? {
        return form.map?[key.rawValue]
    }
}
