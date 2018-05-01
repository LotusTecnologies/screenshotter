//
//  CheckoutPaymentFormViewController.swift
//  screenshot
//
//  Created by Corey Werner on 4/8/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import CreditCardValidator

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

class CheckoutPaymentFormViewController: CheckoutFormViewController {
    fileprivate var card: Card?
    fileprivate var supportedCountriesMap: CheckoutSupportedCountriesMap?
    fileprivate var supportedStatesMap: CheckoutSupportedStatesMap?
    private var confirmBeforeSave = false
    convenience init(withCard card: Card? = nil) {
        let isEditLayout = card != nil
        self.init(withCard: card, isEditLayout: isEditLayout, confirmBeforeSave: true)
    }
    
    convenience init(withCard card: Card? = nil, isEditLayout:Bool, confirmBeforeSave:Bool) {
        
        var cardRows: [FormRow] = []
        var billingRows: [FormRow] = []
        
        let cardName = FormRow.Text(CheckoutPaymentFormKeys.cardName.rawValue)
        cardName.title = "Name on Card"
        cardName.value = card?.fullName
        cardRows.append(cardName)
        
        let cardNumber = FormRow.Card(CheckoutPaymentFormKeys.cardNumber.rawValue)
        cardNumber.title = "Card Number"
        cardNumber.placeholder = card?.displayNumber
        cardRows.append(cardNumber)
        
        let exp = FormRow.Expiration(CheckoutPaymentFormKeys.cardExp.rawValue)
        exp.title = "Exp"
        exp.value = {
            guard let card = card else {
                return nil
            }
            
            let date = FormRow.Expiration.Date(month: Int(card.expirationMonth), year: Int(card.expirationYear))
            return FormRow.Expiration.value(for: date)
        }()
        cardRows.append(exp)
        
        if !isEditLayout {
            let cvv = FormRow.CVV(CheckoutPaymentFormKeys.cardCVV.rawValue)
            cvv.title = "CVV"
            cardRows.append(cvv)
        }
        
        let street = FormRow.Text(CheckoutPaymentFormKeys.addressStreet.rawValue)
        street.title = "Street Address"
        street.value = card?.street
        billingRows.append(street)
        
        let city = FormRow.Text(CheckoutPaymentFormKeys.addressCity.rawValue)
        city.title = "City"
        city.value = card?.city
        billingRows.append(city)
        
        let supportedCountriesMap = CheckoutSupportedCountriesMap()
        
        let country = FormRow.Selection(CheckoutPaymentFormKeys.addressCountry.rawValue)
        country.title = "Country"
        country.value = {
            var value: String?
            
            if let countryCode = card?.country {
                value = supportedCountriesMap.countryNames[countryCode]
            }
            
            return value ?? "United States"
        }()
        country.options = supportedCountriesMap.countryCodes.keys.sorted()
        billingRows.append(country)
        
        let supportedStatesMap = CheckoutSupportedStatesMap()
        
        let state = FormRow.Selection(CheckoutPaymentFormKeys.addressState.rawValue)
        state.condition = FormCondition(displayWhen: country, hasValue: "United States")
        state.isVisible = false
        state.title = "State"
        state.value = { // TODO: value should auto select the correct picker index
            var value: String?
            
            if let stateCode = card?.state {
                value = supportedStatesMap.stateNames[stateCode]
            }
            
            return value
        }()
        state.options = supportedStatesMap.stateCodes.keys.sorted()
        billingRows.append(state)
        
        let zip = FormRow.Zip(CheckoutPaymentFormKeys.addressZip.rawValue)
        zip.title = "Zip Code"
        zip.value = card?.zipCode
        billingRows.append(zip)
        
        let email = FormRow.Email(CheckoutPaymentFormKeys.email.rawValue)
        email.title = "Email"
        email.value = card?.email
        email.isRequired = false
        billingRows.append(email)
        
        let phone = FormRow.Phone(CheckoutPaymentFormKeys.phoneNumber.rawValue)
        phone.title = "Phone Number"
        phone.value = card?.phone
        billingRows.append(phone)
        
        if !isEditLayout {
            let ship = FormRow.Checkbox(CheckoutPaymentFormKeys.addressShip.rawValue)
            ship.title = "Ship to this address"
            billingRows.append(ship)
        }
        
        let cardSection = FormSection()
        cardSection.rows = cardRows
        
        let billingSection = FormSection()
        billingSection.title = "BILLING ADDRESS"
        billingSection.rows = billingRows
        
        self.init(with: Form(with: [cardSection, billingSection]))
        self.card = card
        self.supportedCountriesMap = supportedCountriesMap
        self.supportedStatesMap = supportedStatesMap
        
        title = isEditLayout ? "Edit Card" : "Add Card"
        restorationIdentifier = String(describing: type(of: self))
        
        let hasSaveAndDeleteButtons = (isEditLayout && card != nil)
        
        generateButtons(withEditLayout: hasSaveAndDeleteButtons)
        
        if hasSaveAndDeleteButtons {
            continueButton.addTarget(self, action: #selector(updateCard), for: .touchUpInside)
            deleteButton?.addTarget(self, action: #selector(removeCard), for: .touchUpInside)
        }
        else {
            continueButton.addTarget(self, action: #selector(addCard), for: .touchUpInside)
        }
        self.confirmBeforeSave = confirmBeforeSave
    }
    
    func formRow(_ key: CheckoutPaymentFormKeys) -> FormRow? {
        return form.map?[key.rawValue]
    }
    
    @objc fileprivate func addCard() {
        tableView.endEditing(true)
        
        guard form.hasValidFields,
            let cardName = formRow(.cardName)?.value,
            var cardNumber = formRow(.cardNumber)?.value,
            let cardExp = formRow(.cardExp)?.value,
            let addressStreet = formRow(.addressStreet)?.value,
            let addressCity = formRow(.addressCity)?.value,
            var addressCountry = formRow(.addressCountry)?.value,
            var addressState = formRow(.addressState)?.value,
            let addressZip = formRow(.addressZip)?.value,
            let phone = formRow(.phoneNumber)?.value,
            let cardExpDate = FormRow.Expiration.date(for: cardExp),
            let secureNumber = CreditCardValidator.shared.secureNumber(cardNumber)
            else {
                highlightErrorFields()
                return
        }
        let cardCVV = formRow(.cardCVV)?.value


        cardNumber = CreditCardValidator.shared.unformatNumber(cardNumber)
        let email = formRow(.email)?.value
        let addressShip = formRow(.addressShip)?.value
        let isShipToSameAddressChecked = FormRow.Checkbox.bool(for: addressShip)
        let brand = CreditCardValidator.shared.brand(forNumber: cardNumber)
        addressCountry = supportedCountriesMap?.countryCodes[addressCountry] ?? addressCountry
        addressState = supportedStatesMap?.stateCodes[addressState] ?? addressState
        
        func performAction(withSavingCard saveCard: Bool) {
            DataModel.sharedInstance.selectedCardURL = nil
            
            DataModel.sharedInstance.saveCard(fullName: cardName, number: cardNumber, displayNumber: secureNumber, brand: brand.rawValue, expirationMonth: Int16(cardExpDate.month), expirationYear: Int16(cardExpDate.year), street: addressStreet, city: addressCity, country: addressCountry, zipCode: addressZip, state: addressState, email: email, phone: phone, isSaved: saveCard)
                .then { card -> Void in
                    DataModel.sharedInstance.selectedCardURL = card.objectID.uriRepresentation()
                    
                    self.delegate?.checkoutFormViewControllerDidAdd(self)
            }
            
            if isShipToSameAddressChecked {
                DataModel.sharedInstance.saveShippingAddress(fullName: cardName, street: addressStreet, city: addressCity, country: addressCountry, zipCode: addressZip, state: addressState, phone: phone)
                    .then { shippingAddress -> Void in
                        DataModel.sharedInstance.selectedShippingAddressURL = shippingAddress.objectID.uriRepresentation()
                }
            }
        }
        if self.confirmBeforeSave {
            let alertController = UIAlertController(title: "Save Card?", message: "You can use this for future purchases. Your information is saved securely on your device.", preferredStyle: .alert)
            let saveAlertAction = UIAlertAction(title: "Save", style: .default) { alertAction in
                performAction(withSavingCard: true)
            }
            alertController.addAction(saveAlertAction)
            alertController.addAction(UIAlertAction(title: "Don't Save", style: .cancel, handler: { alertAction in
                performAction(withSavingCard: false)
            }))
            alertController.preferredAction = saveAlertAction
            present(alertController, animated: true, completion: nil)
        }else{
            performAction(withSavingCard: true)
            
        }
    }
    
    @objc fileprivate func updateCard() {
        tableView.endEditing(true)
        
        guard form.hasValidFields,
            let card = card,
            let cardName = formRow(.cardName)?.value ?? formRow(.cardName)?.placeholder,
            let cardNumber = formRow(.cardNumber)?.value,
            let cardExp = formRow(.cardExp)?.value,
            let addressStreet = formRow(.addressStreet)?.value,
            let addressCity = formRow(.addressCity)?.value,
            var addressCountry = formRow(.addressCountry)?.value,
            var addressState = formRow(.addressState)?.value,
            let addressZip = formRow(.addressZip)?.value,
            let phone = formRow(.phoneNumber)?.value,
            let cardExpDate = FormRow.Expiration.date(for: cardExp)
            else {
                highlightErrorFields()
                return
        }
        
        var newCardNumber: String?
        var newSecureNumber: String?
        var newBrand: String?
        
        if cardNumber != CreditCardValidator.shared.secureNumber(card.retrieveCardNumber()) {
            newCardNumber = CreditCardValidator.shared.unformatNumber(cardNumber)
            newSecureNumber = CreditCardValidator.shared.secureNumber(cardNumber)
            newBrand = CreditCardValidator.shared.brand(forNumber: cardNumber).rawValue
        }
        
        let email = formRow(.email)?.value
        addressCountry = supportedCountriesMap?.countryCodes[addressCountry] ?? addressCountry
        addressState = supportedStatesMap?.stateCodes[addressState] ?? addressState
        
        card.edit(fullName: cardName, number: newCardNumber, displayNumber: newSecureNumber, brand: newBrand, expirationMonth: Int16(cardExpDate.month), expirationYear: Int16(cardExpDate.year), street: addressStreet, city: addressCity, country: addressCountry, zipCode: addressZip, state: addressState, email: email, phone: phone)
        
        delegate?.checkoutFormViewControllerDidEdit(self)
    }
    
    @objc fileprivate func removeCard() {
        guard let card = card else {
            return
        }
        
        if let primaryCardURL = DataModel.sharedInstance.selectedCardURL {
            if primaryCardURL == card.objectID.uriRepresentation() {
                DataModel.sharedInstance.selectedCardURL = nil
            }
        }
        
        card.delete()
        
        delegate?.checkoutFormViewControllerDidRemove(self)
    }
}
