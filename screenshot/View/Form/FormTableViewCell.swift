//
//  FormTableViewCell.swift
//  screenshot
//
//  Created by Corey Werner on 3/26/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class FormCardTableViewCell: UITableViewCell {
    
}

class FormDateTableViewCell: UITableViewCell {
    
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

class FormSelectionTableViewCell: UITableViewCell {
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        
        let dropDownImageView = UIImageView(image: UIImage(named: "CheckoutDownArrow"))
        dropDownImageView.contentMode = .scaleAspectFit
        accessoryView = dropDownImageView
    }
    
    // MARK: First Responder
    
    var canResignFirstResponderOverride: Bool?
    
    override var canBecomeFirstResponder: Bool {
        return next is UITableView
    }
    
    override var canResignFirstResponder: Bool {
        if let override = canResignFirstResponderOverride {
            return override
        }
        else {
            return super.canResignFirstResponder
        }
    }
    
    override func becomeFirstResponder() -> Bool {
        if !isFirstResponder {
            toggleSelectionPickerVisibility()
        }
        
        return super.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        if isFirstResponder {
            toggleSelectionPickerVisibility()
        }
        
        return super.resignFirstResponder()
    }
    
    // MARK: Selection Picker
    
    private func toggleSelectionPickerVisibility() {
        if let tableView = next as? FormViewTableView, let indexPath = tableView.indexPath(for: self) {
            tableView.toggleSelectionPickerVisibility(for: indexPath)
        }
    }
}

class FormSelectionPickerTableViewCell: UITableViewCell {
    let pickerView = UIPickerView()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        
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

class FormTextTableViewCell: TextFieldTableViewCell {
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
    }
}
