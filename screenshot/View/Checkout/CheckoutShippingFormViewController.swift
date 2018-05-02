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
        firstName.title = "form.address.first_name".localized
        firstName.value = shippingAddress?.firstName
        formRows.append(firstName)
        
        let lastName = FormRow.Text(CheckoutShippingFormKeys.nameLast.rawValue)
        lastName.title = "form.address.last_name".localized
        lastName.value = shippingAddress?.lastName
        formRows.append(lastName)
        
        let street = FormRow.Text(CheckoutShippingFormKeys.addressStreet.rawValue)
        street.title = "form.address.street".localized
        street.value = shippingAddress?.street
        formRows.append(street)
        
        let city = FormRow.Text(CheckoutShippingFormKeys.addressCity.rawValue)
        city.title = "form.address.city".localized
        city.value = shippingAddress?.city
        formRows.append(city)
        
        let supportedCountriesMap = CheckoutSupportedCountriesMap()
        
        let country = FormRow.Selection(CheckoutShippingFormKeys.addressCountry.rawValue)
        country.title = "form.address.country".localized
        country.value = {
            var value: String?
            
            if let countryCode = shippingAddress?.country {
                value = supportedCountriesMap.countryNames[countryCode]
            }
            
            return value ?? "United States"
        }()
        country.options = supportedCountriesMap.countryCodes.keys.sorted()
        formRows.append(country)
        
        let supportedStatesMap = CheckoutSupportedStatesMap()
        
        let state = FormRow.Selection(CheckoutShippingFormKeys.addressState.rawValue)
        state.condition = FormCondition(displayWhen: country, hasValue: "United States")
        state.isVisible = false
        state.title = "form.address.state".localized
        state.value = {
            var value: String?
            
            if let stateCode = shippingAddress?.state {
                value = supportedStatesMap.stateNames[stateCode]
            }
            
            return value
        }()
        state.options = supportedStatesMap.stateCodes.keys.sorted()
        formRows.append(state)
        
        let zip = FormRow.Number(CheckoutShippingFormKeys.addressZip.rawValue)
        zip.title = "form.address.zip".localized
        zip.value = shippingAddress?.zipCode
        formRows.append(zip)
        
        let phone = FormRow.Phone(CheckoutShippingFormKeys.phoneNumber.rawValue)
        phone.title = "form.personal.phone".localized
        phone.value = shippingAddress?.phone
        formRows.append(phone)
        
        let section = FormSection()
        section.rows = formRows
        
        self.init(with: Form(with: [section]))
        self.shippingAddress = shippingAddress
        self.supportedCountriesMap = supportedCountriesMap
        self.supportedStatesMap = supportedStatesMap
        
        title = isEditLayout ? "checkout.form.address.edit".localized : "checkout.form.address.add".localized
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
        tableView.endEditing(true)
        
        guard form.hasValidFields,
            let addressCity = formRow(.addressCity)?.value,
            var addressCountry = formRow(.addressCountry)?.value,
            var addressState = formRow(.addressState)?.value,
            let addressStreet = formRow(.addressStreet)?.value,
            let addressZip = formRow(.addressZip)?.value,
            let nameFirst = formRow(.nameFirst)?.value,
            let nameLast = formRow(.nameLast)?.value,
            let phone = formRow(.phoneNumber)?.value
            else {
                highlightErrorFields()
                return
        }
        
        addressCountry = supportedCountriesMap?.countryCodes[addressCountry] ?? addressCountry
        addressState = supportedStatesMap?.stateCodes[addressState] ?? addressState
        
        DataModel.sharedInstance.selectedShippingAddressURL = nil
        
        DataModel.sharedInstance.saveShippingAddress(firstName: nameFirst, lastName: nameLast, street: addressStreet, city: addressCity, country: addressCountry, zipCode: addressZip, state: addressState, phone: phone)
            .then { shippingAddress -> Void in
                DispatchQueue.main.async {
                    DataModel.sharedInstance.selectedShippingAddressURL = shippingAddress.objectID.uriRepresentation()
                    
                    self.delegate?.checkoutFormViewControllerDidAdd(self)
                }
        }
    }
    
    @objc fileprivate func updateShippingAddress() {
        tableView.endEditing(true)
        
        guard form.hasValidFields,
            let addressCity = formRow(.addressCity)?.value,
            var addressCountry = formRow(.addressCountry)?.value,
            var addressState = formRow(.addressState)?.value,
            let addressStreet = formRow(.addressStreet)?.value,
            let addressZip = formRow(.addressZip)?.value,
            let nameFirst = formRow(.nameFirst)?.value,
            let nameLast = formRow(.nameLast)?.value,
            let phone = formRow(.phoneNumber)?.value,
            let shippingAddress = shippingAddress
            else {
                highlightErrorFields()
                return
        }
        
        addressCountry = supportedCountriesMap?.countryCodes[addressCountry] ?? addressCountry
        addressState = supportedStatesMap?.stateCodes[addressState] ?? addressState
        
        shippingAddress.edit(firstName: nameFirst, lastName: nameLast, street: addressStreet, city: addressCity, country: addressCountry, zipCode: addressZip, state: addressState, phone: phone)
        
        delegate?.checkoutFormViewControllerDidEdit(self)
    }
    
    @objc fileprivate func removeShippingAddress() {
        guard let shippingAddress = shippingAddress else {
            return
        }
        
        if let primaryShippingURL = DataModel.sharedInstance.selectedShippingAddressURL {
            if primaryShippingURL == shippingAddress.objectID.uriRepresentation() {
                DataModel.sharedInstance.selectedShippingAddressURL = nil
            }
        }
        
        shippingAddress.delete()
        
        delegate?.checkoutFormViewControllerDidRemove(self)
    }
}
