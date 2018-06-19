//
//  MainButton.swift
//  screenshot
//
//  Created by Corey Werner on 9/4/17.
//  Copyright (c) 2017 crazeapp. All rights reserved.
//

import UIKit

class MainButton: LoadingButton {
    private var backgroundColorStates: [UInt : UIColor] = [:]
    private var isSettingBackgroundColor = false
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .crazeRed
        contentEdgeInsets = UIEdgeInsets(top: 0, left: .padding, bottom: 0, right: .padding)
        adjustsImageWhenHighlighted = false
        titleLabel?.font = UIFont(screenshopName: .hindMedium, size: UIFont.buttonFontSize)
        layer.cornerRadius = 9
        layer.shadowColor = Shadow.basic.color.cgColor
        layer.shadowOffset = Shadow.basic.offset
        layer.shadowRadius = Shadow.basic.radius
        layer.shadowOpacity = 1
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
    }
    
    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.width = max(size.width, 160)
        size.height = 50
        return size
    }
    
    // MARK: States
    
    override var isHighlighted: Bool {
        didSet {
            setBackgroundColor(to: isHighlighted ? .highlighted : state)
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            setBackgroundColor(to: isEnabled ? state : .disabled)
        }
    }
    
    // MARK: Background Color
    
    override var backgroundColor: UIColor? {
        didSet {
            if !isSettingBackgroundColor {
                backgroundColorStates[UIControlState.normal.rawValue] = backgroundColor
                backgroundColorStates[UIControlState.highlighted.rawValue] = backgroundColor?.darker()
                backgroundColorStates[UIControlState.disabled.rawValue] = backgroundColor?.lighter()
            }
        }
    }
    
    fileprivate func setBackgroundColor(to state: UIControlState) {
        isSettingBackgroundColor = true
        backgroundColor = backgroundColorStates[state.rawValue] ?? backgroundColor
        isSettingBackgroundColor = false
    }
    
    // MARK: Image
    
    override func setImage(_ image: UIImage?, for state: UIControlState) {
        super.setImage(image, for: state)
        adjustInsetsForImage(withPadding: 6)
    }
}
