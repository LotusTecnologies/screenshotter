//
//  NetworkingIndicatorProtocol.swift
//  screenshot
//
//  Created by Corey Werner on 10/16/17.
//  Copyright (c) 2017 crazeapp. All rights reserved.
//

import Foundation

enum NetworkingIndicatorType: Int {
    case Screenshot
    case Product
}

protocol NetworkingIndicatorProtocol: NSObjectProtocol {
    func networkingIndicatorDidStart(type: NetworkingIndicatorType)
    func networkingIndicatorDidComplete(type: NetworkingIndicatorType)
}
