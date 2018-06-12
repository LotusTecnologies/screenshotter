//
//  CredentialHelper.swift
//  screenshot
//
//  Created by Corey Werner on 9/26/17.
//  Copyright (c) 2017 crazeapp. All rights reserved.
//

import Foundation

extension String {
    var isValidEmail: Bool {
        // http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
        //        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        //        let stricterFilterRegex = "^[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}$"
        let laxRegex = "^.+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*$"
        return NSPredicate.init(format: "SELF MATCHES %@", argumentArray: [laxRegex]).evaluate(with: self)
    }
}
