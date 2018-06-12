//
//  Variant+craze.swift
//  screenshot
//
//  Created by Jonathan Rose on 6/3/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import Foundation
import CoreData


extension Variant {
    
    func parsedImageURLs() -> [URL] {
        return imageURLs?.components(separatedBy: ",").compactMap { URL(string: $0) } ?? []
    }
    
}

