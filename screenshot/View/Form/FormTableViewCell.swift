//
//  FormTableViewCell.swift
//  screenshot
//
//  Created by Corey Werner on 3/26/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import Appsee
import CreditCardValidator

class FormCardTableViewCell: FormNumberTableViewCell {
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        textFieldController = TextFieldFormatter(with: .card)
//        textField.isSecureTextEntry = true
        
        Appsee.markView(asSensitive: textField)
    }
}

class FormCheckboxTableViewCell: TableViewCell, FormErrorTableViewCellProtocol {
    private let checkboxImage = UIImage(named: "FormCheckbox")
    private let checkboxSelectedImage = UIImage(named: "FormCheckboxChecked")
    var hasInvalidValue = false {
        didSet {
            highlightError()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        
        clipsToBounds = true
        
        imageView?.image = checkboxImage
        
        textLabel?.font = .screenshopFont(.hindLight, textStyle: .body)
    }
    
    var isChecked = false {
        didSet {
            if isChecked {
                imageView?.image = checkboxSelectedImage
            }
            else {
                imageView?.image = checkboxImage
            }
        }
    }
}

class FormCVVTableViewCell: FormNumberTableViewCell {
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        textFieldController = TextFieldFormatter(with: .cvv)
    }
}

class FormEmailTableViewCell: FormTextTableViewCell {
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        textField.keyboardType = .emailAddress
        textField.autocapitalizationType = .none
    }
}

class FormExpirationTableViewCell: FormSelectionTableViewCell {
    
}

class FormExpirationPickerTableViewCell: FormSelectionPickerTableViewCell {
    enum DateComponent: Int {
        // Don't change order
        case month
        case year
    }
    
    private static let currentYear = CreditCardValidator.currentYear
    
    static let dateMap = [
        DateComponent.month: [Int](1...12),
        DateComponent.year: [Int](currentYear...(currentYear + 20))
    ]
}

class FormNumberTableViewCell: FormTextTableViewCell {
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        textField.keyboardType = .numberPad
    }
}

class FormPhoneTableViewCell: FormTextTableViewCell {
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        textField.keyboardType = .phonePad
    }
}

class FormSelectionTableViewCell: TableViewCell, FormErrorTableViewCellProtocol {
    var hasInvalidValue = false {
        didSet {
            highlightError()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        
        clipsToBounds = true
        
        textLabel?.font = .screenshopFont(.hindLight, textStyle: .body)
        
        let dropDownImageView = UIImageView(image: UIImage(named: "FormDownArrow"))
        dropDownImageView.contentMode = .scaleAspectFit
        dropDownImageView.sizeToFit()
        dropDownImageView.frame = {
            var rect = dropDownImageView.frame
            rect.origin.x = .padding
            return rect
        }()
        
        let imageViewContainer = UIView()
        imageViewContainer.frame = {
            var rect = dropDownImageView.bounds
            rect.size.width = dropDownImageView.frame.maxX
            return rect
        }()
        imageViewContainer.addSubview(dropDownImageView)
        accessoryView = imageViewContainer
    }
    
    // MARK: First Responder
    
    override var canBecomeFirstResponder: Bool {
        return next is UITableView
    }
    
    override func becomeFirstResponder() -> Bool {
        if !isFirstResponder {
            changePicker(visibility: true)
        }
        
        return super.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        if isFirstResponder {
            changePicker(visibility: false)
        }
        
        return super.resignFirstResponder()
    }
    
    // MARK: Picker
    
    private func changePicker(visibility: Bool) {
        if let tableView = next as? FormViewTableView, let indexPath = tableView.indexPath(for: self) {
            tableView.changePicker(visibility: visibility, forAttached: indexPath)
        }
    }
}

class FormSelectionPickerTableViewCell: TableViewCell, FormErrorTableViewCellProtocol {
    let pickerView = UIPickerView()
    var hasInvalidValue = false {
        didSet {
            highlightError()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        clipsToBounds = true
        
        let containerView = NotifyChangeView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.clipsToBounds = true
        containerView.notifySizeChange = sizeChanged
        contentView.addSubview(containerView)
        containerView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        pickerView.backgroundColor = .gray9
        containerView.addSubview(pickerView)
        pickerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        pickerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        pickerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
    }
    
    fileprivate func sizeChanged(_ size: CGSize) {
        guard floor(size.height) > 0,
            pickerView.dataSource != nil,
            pickerView.numberOfComponents > 0,
            pickerView.numberOfRows(inComponent: 0) == 0
            else {
                return
        }
        
        pickerView.reloadAllComponents()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        pickerView.dataSource = nil
        pickerView.delegate = nil
    }
}

class FormTextTableViewCell: TextFieldTableViewCell, UITextFieldDelegate, FormErrorTableViewCellProtocol {
    fileprivate var textFieldController: TextFieldFormatter?
    var hasInvalidValue = false {
        didSet {
            highlightError()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        
        clipsToBounds = true
        
        textField.delegate = self
        textField.autocapitalizationType = .words
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if range.location == 0 && string == " " {
            return false
        }
        else if range.location > 0 && string == " " && textField.text?.last == " " {
            return false
        }
        else if let textFieldController = textFieldController {
            return textFieldController.textField(textField, shouldChangeCharactersIn: range, replacementString: string)
        }
        else {
            return true
        }
    }
}

class FormZipTableViewCell: FormNumberTableViewCell {
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        textFieldController = TextFieldFormatter(with: .zip)
        textField.delegate = self
    }
}

protocol FormErrorTableViewCellProtocol {
    var hasInvalidValue: Bool { get set }
}

extension FormErrorTableViewCellProtocol where Self: UITableViewCell {
    func highlightError() {
        if hasInvalidValue {
            textLabel?.textColor = .crazeRed
        }
        else {
            textLabel?.textColor = .gray3
        }
    }
}

