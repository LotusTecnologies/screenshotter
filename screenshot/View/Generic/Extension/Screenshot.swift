//
//  Screenshot.swift
//  screenshot
//
//  Created by Corey Werner on 12/27/17.
//  Copyright (c) 2017 crazeapp. All rights reserved.
//

import UIKit

extension Screenshot {
    private class func createRatio(width: CGFloat, height: CGFloat) -> CGSize {
        return CGSize(width: width / height, height: height / width)
    }
    
    class var ratio: CGSize {
        return createRatio(width: 9, height: 16)
    }
    
    class var discoverRatio: CGSize {
        return createRatio(width: 15, height: 23)
    }
}
