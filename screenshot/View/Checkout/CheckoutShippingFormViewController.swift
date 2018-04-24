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
    fileprivate var shippingAddress: ShippingAddress?
    fileprivate var supportedCountriesMap: CheckoutSupportedCountriesMap?
    fileprivate var supportedStatesMap: CheckoutSupportedStatesMap?
    
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
        
        let supportedCountriesMap = CheckoutSupportedCountriesMap()
        
        let country = FormRow.Selection(CheckoutShippingFormKeys.addressCountry.rawValue)
        country.placeholder = "Country"
        country.value = shippingAddress?.country ?? "United States"
        country.options = supportedCountriesMap.countries.keys.sorted()
        formRows.append(country)
        
        let supportedStatesMap = CheckoutSupportedStatesMap()
        
        let state = FormRow.Selection(CheckoutShippingFormKeys.addressState.rawValue)
        state.condition = FormCondition(displayWhen: country, hasValue: "United States")
        state.isVisible = false
        state.placeholder = "State"
        state.value = shippingAddress?.state
        state.options = supportedStatesMap.states.keys.sorted()
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
        self.shippingAddress = shippingAddress
        self.supportedCountriesMap = supportedCountriesMap
        self.supportedStatesMap = supportedStatesMap
        
        title = isEditLayout ? "Edit Address" : "Add Address"
        restorationIdentifier = String(describing: type(of: self))
        
        generateButtons(withEditLayout: isEditLayout)
        
        if isEditLayout {
            continueButton.addTarget(self, action: #selector(updateShippingAddress), for: .touchUpInside)
            deleteButton?.addTarget(self, action: #selector(removeShippingAddress), for: .touchUpInside)
        }
        else {
            continueButton.addTarget(self, action: #selector(addShippingAddress), for: .touchUpInside)
        }
    }
    
    func formRow(_ key: CheckoutShippingFormKeys) -> FormRow? {
        return form.map?[key.rawValue]
    }
    
    @objc fileprivate func addShippingAddress() {
        guard let addressCity = formRow(.addressCity)?.value,
            var addressCountry = formRow(.addressCountry)?.value,
            var addressState = formRow(.addressState)?.value,
            let addressStreet = formRow(.addressStreet)?.value,
            let addressZip = formRow(.addressZip)?.value,
            let nameFirst = formRow(.nameFirst)?.value,
            let nameLast = formRow(.nameLast)?.value,
            let phone = formRow(.phoneNumber)?.value
            else {
                // TODO: highlight fields with errors
                return
        }
        
        addressCountry = supportedCountriesMap?.countries[addressCountry] ?? addressCountry
        addressState = supportedStatesMap?.states[addressState] ?? addressState
        
        DataModel.sharedInstance.saveShippingAddress(firstName: nameFirst, lastName: nameLast, street: addressStreet, city: addressCity, country: addressCountry, zipCode: addressZip, state: addressState, phone: phone)
            .then { shippingAddress -> Void in
                let shippingAddressURL = shippingAddress.objectID.uriRepresentation()
                UserDefaults.standard.set(shippingAddressURL, forKey: Constants.checkoutPrimaryAddressURL)
                UserDefaults.standard.synchronize()
        }
        
        delegate?.checkoutFormViewControllerDidAdd(self)
    }
    
    @objc fileprivate func updateShippingAddress() {
        guard let addressCity = formRow(.addressCity)?.value,
            var addressCountry = formRow(.addressCountry)?.value,
            var addressState = formRow(.addressState)?.value,
            let addressStreet = formRow(.addressStreet)?.value,
            let addressZip = formRow(.addressZip)?.value,
            let nameFirst = formRow(.nameFirst)?.value,
            let nameLast = formRow(.nameLast)?.value,
            let phone = formRow(.phoneNumber)?.value,
            let shippingAddress = shippingAddress
            else {
                // TODO: highlight fields with errors
                return
        }
        
        addressCountry = supportedCountriesMap?.countries[addressCountry] ?? addressCountry
        addressState = supportedStatesMap?.states[addressState] ?? addressState
        
        shippingAddress.edit(firstName: nameFirst, lastName: nameLast, street: addressStreet, city: addressCity, country: addressCountry, zipCode: addressZip, state: addressState, phone: phone)
        
        delegate?.checkoutFormViewControllerDidEdit(self)
    }
    
    @objc fileprivate func removeShippingAddress() {
        guard let shippingAddress = shippingAddress else {
            return
        }
        
        if let primaryShippingURL = UserDefaults.standard.url(forKey: Constants.checkoutPrimaryAddressURL) {
            if primaryShippingURL == shippingAddress.objectID.uriRepresentation() {
                UserDefaults.standard.set(nil, forKey: Constants.checkoutPrimaryAddressURL)
            }
        }
        
        shippingAddress.delete()
        
        delegate?.checkoutFormViewControllerDidRemove(self)
    }
}
