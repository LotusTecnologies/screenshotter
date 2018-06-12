//
//  ShippingAddress+craze.swift
//  screenshot
//
//  Created by Jonathan Rose on 6/3/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import Foundation
import CoreData


extension ShippingAddress {
    
    func edit(firstName: String?,
              lastName: String?,
              street: String,
              city: String,
              country: String,
              zipCode: String,
              state: String?,
              phone: String) {
        let oid = objectID
        DataModel.sharedInstance.performBackgroundTask { (managedObjectContext) in
            guard let shippingAddress = managedObjectContext.object(with: oid) as? ShippingAddress else {
                print("ShippingAddress.edit failed to retrieve object with oid:\(oid)")
                return
            }
            shippingAddress.firstName = firstName
            shippingAddress.lastName = lastName
            shippingAddress.street = street
            shippingAddress.city = city
            shippingAddress.country = country
            shippingAddress.zipCode = zipCode
            shippingAddress.state = state
            shippingAddress.phone = phone
            shippingAddress.dateModified = Date()
            do {
                try managedObjectContext.save()
            } catch {
                DataModel.sharedInstance.receivedCoreDataError(error: error)
            }
        }
    }
    
    func delete() {
        let oid = objectID
        DataModel.sharedInstance.performBackgroundTask { (managedObjectContext) in
            guard let shippingAddress = managedObjectContext.object(with: oid) as? ShippingAddress else {
                print("ShippingAddress.delete failed to retrieve object with oid:\(oid)")
                return
            }
            managedObjectContext.delete(shippingAddress)
            do {
                try managedObjectContext.save()
            } catch {
                DataModel.sharedInstance.receivedCoreDataError(error: error)
            }
        }
    }
    
    var fullName: String? {
        if let names = [firstName, lastName].filter({ $0?.isEmpty == false }) as? [String] {
            return names.joined(separator: " ")
        }
        return nil
    }
    
    var readableAddress: String? {
        guard let street = street, let city = city, let state = state, let zip = zipCode, let country = country else {
            return nil
        }
        
        return """
        \(street)
        \(city), \(state) \(zip)
        \(country)
        """
    }
    
}

