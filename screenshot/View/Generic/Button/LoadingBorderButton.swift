//
//  BorderButton.swift
//  screenshot
//
//  Created by Corey Werner on 3/8/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class LoadingBorderButton: UIButton {
    
    let loadingButtonController = LoadingButtonController()
    let borderButonController = BorderButonController()

    var isLoading = Bool() {
        didSet {
            self.loadingButtonController.isLoading = isLoading
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.loadingButtonController.setup(button: self)
        self.borderButonController.setup(button: self)

    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadingButtonController.setup(button: self)
        self.borderButonController.setup(button: self)

    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Force isHidden since UIKit can unset it
        imageView?.isHidden = isLoading
    }
    
    override func setTitleColor(_ color: UIColor?, for state: UIControlState) {
        super.setTitleColor(color, for: state)
        self.borderButonController.setTitleColor(color, for: state)
        self.loadingButtonController.syncActivityIndicatorColor()
    }
    
    override var isHighlighted: Bool {
        didSet {
            self.loadingButtonController.syncActivityIndicatorColor()
            self.borderButonController.syncBorderColor()

        }
    }
    
    override var isSelected: Bool {
        didSet {
            self.loadingButtonController.syncActivityIndicatorColor()
            self.borderButonController.syncBorderColor()
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            self.loadingButtonController.syncActivityIndicatorColor()
            self.borderButonController.syncBorderColor()
        }
    }
}
