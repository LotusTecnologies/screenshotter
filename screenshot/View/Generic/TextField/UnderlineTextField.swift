//
//  UnderlineTextField.swift
//  screenshot
//
//  Created by Corey Werner on 5/21/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class UnderlineTextField: UITextField {
    fileprivate let underlineView = BorderView(edge: .bottom, height: 1)
    
    var isInvalid: Bool = false {
        didSet {
            syncColors()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        NotificationCenter.default.addObserver(self, selector: #selector(syncColors), name: .UITextFieldTextDidBeginEditing, object: self)
        NotificationCenter.default.addObserver(self, selector: #selector(syncColors), name: .UITextFieldTextDidEndEditing, object: self)
        NotificationCenter.default.addObserver(self, selector: #selector(textDidChange), name: .UITextFieldTextDidChange, object: self)
        
        syncColors()
        addSubview(underlineView)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = 48
        return size
    }
    
    @objc fileprivate func syncColors() {
        let color: UIColor
        
        if isInvalid {
            color = .crazeRed
        }
        else if isEditing {
            color = .crazeGreen
        }
        else {
            color = .gray8
        }
        
        tintColor = color
        underlineView.backgroundColor = color
    }
    
    @objc fileprivate func textDidChange() {
        isInvalid = false
    }
}
