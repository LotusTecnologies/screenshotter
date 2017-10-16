//
//  NetworkingIndicatorProtocol.swift
//  screenshot
//
//  Created by Corey Werner on 10/16/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

@objc enum NetworkingIndicatorType: Int {
    case Screenshot
    case Product
}

@objc protocol NetworkingIndicatorProtocol: NSObjectProtocol {
    @objc func networkingIndicatorDidStart(type: NetworkingIndicatorType)
    @objc func networkingIndicatorDidComplete(type: NetworkingIndicatorType)
}
