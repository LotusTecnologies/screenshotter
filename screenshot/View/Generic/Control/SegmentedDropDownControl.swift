//
//  SegmentedDropDownControl.swift
//  screenshot
//
//  Created by Corey Werner on 1/29/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit

class SegmentedDropDownItem : NSObject {
    var pickerItems: [String] {
        didSet {
            if let segment = segment as? DropDownControl {
                segment.isEnabled = !pickerItems.isEmpty
            }
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
    var isPickerViewInsertedInline = false
    var pickerViewAnimation: (()->())?
    var pickerView: UIPickerView? {
        if let segment = segment as? DropDownControl {
            return segment.pickerView
        }
        return nil
    }
    var placeholderTitle: String?
    
    /// If the titleLabel.text is empty, this value will be used to select the current picker row.
    var placeholderRow: String?
    
    /// Value from 1 to 0 where 1 takes up the whole segmented control
    /// width. -1 uses auto calculate.
    var widthRatio: CGFloat = -1
    
    fileprivate var segment: UIView?
    fileprivate var frameLayer: CAShapeLayer?
    
    fileprivate var titleItemText: String?
    
    init(pickerItems: [String], selectedPickerItem: String? = nil) {
        self.pickerItems = pickerItems
        super.init()
        
        if let selectedPickerItem = selectedPickerItem, pickerItems.contains(selectedPickerItem) {
            self.selectedPickerItem = selectedPickerItem
        }
    }
    
    convenience init(titleItem: String) {
        self.init(pickerItems: [], selectedPickerItem: nil)
        titleItemText = titleItem
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
    
    var title: String? {
        set(newTitle) {
            if let segment = segment as? DropDownControl {
                segment.titleLabel.text = newTitle
            }
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

class SegmentedDropDownControl : UIButton {
    fileprivate let borderWidth: CGFloat = 1
    static fileprivate let borderColor: UIColor = .gray8
    static fileprivate let borderErrorColor: UIColor = .crazeRed
    var changeValueOnRowChange = false

    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addTarget(self, action: #selector(touchUpInside(_:event:)), for: .touchUpInside)
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
    
    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = .defaultViewHeight
        return size
    }
    
    // MARK: Segments
    
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
                let segment: UIView
                
                if let titleItemText = item.titleItemText {
                    let label = DropDownLabel()
                    label.text = titleItemText
                    segment = label
                }
                else {
                    let dropDownControl = DropDownControl()
                    dropDownControl.pickerDataSource = self
                    dropDownControl.pickerDelegate = self
                    dropDownControl.placeholderRow = item.placeholderRow
                    dropDownControl.titleLabel.text = item.title
                    dropDownControl.titleLabel.textColor = .gray3
                    dropDownControl.imageView.tintColor = dropDownControl.titleLabel.textColor
                    dropDownControl.isEnabled = !item.pickerItems.isEmpty
                    dropDownControl.isPickerViewInsertedInline = item.isPickerViewInsertedInline
                    
                    if !item.isPickerViewInsertedInline {
                        dropDownControl.pickerInputView.doneButton.addTarget(self, action: #selector(pickerDoneButtonAction(_:)), for: .touchUpInside)
                    }
                    
                    segment = dropDownControl
                }
                
                segment.translatesAutoresizingMaskIntoConstraints = false
                segment.isUserInteractionEnabled = false
                addSubview(segment)
                segment.topAnchor.constraint(equalTo: topAnchor).isActive = true
                segment.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor).isActive = true
                segment.heightAnchor.constraint(equalToConstant: .defaultViewHeight).isActive = true
                
                if isFirst {
                    segment.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
                }
                else {
                    if let previousSegment = items[index - 1].segment {
                        segment.leadingAnchor.constraint(equalTo: previousSegment.trailingAnchor, constant: -borderWidth).isActive = true
                    }
                }
                
                if isLast {
                    segment.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
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
                
                insertSegmentPickerViewIfNeeded(item: item)
            }
        }
    }
    
    private func insertSegmentPickerViewIfNeeded(item: SegmentedDropDownItem) {
        if item.isPickerViewInsertedInline, let dropDownControl = item.segment as? DropDownControl {
            let expandedHeight: CGFloat = 130
            
            let pickerViewContainer = UIView()
            pickerViewContainer.translatesAutoresizingMaskIntoConstraints = false
            pickerViewContainer.backgroundColor = .white
            pickerViewContainer.layer.masksToBounds = true
            pickerViewContainer.layer.cornerRadius = .defaultCornerRadius
            pickerViewContainer.layer.borderColor = type(of: self).borderColor.cgColor
            pickerViewContainer.layer.borderWidth = borderWidth
            insertSubview(pickerViewContainer, at: 0)
            pickerViewContainer.topAnchor.constraint(equalTo: dropDownControl.bottomAnchor, constant: -.defaultCornerRadius * 2).isActive = true
            pickerViewContainer.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            pickerViewContainer.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            pickerViewContainer.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            let pickerViewContainerHeightConstraint = pickerViewContainer.heightAnchor.constraint(equalToConstant: 0)
            pickerViewContainerHeightConstraint.isActive = true
            
            let pickerView = dropDownControl.pickerView
            pickerView.translatesAutoresizingMaskIntoConstraints = false
            pickerViewContainer.addSubview(pickerView)
            pickerView.leadingAnchor.constraint(equalTo: pickerViewContainer.leadingAnchor).isActive = true
            pickerView.bottomAnchor.constraint(equalTo: pickerViewContainer.bottomAnchor).isActive = true
            pickerView.trailingAnchor.constraint(equalTo: pickerViewContainer.trailingAnchor).isActive = true
            pickerView.heightAnchor.constraint(equalToConstant: expandedHeight).isActive = true
            
            dropDownControl.animatePickerView = { isExpanding in
                if isExpanding {
                    pickerViewContainerHeightConstraint.constant = expandedHeight
                }
                else {
                    pickerViewContainerHeightConstraint.constant = 0
                }
                
                var options: UIViewAnimationOptions = .beginFromCurrentState
                options.insert(isExpanding ? .curveEaseOut : .curveEaseIn)
                
                UIView.animate(withDuration: .defaultAnimationDuration, delay: 0, options: options, animations: {
                    self.layoutIfNeeded()
                    item.pickerViewAnimation?()
                })
            }
        }
    }
    
    private func dropDownControl(at location: CGPoint) -> DropDownControl? {
        return subviews.first(where: { $0.frame.contains(location) }) as? DropDownControl
    }
    
    // MARK: Interaction
    
    private var touchLocation: CGPoint?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchLocation = event?.allTouches?.first?.location(in: self)
        super.touchesBegan(touches, with: event)
    }
    
    override var isHighlighted: Bool {
        didSet {
            if let location = touchLocation, let dropDownControl = dropDownControl(at: location) {
                dropDownControl.isHighlighted = isHighlighted
            }
        }
    }
    
    @objc fileprivate func touchUpInside(_ control: SegmentedDropDownControl, event: UIEvent) {
        guard let location = event.allTouches?.first?.location(in: self),
            let dropDownControl = dropDownControl(at: location),
            let item = items.first(where: { $0.segment == dropDownControl }), !item.pickerItems.isEmpty
            else {
                return
        }
        
        if dropDownControl.isFirstResponder {
            dropDownControl.resignFirstResponder()
        }
        else {
            dropDownControl.becomeFirstResponder()
        }
    }
    
    var highlightedItem: SegmentedDropDownItem? {
        return items.first { item -> Bool in
            if let segment = item.segment as? DropDownControl {
                return segment.isHighlighted
            }
            return false
        }
    }
    
    var selectedItem: SegmentedDropDownItem? {
        return items.first { item -> Bool in
            if let segment = item.segment as? DropDownControl {
                return segment.isSelected
            }
            return false
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

    @discardableResult override func resignFirstResponder() -> Bool {
        items.forEach { item in
            item.segment?.resignFirstResponder()
        }

        return super.resignFirstResponder()
    }
}

extension SegmentedDropDownControl : UIPickerViewDataSource, UIPickerViewDelegate {
    private func itemIndex(pickerView: UIPickerView) -> Int {
        return items.index { item -> Bool in
            guard let segment = item.segment as? DropDownControl else {
                return false
            }
            
            return segment.pickerView == pickerView
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
        var attributes: [NSAttributedStringKey : Any]?
        
        if isItemDisabled(item, withTitle: title) {
            let color: UIColor = .gray5
            
            attributes = [
                .foregroundColor: color,
                .strikethroughColor: color,
                .strikethroughStyle: NSUnderlineStyle.styleSingle.rawValue
            ]
        }
        
        return NSAttributedString(string: title, attributes: attributes)
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if changeValueOnRowChange {
            let item = items[itemIndex(pickerView: pickerView)]
            let title = item.pickerItems[row]
            
            if !isItemDisabled(item, withTitle: title) {
                item.title = title
                
                sendActions(for: .valueChanged)
            }
        }
    }

    @objc fileprivate func pickerDoneButtonAction(_ button: UIButton) {
        func `where`(_ view: UIView) -> Bool {
            return type(of: view) == UIPickerView.self
        }
        
        guard let pickerView = button.superview?.subviews.first(where: `where`) as? UIPickerView else {
            return
        }
        
        let row = pickerView.selectedRow(inComponent: 0)
        let item = items[itemIndex(pickerView: pickerView)]
        let title = item.pickerItems[row]
        
        if !isItemDisabled(item, withTitle: title) {
            item.title = title
            
            sendActions(for: .valueChanged)
        }
        
        item.segment?.resignFirstResponder()
    }
}

fileprivate class DropDownLabel: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor(white: 240/255, alpha: 1)
        textAlignment = .center
        textColor = .gray2
        baselineAdjustment = .alignCenters
        minimumScaleFactor = 0.7
        adjustsFontSizeToFitWidth = true
        font = .screenshopFont(.quicksand, size: 16)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    let imageView = UIImageView()
    let image = UIImage(named: "DropDownArrow")?.withRenderingMode(.alwaysTemplate)
    let pickerView = UIPickerView()
    private(set) lazy var pickerInputView: PickerInputView = {
        return PickerInputView(pickerView: self.pickerView)
    }()
    
    var placeholderRow: String?
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        backgroundImageView.image = backgroundImage
        backgroundImageView.contentMode = .scaleToFill
        addSubview(backgroundImageView)
        backgroundImageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        backgroundImageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        backgroundImageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        backgroundImageView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
        imageView.setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)
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
        size.height = .defaultViewHeight
        return size
    }
    
    // MARK: Background
    
    private let backgroundImageView = UIImageView()
    private let backgroundImage = UIImage(named: "DropDownBackground")
    private let backgroundSelectedImage = UIImage(named: "DropDownSelectedBackground")
    
    private func syncBackgroundImage() {
        switch state {
        case .normal:
            backgroundImageView.image = backgroundImage
            backgroundImageView.alpha = 1
            
        case .highlighted:
            backgroundImageView.image = backgroundSelectedImage
            backgroundImageView.alpha = 1
            
        case .selected:
            backgroundImageView.image = backgroundSelectedImage
            backgroundImageView.alpha = 0.7
            
        default:
            break
        }
    }
    
    // MARK: States
    
    override var isHighlighted: Bool {
        didSet {
            syncBackgroundImage()
        }
    }
    
    override var isSelected: Bool {
        didSet {
            syncBackgroundImage()
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
    
    override var inputView: UIView? {
        get {
            return isPickerViewInsertedInline ? nil : pickerInputView
        }
    }
    
    var isPickerViewInsertedInline = false {
        didSet {
            pickerView.removeFromSuperview()
            
            if !isPickerViewInsertedInline {
                pickerInputView.insert(pickerView: pickerView)
            }
        }
    }
    
    func selectCurrentRow() {
        guard let dataSource = pickerView.dataSource, let delegate = pickerView.delegate else {
            return
        }
        
        var row = 0
        
        for i in 0 ..< dataSource.pickerView(pickerView, numberOfRowsInComponent: 0) {
            let title = delegate.pickerView?(pickerView, titleForRow: i, forComponent: 0) ?? ""
            
            if !title.isEmpty {
                if let text = titleLabel.text, title == text {
                    row = i
                    break
                }
                else if let text = placeholderRow, title == text {
                    row = i
                    break
                }
            }
        }
        
        pickerView.selectRow(row, inComponent: 0, animated: false)
    }
    
    var animatePickerView: ((_ isExpanding: Bool)->())?
    
    // MARK: First Responder
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    @discardableResult override func becomeFirstResponder() -> Bool {
        let becomeFirstResponder = super.becomeFirstResponder()
        
        if becomeFirstResponder {
            isSelected = true
            selectCurrentRow()
            
            if isPickerViewInsertedInline {
                animatePickerView?(true)
            }
        }
        
        return becomeFirstResponder
    }
    
    @discardableResult override func resignFirstResponder() -> Bool {
        let resignFirstResponder = super.resignFirstResponder()
        
        if resignFirstResponder {
            isSelected = false
            
            if isPickerViewInsertedInline {
                animatePickerView?(false)
            }
        }
        
        return resignFirstResponder
    }
}

fileprivate extension DropDownControl {
    class PickerInputView: UIInputView {
        let doneButton = UIButton()
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override init(frame: CGRect, inputViewStyle: UIInputViewStyle) {
            super.init(frame: frame, inputViewStyle: inputViewStyle)
            
            translatesAutoresizingMaskIntoConstraints = false
            allowsSelfSizing = true
            
            doneButton.translatesAutoresizingMaskIntoConstraints = false
            doneButton.setTitle("generic.done".localized, for: .normal)
            doneButton.setTitleColor(.gray3, for: .normal)
            doneButton.setTitleColor(.gray6, for: .highlighted)
            doneButton.contentEdgeInsets = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
            addSubview(doneButton)
            doneButton.topAnchor.constraint(equalTo: topAnchor).isActive = true
            doneButton.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        }
        
        convenience init(pickerView: UIPickerView) {
            self.init(frame: .zero, inputViewStyle: .default)
            insert(pickerView: pickerView)
        }
        
        func insert(pickerView: UIPickerView) {
            pickerView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(pickerView)
            pickerView.topAnchor.constraint(equalTo: doneButton.bottomAnchor).isActive = true
            pickerView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            pickerView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            pickerView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        }
    }
}
