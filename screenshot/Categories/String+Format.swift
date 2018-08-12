//
//  String+Format.swift
//  Screenshop
//
//  Created by Corey Werner on 8/12/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation

extension String {
    var nonEmptyValue: String? {
        return isEmpty ? nil : self
    }
}
