//
//  UIResponder.swift
//  screenshot
//
//  Created by Corey Werner on 4/15/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit

extension UIResponder {
    private weak static var _currentFirstResponder: UIResponder? = nil
    
    static var current: UIResponder? {
        _currentFirstResponder = nil
        UIApplication.shared.sendAction(#selector(findFirstResponder), to: nil, from: nil, for: nil)
        return _currentFirstResponder
    }
    
    @objc private func findFirstResponder() {
        UIResponder._currentFirstResponder = self
    }
}
