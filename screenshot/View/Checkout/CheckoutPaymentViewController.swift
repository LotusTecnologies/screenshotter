//
//  CheckoutPaymentViewController.swift
//  screenshot
//
//  Created by Corey Werner on 4/8/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class CheckoutPaymentViewController: FormViewController {
    convenience init() {
        var formRows: [FormRow] = []
        
        let cardName = FormRow.Text()
        cardName.placeholder = "Name on Card"
        formRows.append(cardName)
        
        let cardNumber = FormRow.Card()
        cardNumber.placeholder = "Card Number"
        formRows.append(cardNumber)
        
        let exp = FormRow.Date()
        exp.placeholder = "Exp"
        formRows.append(exp)
        
        let cvv = FormRow.Number()
        cvv.placeholder = "CVV"
        formRows.append(cvv)
        
        let address = FormRow.Text()
        address.placeholder = "Street Address"
        formRows.append(address)
        
        let city = FormRow.Text()
        city.placeholder = "City"
        formRows.append(city)
        
        let country = FormRow.Selection()
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
        
        let state = FormRow.Selection()
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
        
        let zip = FormRow.Number()
        zip.placeholder = "Zip Code"
        formRows.append(zip)
        
        let email = FormRow.Email()
        email.placeholder = "Email"
        formRows.append(email)
        
        let phone = FormRow.Phone()
        phone.placeholder = "Phone Number"
        formRows.append(phone)
        
        let ship = FormRow.Checkbox()
        ship.placeholder = "Ship to this address"
        formRows.append(ship)
        
        let section = FormSection()
        section.rows = formRows
        
        self.init(with: Form(with: [section]))
        
        title = "Add A Card"
        restorationIdentifier = String(describing: type(of: self))
    }
}
