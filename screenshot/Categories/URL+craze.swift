//
//  URL+Craze.swift
//  screenshot
//
//  Created by Jonathan Rose on 3/26/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import Foundation

extension URL {
    static func urlWith(string:String, queryParameters:[String:String]) ->URL?{
        if var urlComponents = URLComponents.init(string: string){
            var queryItems:[URLQueryItem] = []
            if let q = urlComponents.queryItems {
                queryItems = q
            }
            //remove existing version of these parameters
            var items = queryItems.filter({ queryParameters[$0.name] == nil })
            
            //add the query parameters
            queryParameters.forEach({ (key, value) in
                items.append(URLQueryItem.init(name: key, value: value))
            })
            urlComponents.queryItems = items
            
            
            if let url = urlComponents.url {
                return url
            }
        }
        return nil
    }
}

enum HMACAlgorithm {
    case MD5, SHA1, SHA224, SHA256, SHA384, SHA512
    
    func toCCHmacAlgorithm() -> CCHmacAlgorithm {
        var result: Int = 0
        switch self {
        case .MD5:
            result = kCCHmacAlgMD5
        case .SHA1:
            result = kCCHmacAlgSHA1
        case .SHA224:
            result = kCCHmacAlgSHA224
        case .SHA256:
            result = kCCHmacAlgSHA256
        case .SHA384:
            result = kCCHmacAlgSHA384
        case .SHA512:
            result = kCCHmacAlgSHA512
        }
        return CCHmacAlgorithm(result)
    }
    
    func digestLength() -> Int {
        var result: CInt = 0
        switch self {
        case .MD5:
            result = CC_MD5_DIGEST_LENGTH
        case .SHA1:
            result = CC_SHA1_DIGEST_LENGTH
        case .SHA224:
            result = CC_SHA224_DIGEST_LENGTH
        case .SHA256:
            result = CC_SHA256_DIGEST_LENGTH
        case .SHA384:
            result = CC_SHA384_DIGEST_LENGTH
        case .SHA512:
            result = CC_SHA512_DIGEST_LENGTH
        }
        return Int(result)
    }
}
extension NSData {
    func base16EncodedString(uppercase uppercase: Bool = false) -> String {
        let buffer = UnsafeBufferPointer<UInt8>(start: UnsafePointer(self.bytes),
                                                count: self.length)
        let hexFormat = uppercase ? "X" : "x"
        let formatString = "%02\(hexFormat)"
        let bytesAsHexStrings = buffer.map {
            String(format: formatString, $0)
        }
        return bytesAsHexStrings.joinWithSeparator("")
    }
}
extension String {
    func hmac(algorithm: HMACAlgorithm, key: String) -> String {
        let cKey = key.cString(using: .utf8)
        let cData = self.cString(using: .utf8)
        var result = [CUnsignedChar](repeating: 0, count: Int(algorithm.digestLength()))
        CCHmac(algorithm.toCCHmacAlgorithm(), cKey!, strlen(cKey!), cData!, strlen(cData!), &result)
        let hmacData:NSData = NSData(bytes: result, length: (Int(algorithm.digestLength())))
//        let hmacBase64 = hmacData.base64EncodedString(options: NSData.Base64EncodingOptions.lineLength76Characters)
        return hmacData.base16EncodedString()
    }
}
