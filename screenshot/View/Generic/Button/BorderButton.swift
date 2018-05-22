//
//  BorderButton.swift
//  screenshot
//
//  Created by Corey Werner on 3/8/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class BorderButonController {
    weak var button:UIButton?
    func setup(button:UIButton) {
        self.button = button
        button.setTitleColor(.crazeRed, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: .padding / 1.8, left: .padding, bottom: .padding / 1.8, right: .padding)
        button.adjustsImageWhenHighlighted = false
        button.titleLabel?.font = UIFont(screenshopName: .hindMedium, size: UIFont.buttonFontSize)
        button.layer.borderWidth = 1
        button.layer.cornerRadius = .defaultCornerRadius
    }
    func syncBorderColor() {
        if let button = self.button, let cgColor = button.titleColor(for: button.state)?.cgColor {
            self.button?.layer.borderColor = cgColor
        }
    }
    func setTitleColor(_ color: UIColor?, for state: UIControlState) {
        self.syncBorderColor()

        if state == .normal {
            let darkerColor = color?.darker(by: 14)
            
            self.button?.setTitleColor(darkerColor, for: .highlighted)
            self.button?.setTitleColor(darkerColor, for: [.highlighted, .selected])
        }
    }

}

class BorderButton: UIButton {
    let borderButonController = BorderButonController()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.borderButonController.setup(button: self)
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.borderButonController.setup(button: self)
    }
    
    override func setTitleColor(_ color: UIColor?, for state: UIControlState) {
        super.setTitleColor(color, for: state)
       self.borderButonController.setTitleColor(color, for: state)
    }
    
    override var isHighlighted: Bool {
        didSet {
            self.borderButonController.syncBorderColor()
        }
    }
    
    override var isSelected: Bool {
        didSet {
            self.borderButonController.syncBorderColor()
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            self.borderButonController.syncBorderColor()
        }
    }
    
    
}
