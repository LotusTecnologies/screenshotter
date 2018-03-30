//
//  CheckoutShippingViewController.swift
//  screenshot
//
//  Created by Corey Werner on 3/28/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class CheckoutShippingViewController: FormViewController {
    convenience init() {
        var formRows: [FormRow] = []
        
        let firstName = FormRow.Text()
        firstName.placeholder = "First Name"
        firstName.value = "Corey"
        formRows.append(firstName)
        
        let lastName = FormRow.Text()
        lastName.placeholder = "Last Name"
        formRows.append(lastName)
        
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
        
        let phone = FormRow.Phone()
        phone.placeholder = "Phone Number"
        formRows.append(phone)
        
        for _ in 0...10 {
            let phone = FormRow.Card()
            phone.placeholder = "Card"
            formRows.append(phone)
        }
        
        let section = FormSection()
        section.rows = formRows
        
        self.init(with: Form(with: [section]))
    }
}
