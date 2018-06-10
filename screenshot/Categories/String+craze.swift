//
//  String+craze.swift
//  screenshot
//
//  Created by Jonathan Rose on 6/7/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
extension String {
    func sha1() -> String? {
        if let data = self.data(using: String.Encoding.utf8) {
        var digest = [UInt8](repeating: 0, count:Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA1($0, CC_LONG(data.count), &digest)
        }
        return Data(bytes: digest).base64EncodedString()
        }
        return nil
    }
}
