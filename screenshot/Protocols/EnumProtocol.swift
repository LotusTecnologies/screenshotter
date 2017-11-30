//
//  EnumProtocol.swift
//  screenshot
//
//  Created by Corey Werner on 11/22/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

protocol EnumIntFallbackProtocol {
    static var fallback: Self { get }
    
    init(intValue: Int)
}
