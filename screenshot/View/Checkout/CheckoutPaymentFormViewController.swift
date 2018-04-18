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
    
    convenience init(withCard card: Card? = nil) {
        let isEditLayout = card != nil
        
        var cardRows: [FormRow] = []
        var billingRows: [FormRow] = []
        
        let cardName = FormRow.Text(CheckoutPaymentFormKeys.cardName.rawValue)
        cardName.placeholder = "Name on Card"
        cardName.value = card?.fullName
        cardRows.append(cardName)
        
        let cardNumber = FormRow.Card(CheckoutPaymentFormKeys.cardNumber.rawValue)
        cardNumber.placeholder = "Card Number"
        cardNumber.value = card?.displayNumber
        cardRows.append(cardNumber)
        
        let exp = FormRow.Expiration(CheckoutPaymentFormKeys.cardExp.rawValue)
        exp.placeholder = "Exp"
        exp.value = {
            guard let card = card else {
                return nil
            }
            
            let date = FormRow.Expiration.Date(month: Int(card.expirationMonth), year: Int(card.expirationYear))
            return FormRow.Expiration.value(for: date)
        }()
        cardRows.append(exp)
        
        let cvv = FormRow.CVV(CheckoutPaymentFormKeys.cardCVV.rawValue)
        cvv.placeholder = "CVV"
        cardRows.append(cvv)
        
        let street = FormRow.Text(CheckoutPaymentFormKeys.addressStreet.rawValue)
        street.placeholder = "Street Address"
        street.value = card?.street
        billingRows.append(street)
        
        let city = FormRow.Text(CheckoutPaymentFormKeys.addressCity.rawValue)
        city.placeholder = "City"
        city.value = card?.city
        billingRows.append(city)
        
        let country = FormRow.Selection(CheckoutPaymentFormKeys.addressCountry.rawValue)
        country.placeholder = "Country"
        country.value = card?.country
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
        state.value = card?.state
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
        zip.value = card?.zipCode
        billingRows.append(zip)
        
        let email = FormRow.Email(CheckoutPaymentFormKeys.email.rawValue)
        email.placeholder = "Email"
        email.value = card?.email
        email.isRequired = false
        billingRows.append(email)
        
        let phone = FormRow.Phone(CheckoutPaymentFormKeys.phoneNumber.rawValue)
        phone.placeholder = "Phone Number"
        phone.value = card?.phone
        billingRows.append(phone)
        
        if !isEditLayout {
            let ship = FormRow.Checkbox(CheckoutPaymentFormKeys.addressShip.rawValue)
            ship.placeholder = "Ship to this address"
            billingRows.append(ship)
        }
        
        let cardSection = FormSection()
        cardSection.rows = cardRows
        
        let billingSection = FormSection()
        billingSection.title = "BILLING ADDRESS"
        billingSection.rows = billingRows
        
        self.init(with: Form(with: [cardSection, billingSection]))
        self.card = card
        
        title = isEditLayout ? "Edit Card" : "Add Card"
        restorationIdentifier = String(describing: type(of: self))
        
        generateButtons(withEditLayout: isEditLayout)
        
        if isEditLayout {
            
        }
    }
    
    func formRow(_ key: CheckoutPaymentFormKeys) -> FormRow? {
        return form.map?[key.rawValue]
    }
    
    var hasRequiredFields: Bool {
        if let sections = form.sections {
            for section in sections {
                guard let rows = section.rows else {
                    continue
                }
                
                for row in rows {
                    if row.isRequired && (row.value == nil || row.value!.isEmpty) {
                        return false
                    }
                }
            }
        }
        
        return true
    }
    
    @discardableResult func addCard(shouldSave: Bool) -> Bool {
        guard let cardName = formRow(.cardName)?.value,
            let cardNumber = formRow(.cardNumber)?.value,
            let cardExp = formRow(.cardExp)?.value,
//            let cardCVV = formRow(.cardCVV)?.value,
            let addressStreet = formRow(.addressStreet)?.value,
            let addressCity = formRow(.addressCity)?.value,
            let addressCountry = formRow(.addressCountry)?.value,
            let addressState = formRow(.addressState)?.value,
            let addressZip = formRow(.addressZip)?.value,
            let phone = formRow(.phoneNumber)?.value,
            let cardExpDate = FormRow.Expiration.date(for: cardExp),
            let secureNumber = CreditCardValidator.shared.secureNumber(cardNumber)
            else {
                // TODO: highlight fields with errors
                return false
        }
        
        let email = formRow(.email)?.value
        
        DataModel.sharedInstance.saveCard(fullName: cardName, number: cardNumber, displayNumber: secureNumber, expirationMonth: Int16(cardExpDate.month), expirationYear: Int16(cardExpDate.year), street: addressStreet, city: addressCity, country: addressCountry, zipCode: addressZip, state: addressState, email: email, phone: phone, isSaved: shouldSave)
        
        let addressShip = formRow(.addressShip)?.value
        let isShipToSameAddressChecked = FormRow.Checkbox.bool(for: addressShip)
        
        if isShipToSameAddressChecked {
            DataModel.sharedInstance.saveShippingAddress(fullName: cardName, street: addressStreet, city: addressCity, country: addressCountry, zipCode: addressZip, state: addressState, phone: phone)
        }
        
        return true
    }
    
    @discardableResult func updateCard() -> Bool {
        guard let cardName = formRow(.cardName)?.value,
            let cardNumber = formRow(.cardNumber)?.value,
            let cardExp = formRow(.cardExp)?.value,
            let addressStreet = formRow(.addressStreet)?.value,
            let addressCity = formRow(.addressCity)?.value,
            let addressCountry = formRow(.addressCountry)?.value,
            let addressState = formRow(.addressState)?.value,
            let addressZip = formRow(.addressZip)?.value,
            let phone = formRow(.phoneNumber)?.value,
            let cardExpDate = FormRow.Expiration.date(for: cardExp),
            let secureNumber = CreditCardValidator.shared.secureNumber(cardNumber),
            let card = card
            else {
                // TODO: highlight fields with errors
                return false
        }
        
        let email = formRow(.email)?.value
        
        card.edit(fullName: cardName, number: cardNumber, displayNumber: secureNumber, expirationMonth: Int16(cardExpDate.month), expirationYear: Int16(cardExpDate.year), street: addressStreet, city: addressCity, country: addressCountry, zipCode: addressZip, state: addressState, email: email, phone: phone)
        
        return true
    }
    
    @discardableResult func deleteCard() -> Bool {
        guard let card = card else {
            return false
        }
        
        card.delete()
        
        return true
    }
}
