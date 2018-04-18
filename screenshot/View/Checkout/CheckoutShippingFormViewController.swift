//
//  CheckoutShippingFormViewController.swift
//  screenshot
//
//  Created by Corey Werner on 3/28/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

enum CheckoutShippingFormKeys: Int {
    case addressCity
    case addressCountry
    case addressState
    case addressStreet
    case addressZip
    
    case nameFirst
    case nameLast
    case phoneNumber
}

class CheckoutShippingFormViewController: CheckoutFormViewController {
    convenience init(withShippingAddress shippingAddress: ShippingAddress? = nil) {
        let isEditLayout = shippingAddress != nil
        
        var formRows: [FormRow] = []
        
        let firstName = FormRow.Text(CheckoutShippingFormKeys.nameFirst.rawValue)
        firstName.placeholder = "First Name"
        firstName.value = shippingAddress?.firstName
        formRows.append(firstName)
        
        let lastName = FormRow.Text(CheckoutShippingFormKeys.nameLast.rawValue)
        lastName.placeholder = "Last Name"
        lastName.value = shippingAddress?.lastName
        formRows.append(lastName)
        
        let street = FormRow.Text(CheckoutShippingFormKeys.addressStreet.rawValue)
        street.placeholder = "Street Address"
        street.value = shippingAddress?.street
        formRows.append(street)
        
        let city = FormRow.Text(CheckoutShippingFormKeys.addressCity.rawValue)
        city.placeholder = "City"
        city.value = shippingAddress?.city
        formRows.append(city)
        
        let country = FormRow.Selection(CheckoutShippingFormKeys.addressCountry.rawValue)
        country.placeholder = "Country"
        country.value = shippingAddress?.country
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
        
        let state = FormRow.Selection(CheckoutShippingFormKeys.addressState.rawValue)
        state.condition = FormCondition(displayWhen: country, hasValue: "United States")
        state.isVisible = false
        state.placeholder = "State"
        state.value = shippingAddress?.state
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
        
        let zip = FormRow.Number(CheckoutShippingFormKeys.addressZip.rawValue)
        zip.placeholder = "Zip Code"
        zip.value = shippingAddress?.zipCode
        formRows.append(zip)
        
        let phone = FormRow.Phone(CheckoutShippingFormKeys.phoneNumber.rawValue)
        phone.placeholder = "Phone Number"
        phone.value = shippingAddress?.phone
        formRows.append(phone)
        
        let section = FormSection()
        section.rows = formRows
        
        self.init(with: Form(with: [section]))
        
        title = isEditLayout ? "Edit Address" : "Add Address"
        restorationIdentifier = String(describing: type(of: self))
        
        generateButtons(withEditLayout: isEditLayout)
    }
    
    func formRow(_ key: CheckoutShippingFormKeys) -> FormRow? {
        return form.map?[key.rawValue]
    }
}
