//
//  Car+craze.swift
//  screenshot
//
//  Created by Jonathan Rose on 6/3/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import Foundation
import CoreData

extension Cart {
    var estimatedTax:Float {
        get{
            return 0.06 * ( self.subtotal + self.shippingTotal )
        }
    }
    var estimatedTotalOrder:Float {
        get{
            return self.subtotal + self.shippingTotal + self.estimatedTax
        }
    }
}
