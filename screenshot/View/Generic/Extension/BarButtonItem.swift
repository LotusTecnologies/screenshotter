//
//  BarButtonItem.swift
//  screenshot
//
//  Created by Corey Werner on 11/1/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

extension UIBarButtonItem {
    var targetView: UIView? {
        guard let view = value(forKey: "view") as? UIView else {
            return nil
        }
        return view
    }
}
