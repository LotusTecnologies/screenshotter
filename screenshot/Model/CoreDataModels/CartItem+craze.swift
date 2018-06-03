//
//  CartItem+craze.swift
//  screenshot
//
//  Created by Jonathan Rose on 6/3/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import CoreData

extension CartItem {
    
    func productTitle() -> String? {
        return productDescription?.productTitle()
    }
    
}


