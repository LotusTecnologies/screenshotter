//
//  Data+craze.swift
//  Screenshop
//
//  Created by Jonathan Rose on 10/21/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation

//Source: https://stackoverflow.com/a/47476781/1143046
extension Data {
    private static let hexAlphabet = "0123456789abcdef".unicodeScalars.map { $0 }
    
    public func hexEncodedString() -> String {
        return String(self.reduce(into: "".unicodeScalars, { (result, value) in
            result.append(Data.hexAlphabet[Int(value/16)])
            result.append(Data.hexAlphabet[Int(value%16)])
        }))
    }
}
