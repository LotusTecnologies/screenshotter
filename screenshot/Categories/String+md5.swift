//
//  string+md5.swift
//  Screenshop
//
//  Created by Jonathan Rose on 10/21/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation

extension String {
    func md5() -> Data {
        return String.MD5(string: self)
    }
    func md5String() -> String{
        return String.MD5(string: self).hexEncodedString()

    }
     static func MD5(string: String) -> Data {
        let messageData = string.data(using:.utf8)!
        var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        
        _ = digestData.withUnsafeMutableBytes {digestBytes in
            messageData.withUnsafeBytes {messageBytes in
                CC_MD5(messageBytes, CC_LONG(messageData.count), digestBytes)
            }
        }
        
        return digestData
    }
}
