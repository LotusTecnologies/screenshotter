//
//  CustomInputtableView.swift
//  screenshot
//
//  Created by Corey Werner on 5/6/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit

class CustomInputtableView: UIView {
    var customInputView: UIView?
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override var inputView: UIView {
        return self.customInputView ?? UIView()
    }
}
