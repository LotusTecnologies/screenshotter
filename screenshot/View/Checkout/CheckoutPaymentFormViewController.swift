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
    private var autoSaveBillAddressAsShippingAddress = false

    convenience init(withCard card: Card? = nil) {
        let isEditLayout = card != nil
        self.init(withCard: card, isEditLayout: isEditLayout, confirmBeforeSave: true, autoSaveBillAddressAsShippingAddress:false)
    }
    
    convenience init(withCard card: Card? = nil, isEditLayout:Bool, confirmBeforeSave:Bool, autoSaveBillAddressAsShippingAddress:Bool) {
        var cardRows: [FormRow] = []
        var billingRows: [FormRow] = []
        
        let cardName = FormRow.Text(CheckoutPaymentFormKeys.cardName.rawValue)
        cardName.title = "form.card.full_name".localized
        cardName.value = card?.fullName
        cardRows.append(cardName)
        
        let cardNumber = FormRow.Card(CheckoutPaymentFormKeys.cardNumber.rawValue)
        cardNumber.title = "form.card.number".localized
        cardNumber.placeholder = card?.displayNumber
        cardRows.append(cardNumber)
        
        let exp = FormRow.Expiration(CheckoutPaymentFormKeys.cardExp.rawValue)
        exp.title = "form.card.expiration".localized
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
            cvv.title = "form.card.cvv".localized
            cardRows.append(cvv)
        }
        
        let street = FormRow.Text(CheckoutPaymentFormKeys.addressStreet.rawValue)
        street.title = "form.address.street".localized
        street.value = card?.street
        billingRows.append(street)
        
        let city = FormRow.Text(CheckoutPaymentFormKeys.addressCity.rawValue)
        city.title = "form.address.city".localized
        city.value = card?.city
        billingRows.append(city)
        
        let supportedCountriesMap = CheckoutSupportedCountriesMap()
        
        let country = FormRow.Selection(CheckoutPaymentFormKeys.addressCountry.rawValue)
        country.title = "form.address.country".localized
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
        state.title = "form.address.state".localized
        state.value = {
            var value: String?
            
            if let stateCode = card?.state {
                value = supportedStatesMap.stateNames[stateCode]
            }
            
            return value
        }()
        state.options = supportedStatesMap.stateCodes.keys.sorted()
        billingRows.append(state)
        
        let zip = FormRow.Zip(CheckoutPaymentFormKeys.addressZip.rawValue)
        zip.title = "form.address.zip".localized
        zip.value = card?.zipCode
        billingRows.append(zip)
        
        let email = FormRow.Email(CheckoutPaymentFormKeys.email.rawValue)
        email.title = "form.personal.email".localized
        email.value = card?.email
        email.isRequired = false
        billingRows.append(email)
        
        let phone = FormRow.Phone(CheckoutPaymentFormKeys.phoneNumber.rawValue)
        phone.title = "form.personal.phone".localized
        phone.value = card?.phone
        billingRows.append(phone)
        
        if !isEditLayout {
            let ship = FormRow.Checkbox(CheckoutPaymentFormKeys.addressShip.rawValue)
            ship.title = "form.address.ship_to".localized
            billingRows.append(ship)
        }
        
        let cardSection = FormSection()
        cardSection.rows = cardRows
        
        let billingSection = FormSection()
        billingSection.title = "checkout.form.card.billing".localized
        billingSection.rows = billingRows
        
        self.init(with: Form(with: [cardSection, billingSection]))
        self.card = card
        self.supportedCountriesMap = supportedCountriesMap
        self.supportedStatesMap = supportedStatesMap
        
        title = isEditLayout ? "checkout.form.card.edit".localized : "checkout.form.card.add".localized
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
        self.autoSaveBillAddressAsShippingAddress = autoSaveBillAddressAsShippingAddress
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
                    DispatchQueue.main.async {
                        
                        DataModel.sharedInstance.selectedCardURL = card.objectID.uriRepresentation()
                        
                        self.delegate?.checkoutFormViewControllerDidAdd(self)
                    }
            }
            
            if isShipToSameAddressChecked || self.autoSaveBillAddressAsShippingAddress {
                let cart = DataModel.sharedInstance.retrieveAddableCart(managedObjectContext: DataModel.sharedInstance.mainMoc())
                if self.autoSaveBillAddressAsShippingAddress {
                    Analytics.trackCartShippingAdded(cart: cart, source: .onboarding)
                }else{
                    Analytics.trackCartShippingAdded(cart: cart, source: .sameAsBilling)
                }
                DataModel.sharedInstance.saveShippingAddress(fullName: cardName, street: addressStreet, city: addressCity, country: addressCountry, zipCode: addressZip, state: addressState, phone: phone)
                    .then { shippingAddress -> Void in
                        DataModel.sharedInstance.selectedShippingAddressURL = shippingAddress.objectID.uriRepresentation()
                }
            }
        }
        
        if self.confirmBeforeSave {
            let alertController = UIAlertController(title: "checkout.form.card.save.title".localized, message: "checkout.form.card.save.message".localized, preferredStyle: .alert)
            let saveAlertAction = UIAlertAction(title: "generic.save".localized, style: .default) { alertAction in
                performAction(withSavingCard: true)
            }
            alertController.addAction(saveAlertAction)
            alertController.addAction(UIAlertAction(title: "generic.dont_save".localized, style: .cancel, handler: { alertAction in
                performAction(withSavingCard: false)
            }))
            alertController.preferredAction = saveAlertAction
            present(alertController, animated: true, completion: nil)
        }
        else {
            performAction(withSavingCard: true)
        }
    }
    
    @objc fileprivate func updateCard() {
        tableView.endEditing(true)
        
        guard form.hasValidFields,
            let card = card,
            let cardName = formRow(.cardName)?.value,
            let cardNumber = formRow(.cardNumber)?.value ?? formRow(.cardNumber)?.placeholder,
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
        
        if !cardNumber.isEmpty && cardNumber != CreditCardValidator.shared.secureNumber(card.retrieveCardNumber()) {
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
