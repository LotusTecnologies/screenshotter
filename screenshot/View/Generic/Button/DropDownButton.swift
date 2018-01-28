//
//  DropDownButton.swift
//  screenshot
//
//  Created by Corey Werner on 1/28/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation

class DropDownButton : UIControl {
    let titleLabel = UILabel()
    
    fileprivate let image = UIImage(named: "DropDownArrow")
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
        imageView.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        imageView.topAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.topAnchor).isActive = true
        imageView.bottomAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.bottomAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: layoutMarginsGuide.centerYAnchor).isActive = true
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: UIFont.buttonFontSize)
        addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: imageView.leadingAnchor, constant: -_layoutMargins.right).isActive = true
    }
    
    private let _layoutMargins = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding / 2)
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Needed here for iOS 10
        layoutMargins = _layoutMargins
    }
    
    override var intrinsicContentSize: CGSize {
        var size: CGSize = .zero
        let labelSize = titleLabel.systemLayoutSizeFitting(super.intrinsicContentSize)
        let imageWidth = image?.size.width ?? 0
        
        size.width = layoutMargins.left + ceil(labelSize.width) + layoutMargins.right + imageWidth + layoutMargins.right
        size.height = layoutMargins.top + ceil(labelSize.height) + layoutMargins.bottom
        return size
    }
    
    // MARK: Picker
    
    var pickerItems: [String] = [] {
        didSet {
            titleLabel.text = pickerItems.first
        }
    }
    
    fileprivate lazy var pickerView: UIPickerView = {
        let view = UIPickerView()
        view.delegate = self
        view.dataSource = self
        return view
    }()
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override var inputView: UIView? {
        get {
            return pickerView
        }
    }
}

extension DropDownButton : UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerItems.count
    }
}

extension DropDownButton : UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerItems[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        titleLabel.text = pickerItems[row]
        resignFirstResponder()
    }
}
