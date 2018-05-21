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
            syncUnderlineColor()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        NotificationCenter.default.addObserver(self, selector: #selector(syncUnderlineColor), name: .UITextFieldTextDidBeginEditing, object: self)
        NotificationCenter.default.addObserver(self, selector: #selector(syncUnderlineColor), name: .UITextFieldTextDidEndEditing, object: self)
        NotificationCenter.default.addObserver(self, selector: #selector(textDidChange), name: .UITextFieldTextDidChange, object: self)
        
        syncUnderlineColor()
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
    
    @objc fileprivate func syncUnderlineColor() {
        if isInvalid {
            underlineView.backgroundColor = .crazeRed
        }
        else if isEditing {
            underlineView.backgroundColor = .crazeGreen
        }
        else {
            underlineView.backgroundColor = .gray8
        }
    }
    
    @objc fileprivate func textDidChange() {
        isInvalid = false
    }
}
