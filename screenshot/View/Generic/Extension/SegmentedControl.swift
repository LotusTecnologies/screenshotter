//
//  SegmentedControl.swift
//  screenshot
//
//  Created by Corey Werner on 12/26/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

extension UISegmentedControl : NSCopying {
    public func copy(with zone: NSZone? = nil) -> Any {
        var items: [Any] = []
        
        for i in 0 ..< numberOfSegments {
            if let title = titleForSegment(at: i) {
                items.append(title)
                
            } else if let image = imageForSegment(at: i) {
                items.append(image)
            }
        }
        
        let copy = UISegmentedControl(items: items)
        
        // !!!: the response from the target does nothing since the object is not the same...
        
        allTargets.forEach { target in
            if let actions = actions(forTarget: target, forControlEvent: .valueChanged) {
                actions.forEach { action in
                    copy.addTarget(target, action: Selector(action), for: .valueChanged)
                }
            }
        }
        
        return copy
    }
}
