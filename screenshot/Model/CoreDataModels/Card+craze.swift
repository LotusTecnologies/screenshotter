//
//  Card+craze.swift
//  screenshot
//
//  Created by Jonathan Rose on 6/3/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import Foundation
import CoreData
import SwiftKeychainWrapper


extension Card {
    
    func cardNumberKeychainKey() -> String {
        return objectID.uriRepresentation().absoluteString
    }
    
    func retrieveCardNumber() -> String? {
        return KeychainWrapper.standard.string(forKey: cardNumberKeychainKey())
    }
    
    func edit(fullName: String,
              number: String?,
              displayNumber: String?,
              brand: String?,
              expirationMonth: Int16,
              expirationYear: Int16,
              street: String,
              city: String,
              country: String,
              zipCode: String,
              state: String?,
              email: String?,
              phone: String) {
        let oid = objectID
        DataModel.sharedInstance.performBackgroundTask { (managedObjectContext) in
            guard let card = managedObjectContext.object(with: oid) as? Card else {
                print("Card.edit failed to retrieve object with oid:\(oid)")
                return
            }
            card.fullName = fullName
            if let displayNumber = displayNumber {
                card.displayNumber = displayNumber
            }
            if let brand = brand {
                card.brand = brand
            }
            card.expirationMonth = expirationMonth
            card.expirationYear = expirationYear
            card.street = street
            card.city = city
            card.country = country
            card.zipCode = zipCode
            card.state = state
            card.email = email
            card.phone = phone
            card.dateModified = Date()
            do {
                try managedObjectContext.save()
                if let number = number {
                    let key = self.cardNumberKeychainKey()
                    DispatchQueue.global(qos: .utility).async {
                        KeychainWrapper.standard.set(number, forKey: key)
                    }
                }
            } catch {
                DataModel.sharedInstance.receivedCoreDataError(error: error)
            }
        }
    }
    
    func delete() {
        let oid = objectID
        DataModel.sharedInstance.performBackgroundTask { (managedObjectContext) in
            guard let card = managedObjectContext.object(with: oid) as? Card else {
                print("Card.delete failed to retrieve object with oid:\(oid)")
                return
            }
            let key = self.cardNumberKeychainKey()
            managedObjectContext.delete(card)
            do {
                try managedObjectContext.save()
                DispatchQueue.global(qos: .utility).async {
                    KeychainWrapper.standard.removeObject(forKey: key)
                }
            } catch {
                DataModel.sharedInstance.receivedCoreDataError(error: error)
            }
        }
    }
    
}
