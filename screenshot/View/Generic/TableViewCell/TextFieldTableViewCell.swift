//
//  TextFieldTableViewCell.swift
//  screenshot
//
//  Created by Corey Werner on 12/6/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit

class TextFieldTableViewCell : UITableViewCell {
    fileprivate let style: UITableViewCellStyle
    
    let textField: UITextField = TextField()
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        self.style = style
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        NotificationCenter.default.addObserver(self, selector: #selector(textFieldTextDidBeginEditing), name: .UITextFieldTextDidBeginEditing, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(textFieldTextDidEndEditing), name: .UITextFieldTextDidEndEditing, object: nil)
        
        textLabel?.font = .screenshopFont(.hindLight, textStyle: .body)
        
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.returnKeyType = .done
        textField.font = .screenshopFont(.hindLight, textStyle: .body)
        textField.adjustsFontForContentSizeCategory = true
        textField.tintColor = .crazeGreen
        textField.isUserInteractionEnabled = false // Activate through the cells becomeFirstResponder
        contentView.addSubview(textField)
        textField.setContentCompressionResistancePriority(1, for: .vertical)
        
        if style == .value1 {
            // Needed for positioning the constraints
            detailTextLabel?.textColor = .clear
            detailTextLabel?.text = " "
            
            applyTextFieldConstraints()
        }
        else {
            textField.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
            textField.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
            textField.centerYAnchor.constraint(equalTo: contentView.layoutMarginsGuide.centerYAnchor).isActive = true
            textField.heightAnchor.constraint(equalTo: contentView.heightAnchor).isActive = true
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Needed for adjusting the cell height correctly with dynamic type
        textLabel?.text = " "
        
        if style == .value1 {
            applyTextFieldConstraints()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Needed when going from dynamic type accessibility size to normal size
        contentView.bringSubview(toFront: textField)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if previousTraitCollection?.preferredContentSizeCategory == .unspecified && style == .value1 {
            applyTextFieldConstraints()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Text Field
    
    fileprivate func applyTextFieldConstraints() {
        // Because these constraints are attached to the cell's labels, they need to be reapplied every time the dynamic type changes.
        
        guard let textLabel = textLabel, let detailTextLabel = detailTextLabel else {
            return
        }
        
        textField.removeFromSuperview() // Removes the constraints
        contentView.addSubview(textField)
        
        textField.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        textField.centerYAnchor.constraint(equalTo: detailTextLabel.centerYAnchor).isActive = true
        
        if traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
            textField.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        }
        else {
            textField.leadingAnchor.constraint(greaterThanOrEqualTo: textLabel.trailingAnchor, constant: .padding).isActive = true
        }
    }
    
    @objc fileprivate func textFieldTextDidBeginEditing() {
        textField.isUserInteractionEnabled = true
    }
    
    @objc fileprivate func textFieldTextDidEndEditing() {
        textField.isUserInteractionEnabled = false
    }
    
    // MARK: First Responder
    
    override var canBecomeFirstResponder: Bool {
        return textField.canBecomeFirstResponder
    }
    
    override var canResignFirstResponder: Bool {
        return textField.canResignFirstResponder
    }
    
    @discardableResult override func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }
    
    @discardableResult override func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }
    
    override var isFirstResponder: Bool {
        return textField.isFirstResponder
    }
}

fileprivate extension TextFieldTableViewCell {
    class TextField: UITextField {
        override var canBecomeFirstResponder: Bool {
            return true
        }
    }
}
