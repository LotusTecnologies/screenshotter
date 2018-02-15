//
//  ProductsViewControllerControl.swift
//  screenshot
//
//  Created by Jonathan Rose on 2/13/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class ProductsViewControllerControl: UIControl {
    var customInputView:UIView?
    override var canBecomeFirstResponder: Bool { return true }
    override var inputView: UIView { return self.customInputView ?? UIView.init() }
    
}
