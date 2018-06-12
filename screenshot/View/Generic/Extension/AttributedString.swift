//
//  AttributedString.swift
//  screenshot
//
//  Created by Corey Werner on 1/22/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit

extension NSMutableAttributedString {
    /// SegmentedString is a localized string combination, all appending
    /// with an incremental index starting from 0. The attributes count
    /// represents the segmented string count.
    convenience init(segmentedString string: String, attributes: [[NSAttributedStringKey : Any]]) {
        guard attributes.count > 1 else {
            self.init(string: string, attributes: attributes.first)
            return
        }
        
        func nextString(_ index: Int) -> String {
            return "\(string).\(index)".localized
        }
        
        func nextAttributes(_ index: Int) -> [NSAttributedStringKey : Any] {
            return attributes[index]
        }
        
        self.init(string: nextString(0), attributes: nextAttributes(0))
        
        for index in 1 ..< attributes.count {
            append(NSAttributedString(string: nextString(index), attributes: nextAttributes(index)))
        }
    }
}
