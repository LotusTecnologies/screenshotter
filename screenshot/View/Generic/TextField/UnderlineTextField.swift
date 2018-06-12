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
    
    fileprivate let errorLabel = UILabel()
    
    var errorText:String? = nil {
        didSet {
            errorLabel.text = errorText
            errorLabel.isHidden = (errorText == nil)
        }
    }
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
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(errorLabel)
        errorLabel.textColor = .red
        errorLabel.leadingAnchor.constraint(equalTo: underlineView.leadingAnchor).isActive = true
        errorLabel.trailingAnchor.constraint(equalTo: underlineView.trailingAnchor).isActive = true
        errorLabel.topAnchor.constraint(equalTo: underlineView.bottomAnchor).isActive = true
        errorLabel.isHidden = true
        errorLabel.font = UIFont.screenshopFont(.hind, size: 10)
        errorLabel.minimumScaleFactor = 0.5
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
        self.errorText = nil
    }
}
