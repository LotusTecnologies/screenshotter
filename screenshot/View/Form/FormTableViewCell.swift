//
//  FormTableViewCell.swift
//  screenshot
//
//  Created by Corey Werner on 3/26/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class FormTableViewCell: UITableViewCell {
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
    }
}

class FormCardTableViewCell: FormTableViewCell {
    
}

class FormDateTableViewCell: FormTableViewCell {
    
}

class FormEmailTableViewCell: FormTextTableViewCell {
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        textField.keyboardType = .emailAddress
    }
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

class FormSelectionTableViewCell: FormTableViewCell {
    
}

class FormSelectionPickerTableViewCell: FormTableViewCell {
    let pickerView = UIPickerView()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
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

class FormTextTableViewCell: FormTableViewCell {
    let textField = UITextField()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
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
