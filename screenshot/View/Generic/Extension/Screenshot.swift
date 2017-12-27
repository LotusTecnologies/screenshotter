//
//  Screenshot.swift
//  screenshot
//
//  Created by Corey Werner on 12/27/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

extension Screenshot {
    class var ratio: CGSize {
        let width = CGFloat(9)
        let height = CGFloat(16)
        return CGSize(width: width / height, height: height / width)
    }
}
