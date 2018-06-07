//
//  String+craze.swift
//  screenshot
//
//  Created by Jonathan Rose on 6/7/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation

extension String
{
    func sha1() -> String
    {
        var selfAsSha1 = ""
        
        if let data = self.dataUsingEncoding(NSUTF8StringEncoding)
        {
            var digest = [UInt8](count: Int(CC_SHA1_DIGEST_LENGTH), repeatedValue: 0)
            CC_SHA1(data.bytes, CC_LONG(data.length), &digest)
            
            for index in 0..<CC_SHA1_DIGEST_LENGTH
            {
                selfAsSha1 += String(format: "%02x", digest[Int(index)])
            }
        }
        
        return selfAsSha1
    }
}
