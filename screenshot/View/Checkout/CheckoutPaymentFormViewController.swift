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
        state.options = USStatesMap().states.keys.sorted()
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
            continueButton.addTarget(self, action: #selector(updateCard), for: .touchUpInside)
            deleteButton?.addTarget(self, action: #selector(removeCard), for: .touchUpInside)
        }
        else {
            continueButton.addTarget(self, action: #selector(addCard), for: .touchUpInside)
        }
    }
    
    func formRow(_ key: CheckoutPaymentFormKeys) -> FormRow? {
        return form.map?[key.rawValue]
    }
    
    @objc fileprivate func addCard() {
        guard let cardName = formRow(.cardName)?.value,
            let cardNumber = formRow(.cardNumber)?.value,
            let cardExp = formRow(.cardExp)?.value,
            let cardCVV = formRow(.cardCVV)?.value,
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
                return
        }
        
        let email = formRow(.email)?.value
        let addressShip = formRow(.addressShip)?.value
        let isShipToSameAddressChecked = FormRow.Checkbox.bool(for: addressShip)
        let brand = CreditCardValidator.shared.brand(forNumber: cardNumber)
        
        func performAction(withSavingCard saveCard: Bool) {
            DataModel.sharedInstance.saveCard(fullName: cardName, number: cardNumber, displayNumber: secureNumber, brand: brand.rawValue, expirationMonth: Int16(cardExpDate.month), expirationYear: Int16(cardExpDate.year), street: addressStreet, city: addressCity, country: addressCountry, zipCode: addressZip, state: addressState, email: email, phone: phone, isSaved: saveCard)
                .then { card -> Void in
                    card.cvv = cardCVV
                    
                    let cardURL = card.objectID.uriRepresentation()
                    UserDefaults.standard.set(cardURL, forKey: Constants.checkoutPrimaryCardURL)
                    UserDefaults.standard.synchronize()
            }
            
            if isShipToSameAddressChecked {
                DataModel.sharedInstance.saveShippingAddress(fullName: cardName, street: addressStreet, city: addressCity, country: addressCountry, zipCode: addressZip, state: addressState, phone: phone)
                    .then { shippingAddress -> Void in
                        let shippingAddressURL = shippingAddress.objectID.uriRepresentation()
                        UserDefaults.standard.set(shippingAddressURL, forKey: Constants.checkoutPrimaryAddressURL)
                        UserDefaults.standard.synchronize()
                }
            }
            
            delegate?.checkoutFormViewControllerDidAdd(self)
        }
        
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
    }
    
    @objc fileprivate func updateCard() {
        guard let cardName = formRow(.cardName)?.value,
            let cardNumber = formRow(.cardNumber)?.value,
            let cardExp = formRow(.cardExp)?.value,
            let cardCVV = formRow(.cardCVV)?.value,
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
                return
        }
        
        let email = formRow(.email)?.value
        let brand = CreditCardValidator.shared.brand(forNumber: cardNumber)
        
        card.edit(fullName: cardName, number: cardNumber, displayNumber: secureNumber, brand: brand.rawValue, expirationMonth: Int16(cardExpDate.month), expirationYear: Int16(cardExpDate.year), street: addressStreet, city: addressCity, country: addressCountry, zipCode: addressZip, state: addressState, email: email, phone: phone)
        card.cvv = cardCVV
        
        delegate?.checkoutFormViewControllerDidEdit(self)
    }
    
    @objc fileprivate func removeCard() {
        guard let card = card else {
            return
        }
        
        if let primaryCardURL = UserDefaults.standard.url(forKey: Constants.checkoutPrimaryCardURL) {
            if primaryCardURL == card.objectID.uriRepresentation() {
                UserDefaults.standard.set(nil, forKey: Constants.checkoutPrimaryCardURL)
            }
        }
        
        card.delete()
        
        delegate?.checkoutFormViewControllerDidRemove(self)
    }
}
