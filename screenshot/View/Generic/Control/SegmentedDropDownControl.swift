//
//  SegmentedDropDownControl.swift
//  screenshot
//
//  Created by Corey Werner on 1/29/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class SegmentedDropDownItem : NSObject {
    var pickerItems: [String] {
        didSet {
            segment?.isEnabled = !pickerItems.isEmpty
        }
    }
    private(set) var selectedPickerItem: String?
    var disabledPickerItems: [String]? {
        didSet {
            guard let items = disabledPickerItems, let selectedTitle = selectedPickerItem else {
                return
            }
            
            if items.contains(selectedTitle) {
                title = placeholderTitle
            }
        }
    }
    var placeholderTitle: String?
    
    /// Value from 1 to 0 where 1 takes up the whole segmented control
    /// width. -1 uses auto calculate.
    var widthRatio: CGFloat = -1
    
    fileprivate var segment: DropDownControl?
    fileprivate var frameLayer: CAShapeLayer?
    
    init(pickerItems: [String], selectedPickerItem: String? = nil) {
        self.pickerItems = pickerItems
        super.init()
        
        if let selectedPickerItem = selectedPickerItem, pickerItems.contains(selectedPickerItem) {
            self.selectedPickerItem = selectedPickerItem
        }
    }
    
    fileprivate func setBorderColor(_ color: UIColor) {
        if let frameLayer = frameLayer {
            frameLayer.strokeColor = color.cgColor
        }
        else {
            segment?.layer.borderColor = color.cgColor
        }
    }
    
    func setBorderErrorColor() {
        setBorderColor(SegmentedDropDownControl.borderErrorColor)
        bringToFront()
    }
    
    func resetBorderColor() {
        setBorderColor(SegmentedDropDownControl.borderColor)
        sendToBack()
    }
    
    fileprivate func bringToFront() {
        guard let segment = segment else {
            return
        }
        
        segment.superview?.bringSubview(toFront: segment)
    }
    
    fileprivate func sendToBack() {
        guard let segment = segment else {
            return
        }
        
        segment.superview?.sendSubview(toBack: segment)
    }
    
    fileprivate var title: String? {
        set(newTitle) {
            segment?.titleLabel.text = newTitle
            selectedPickerItem = (newTitle == placeholderTitle) ? nil : newTitle
        }
        get {
            if let selectedPickerItem = selectedPickerItem, pickerItems.contains(selectedPickerItem) {
                return selectedPickerItem
            }
            else {
                return placeholderTitle
            }
        }
    }
}

class SegmentedDropDownControl : UIControl {
    fileprivate let borderWidth: CGFloat = 1
    static fileprivate let borderColor: UIColor = .gray8
    static fileprivate let borderErrorColor: UIColor = .crazeRed
    
    // MARK: Life Cycle
    
    var items: [SegmentedDropDownItem] = [] {
        willSet {
            items.forEach { item in
                item.segment?.removeFromSuperview()
            }
        }
        didSet {
            items.enumerated().forEach { (index, item) in
                let isFirst = index == 0
                let isLast = index == items.count - 1
                
                let segment = DropDownControl()
                segment.translatesAutoresizingMaskIntoConstraints = false
                segment.pickerDataSource = self
                segment.pickerDelegate = self
                segment.titleLabel.text = item.title
                segment.titleLabel.textColor = .gray6
                segment.isEnabled = !item.pickerItems.isEmpty
                segment.addTarget(self, action: #selector(touchUpInside(_:)), for: .touchUpInside)
                addSubview(segment)
                segment.topAnchor.constraint(equalTo: topAnchor).isActive = true
                segment.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
                
                if isFirst {
                    segment.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
                }
                else {
                    if let previousSegment = items[index - 1].segment {
                        segment.leadingAnchor.constraint(equalTo: previousSegment.trailingAnchor, constant: -borderWidth).isActive = true
                    }
                }
                
                if isLast {
                    segment.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -borderWidth).isActive = true
                }
                
                if item.widthRatio > -1 {
                    segment.widthAnchor.constraint(equalTo: widthAnchor, multiplier: item.widthRatio).isActive = true
                }
                
                if items.count == 1 {
                    segment.layer.borderColor = type(of: self).borderColor.cgColor
                    segment.layer.borderWidth = borderWidth
                    segment.layer.masksToBounds = true
                    segment.layer.cornerRadius = .defaultCornerRadius
                    
                } else {
                    // iOS 10 masking happens in the layoutSubviews
                    if #available(iOS 11.0, *) {
                        segment.layer.borderColor = type(of: self).borderColor.cgColor
                        segment.layer.borderWidth = borderWidth
                        
                        if isFirst || isLast {
                            segment.layer.masksToBounds = true
                            segment.layer.cornerRadius = .defaultCornerRadius
                        }
                        
                        if isFirst {
                            segment.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
                        }
                        else if isLast {
                            segment.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
                        }
                    }
                }
                
                item.segment = segment
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if #available(iOS 11.0, *) {} else if items.count > 1 {
            items.enumerated().forEach { (index, item) in
                guard let segment = item.segment else {
                    return
                }
                
                let isFirst = index == 0
                let isLast = index == items.count - 1
                let maskPath: CGPath
                
                if isFirst || isLast {
                    let corners: UIRectCorner = isFirst ? [.topLeft, .bottomLeft] : [.topRight, .bottomRight]
                    let radii = CGSize(width: .defaultCornerRadius, height: .defaultCornerRadius)
                    
                    maskPath = UIBezierPath(roundedRect: segment.bounds, byRoundingCorners: corners, cornerRadii: radii).cgPath
                }
                else {
                    maskPath = UIBezierPath(rect: segment.bounds).cgPath
                }
                
                let maskLayer = CAShapeLayer()
                maskLayer.path = maskPath
                segment.layer.mask = maskLayer
                
                item.frameLayer?.removeFromSuperlayer()
                
                let frameLayer = CAShapeLayer()
                frameLayer.path = maskPath
                frameLayer.strokeColor = item.frameLayer?.strokeColor ?? type(of: self).borderColor.cgColor
                frameLayer.lineWidth = borderWidth * 2 // 2x since the clipping cuts half
                frameLayer.fillColor = nil
                segment.layer.addSublayer(frameLayer)
                item.frameLayer = frameLayer
            }
        }
    }
    
    // MARK: Interaction
    
    @objc fileprivate func touchUpInside(_ control: DropDownControl) {
        guard let item = items.first(where: { $0.segment == control }), !item.pickerItems.isEmpty else {
            return
        }
        
        if control.isFirstResponder {
            _ = control.resignFirstResponder()
        }
        else {
            _ = control.becomeFirstResponder()
        }
        
        sendActions(for: .touchUpInside)
    }
    
    var highlightedItem: SegmentedDropDownItem? {
        return items.first { item -> Bool in
            return item.segment?.isHighlighted ?? false
        }
    }
    
    var selectedItem: SegmentedDropDownItem? {
        return items.first { item -> Bool in
            return item.segment?.isSelected ?? false
        }
    }
    
    // MARK: First Responder
    
    override var isFirstResponder: Bool {
        var isFirstResponder = false
        
        for item in items {
            if item.segment?.isFirstResponder ?? false {
                isFirstResponder = true
                break
            }
        }
        
        return isFirstResponder
    }
    
    override func resignFirstResponder() -> Bool {
        items.forEach { item in
            _ = item.segment?.resignFirstResponder()
        }
        
        return super.resignFirstResponder()
    }
}

extension SegmentedDropDownControl : UIPickerViewDataSource, UIPickerViewDelegate {
    private func itemIndex(pickerView: UIPickerView) -> Int {
        return items.index { item -> Bool in
            guard let segment = item.segment else {
                return false
            }
            
            return segment.inputView == pickerView
        } ?? 0
    }
    
    private func isItemDisabled(_ item: SegmentedDropDownItem, withTitle title: String) -> Bool {
        if let disabledPickerItems = item.disabledPickerItems, disabledPickerItems.contains(title) {
            return true
        }
        else {
            return false
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return items[itemIndex(pickerView: pickerView)].pickerItems.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return items[itemIndex(pickerView: pickerView)].pickerItems[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let item = items[itemIndex(pickerView: pickerView)]
        let title = item.pickerItems[row]
        var attributes: [String : Any]?
        
        if isItemDisabled(item, withTitle: title) {
            let color: UIColor = .gray5
            
            attributes = [
                NSForegroundColorAttributeName: color,
                NSStrikethroughColorAttributeName: color,
                NSStrikethroughStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue
            ]
        }
        
        return NSAttributedString(string: title, attributes: attributes)
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let item = items[itemIndex(pickerView: pickerView)]
        let title = item.pickerItems[row]
        
        guard !isItemDisabled(item, withTitle: title) else {
            return
        }
        
        item.title = title
        
        sendActions(for: .valueChanged)
        _ = item.segment?.resignFirstResponder()
    }
}

fileprivate class DropDownControl : UIControl {
    weak var pickerDataSource: UIPickerViewDataSource? {
        didSet {
            pickerView.dataSource = pickerDataSource
        }
    }
    weak var pickerDelegate: UIPickerViewDelegate? {
        didSet {
            pickerView.delegate = pickerDelegate
        }
    }
    
    let titleLabel = UILabel()
    fileprivate let imageView = UIImageView()
    fileprivate let image = UIImage(named: "DropDownArrow")
    fileprivate let pickerView = UIPickerView()
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = image
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
    
    // MARK: States
    
    override var isSelected: Bool {
        didSet {
            backgroundColor = isSelected ? .gray9 : nil
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            let alpha: CGFloat = isEnabled ? 1 : 0.5
            titleLabel.alpha = alpha
            imageView.alpha = alpha
        }
    }
    
    // MARK: Picker
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override var inputView: UIView? {
        get {
            return pickerView
        }
    }
    
    fileprivate func selectCurrentRow() {
        guard let dataSource = pickerView.dataSource, let delegate = pickerView.delegate else {
            return
        }
        
        var row = 0
        
        for i in 0 ..< dataSource.pickerView(pickerView, numberOfRowsInComponent: 0) {
            let title = delegate.pickerView!(pickerView, titleForRow: i, forComponent: 0) ?? ""
            
            if !title.isEmpty && title == titleLabel.text {
                row = i
                break
            }
        }
        
        pickerView.selectRow(row, inComponent: 0, animated: false)
    }
    
    // MARK: First Responder
    
    override func becomeFirstResponder() -> Bool {
        let becomeFirstResponder = super.becomeFirstResponder()
        
        if becomeFirstResponder {
            isSelected = true
            selectCurrentRow()
        }
        
        return becomeFirstResponder
    }
    
    override func resignFirstResponder() -> Bool {
        let resignFirstResponder = super.resignFirstResponder()
        
        if resignFirstResponder {
            isSelected = false
        }
        
        return resignFirstResponder
    }
}
