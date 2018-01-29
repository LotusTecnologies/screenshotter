//
//  SegmentedDropDownButton.swift
//  screenshot
//
//  Created by Corey Werner on 1/29/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation

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
}

class SegmentedDropDownButton : UIView {
    fileprivate var items: [SegmentedDropDownItem]!
    
    fileprivate let borderWidth: CGFloat = 1
    fileprivate let borderColor: UIColor = .gray8
    
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
                segment.layer.borderColor = borderColor.cgColor
                segment.layer.borderWidth = borderWidth
                segment.layer.masksToBounds = true
                segment.layer.cornerRadius = .defaultCornerRadius

            } else {
                // iOS 10 masking happens in the layoutSubviews
                if #available(iOS 11.0, *) {
                    segment.layer.borderColor = UIColor.gray8.cgColor
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
                frameLayer.strokeColor = item.frameLayer?.strokeColor ?? borderColor.cgColor
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
            button.resignFirstResponder()
        }
        else {
            button.becomeFirstResponder()
        }
    }
    
    // MARK: Border
    
    func setBorderColor(_ color: UIColor, atIndex index: Int) {
        guard items.count > index else {
            return
        }
        
        let item = items[index]
        
        if let frameLayer = item.frameLayer {
            frameLayer.strokeColor = color.cgColor
        }
        else {
            item.segment.layer.borderColor = color.cgColor
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
        resignFirstResponder()
    }
}
