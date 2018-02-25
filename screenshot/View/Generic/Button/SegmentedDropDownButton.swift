//
//  SegmentedDropDownButton.swift
//  screenshot
//
//  Created by Corey Werner on 1/29/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class SegmentedDropDownItem : NSObject {
    var pickerItems: [String]
    var placeholderTitle: String?
    fileprivate(set) var title: String?
    
    /// Value from 1 to 0 where 1 takes up the whole segmented button
    /// width. -1 uses auto calculate.
    var widthRatio: CGFloat = -1
    
    fileprivate var segment: DropDownButton!
    fileprivate var frameLayer: CAShapeLayer?
    
    init(pickerItems: [String]) {
        self.pickerItems = pickerItems
        super.init()
    }
    
    fileprivate func setBorderColor(_ color: UIColor) {
        if let frameLayer = frameLayer {
            frameLayer.strokeColor = color.cgColor
        }
        else {
            segment.layer.borderColor = color.cgColor
        }
    }
    
    func setBorderErrorColor() {
        setBorderColor(SegmentedDropDownButton.borderErrorColor)
        bringToFront()
    }
    
    func resetBorderColor() {
        setBorderColor(SegmentedDropDownButton.borderColor)
        sendToBack()
    }
    
    fileprivate func bringToFront() {
        segment.superview?.bringSubview(toFront: segment)
    }
    
    fileprivate func sendToBack() {
        segment.superview?.sendSubview(toBack: segment)
    }
}

class SegmentedDropDownButton : UIControl {
    private(set) var items: [SegmentedDropDownItem]!
    
    fileprivate let borderWidth: CGFloat = 1
    static fileprivate let borderColor: UIColor = .gray8
    static fileprivate let borderErrorColor: UIColor = .crazeRed
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(items: [SegmentedDropDownItem]) {
        self.items = items
        
        super.init(frame: .zero)
        
        items.enumerated().forEach { (index, item) in
            let isFirst = index == 0
            let isLast = index == items.count - 1
            
            let segment = DropDownButton()
            segment.translatesAutoresizingMaskIntoConstraints = false
            segment.pickerDataSource = self
            segment.pickerDelegate = self
            segment.titleLabel.text = item.placeholderTitle ?? item.pickerItems.first
            segment.titleLabel.textColor = .gray6
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
            
            item.title = segment.titleLabel.text
            item.segment = segment
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
    
    @objc fileprivate func touchUpInside(_ button: DropDownButton) {
        if button.isFirstResponder {
            _ = button.resignFirstResponder()
        }
        else {
            _ = button.becomeFirstResponder()
        }
        
        sendActions(for: .touchUpInside)
    }
    
    var highlightedItem: SegmentedDropDownItem? {
        return items.first { item -> Bool in
            return item.segment.isHighlighted
        }
    }
    
    var selectedItem: SegmentedDropDownItem? {
        return items.first { item -> Bool in
            return item.segment.isSelected
        }
    }
}

extension SegmentedDropDownButton : UIPickerViewDataSource, UIPickerViewDelegate {
    private func itemIndex(pickerView: UIPickerView) -> Int {
        return items.index { item -> Bool in
            return item.segment.isPickerViewInitialized && item.segment.inputView == pickerView
        }!
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
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let item = items[itemIndex(pickerView: pickerView)]
        item.title = item.pickerItems[row]
        item.segment.titleLabel.text = item.title
        
        sendActions(for: .valueChanged)
        _ = item.segment.resignFirstResponder()
    }
}

fileprivate class DropDownButton : UIControl {
    weak var pickerDataSource: UIPickerViewDataSource?
    weak var pickerDelegate: UIPickerViewDelegate?
    
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
    
    override var isSelected: Bool {
        didSet {
            backgroundColor = isSelected ? .gray9 : nil
        }
    }
    
    // MARK: Picker
    
    private(set) var isPickerViewInitialized = false
    
    fileprivate lazy var pickerView: UIPickerView = {
        self.isPickerViewInitialized = true
        
        let view = UIPickerView()
        view.dataSource = self.pickerDataSource
        view.delegate = self.pickerDelegate
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
    
    // MARK: First Responder
    
    override func becomeFirstResponder() -> Bool {
        let becomeFirstResponder = super.becomeFirstResponder()
        
        if becomeFirstResponder {
            isSelected = true
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
