//
//  EnumProtocol.swift
//  screenshot
//
//  Created by Corey Werner on 11/22/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

protocol EnumIntDefaultProtocol {
    static var `default`: Self { get }
    
    init(intValue: Int)
}

protocol EnumIntOffsetProtocol {
    init(offsetValue: Int)
    
    var offsetValue: Int { get }
}
