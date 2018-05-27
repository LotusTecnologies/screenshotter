//
//  ProductVariantsSelectorViewController.swift
//  screenshot
//
//  Created by Corey Werner on 5/16/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

protocol ProductVariantsSelectorViewControllerDelegate: NSObjectProtocol {
    func productVariantsSelectorViewControllerDidPressCancel(_ productVariantsSelectorViewController: ProductVariantsSelectorViewController)
    func productVariantsSelectorViewControllerDidPressContinue(_ productVariantsSelectorViewController: ProductVariantsSelectorViewController)
}

class ProductVariantsSelectorViewController: AlertTemplateViewController {
    
    enum Options: Int {
        case quantity
        case color
        case size
        
        var localized: String {
            switch self {
            case .quantity:
                return "product.variants.quantity".localized
            case .color:
                return "product.variants.color".localized
            case .size:
                return "product.variants.size".localized
            }
        }
    }
    
    weak var delegate:ProductVariantsSelectorViewControllerDelegate?
    
    var colorControl:SegmentedDropDownControl?
    var sizeControl:SegmentedDropDownControl?
    var quantityControl:SegmentedDropDownControl?
    
    fileprivate let structuredProduct: StructuredProduct
    fileprivate let initialColor: String?
    fileprivate let initialSize: String?
    fileprivate let initialQuantity: Int
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(product: Product, initialVariant: Variant? = nil, initialQuantity: Int = 1) {
        structuredProduct = StructuredProduct(product)
        initialColor = initialVariant?.color
        initialSize = initialVariant?.size
        self.initialQuantity = initialQuantity
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = "product.variants.edit".localized
        
        let quantityControl = SegmentedDropDownControl()
        quantityControl.translatesAutoresizingMaskIntoConstraints = false
        let quantityRange = (1...Constants.cartItemMaxQuantity)
        quantityControl.items = [SegmentedDropDownItem(pickerItems: quantityRange.map { "\($0)" }, selectedPickerItem: "\(initialQuantity)")]
        view.addSubview(quantityControl)
        quantityControl.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor).isActive = true
        quantityControl.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor).isActive = true
        quantityControl.heightAnchor.constraint(equalToConstant: 50)
        
        let quantityLabel = UILabel()
        quantityLabel.translatesAutoresizingMaskIntoConstraints = false
        quantityLabel.text = Options.quantity.localized
        view.addSubview(quantityLabel)
        quantityLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        quantityLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        quantityLabel.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor).isActive = true
        quantityLabel.centerYAnchor.constraint(equalTo: quantityControl.centerYAnchor).isActive = true
        quantityLabel.trailingAnchor.constraint(equalTo: quantityControl.leadingAnchor, constant: -.extendedPadding).isActive = true
        
        let colorControl = SegmentedDropDownControl()
        colorControl.translatesAutoresizingMaskIntoConstraints = false
        if let items = structuredProduct.colors {
            colorControl.items = [SegmentedDropDownItem(pickerItems: items, selectedPickerItem: initialColor ?? structuredProduct.defaultColor)]
        }
        view.addSubview(colorControl)
        colorControl.topAnchor.constraint(equalTo: quantityControl.bottomAnchor, constant: .padding).isActive = true
        colorControl.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor).isActive = true
        colorControl.heightAnchor.constraint(equalToConstant: 50)
        
        let colorLabel = UILabel()
        colorLabel.translatesAutoresizingMaskIntoConstraints = false
        colorLabel.text = Options.color.localized
        view.addSubview(colorLabel)
        colorLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        colorLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        colorLabel.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor).isActive = true
        colorLabel.trailingAnchor.constraint(equalTo: colorControl.leadingAnchor, constant: -.extendedPadding).isActive = true
        colorLabel.centerYAnchor.constraint(equalTo: colorControl.centerYAnchor).isActive = true
        
        let sizeControl = SegmentedDropDownControl()
        sizeControl.translatesAutoresizingMaskIntoConstraints = false
        if let items = structuredProduct.sizes {
            sizeControl.items = [SegmentedDropDownItem(pickerItems: items, selectedPickerItem: initialSize ?? items.first)]
        }
        view.addSubview(sizeControl)
        sizeControl.topAnchor.constraint(equalTo: colorControl.bottomAnchor, constant: .padding).isActive = true
        sizeControl.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor).isActive = true
        sizeControl.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor).isActive = true
        sizeControl.heightAnchor.constraint(equalToConstant: 50)
        
        let sizeLabel = UILabel()
        sizeLabel.translatesAutoresizingMaskIntoConstraints = false
        sizeLabel.text = Options.size.localized
        view.addSubview(sizeLabel)
        sizeLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        sizeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        sizeLabel.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor).isActive = true
        sizeLabel.trailingAnchor.constraint(equalTo: sizeControl.leadingAnchor, constant: -.extendedPadding).isActive = true
        sizeLabel.centerYAnchor.constraint(equalTo: sizeControl.centerYAnchor).isActive = true
        
        quantityLabel.trailingAnchor.constraint(greaterThanOrEqualTo: colorLabel.trailingAnchor).isActive = true
        quantityLabel.trailingAnchor.constraint(greaterThanOrEqualTo: sizeLabel.trailingAnchor).isActive = true
        colorLabel.trailingAnchor.constraint(greaterThanOrEqualTo: quantityLabel.trailingAnchor).isActive = true
        colorLabel.trailingAnchor.constraint(greaterThanOrEqualTo: sizeLabel.trailingAnchor).isActive = true
        sizeLabel.trailingAnchor.constraint(greaterThanOrEqualTo: quantityLabel.trailingAnchor).isActive = true
        sizeLabel.trailingAnchor.constraint(greaterThanOrEqualTo: colorLabel.trailingAnchor).isActive = true
        
        continueButton.setTitle("generic.done".localized, for: .normal)
        continueButton.addTarget(self, action: #selector(continueButtonPressed(_:)), for: .touchUpInside)
        cancelButton.setTitle("generic.cancel".localized, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelButtonPress(_:)), for: .touchUpInside)
        
        colorControl.addTarget(self, action: #selector(colorControlValueChanged), for: .valueChanged)
        self.colorControl = colorControl
        sizeControl.addTarget(self, action: #selector(sizeControlValueChanged), for: .valueChanged)
        self.sizeControl = sizeControl
        quantityControl.addTarget(self, action: #selector(quantityValueChanged), for: .valueChanged)
        self.quantityControl = quantityControl
        
        colorControl.changeValueOnRowChange = true
        sizeControl.changeValueOnRowChange = true
        quantityControl.changeValueOnRowChange = true
        
        updateDisabledItems()
    }
    
    func updateDisabledItems() {
        if let colorControl = self.colorControl {
            let structuredProduct = self.structuredProduct
            if let structuredColorVariant = structuredProduct.structuredColorVariant(forColor: colorControl.items.first?.selectedPickerItem){
                self.sizeControl?.items.first?.disabledPickerItems = structuredProduct.subtractingSizes(of: structuredColorVariant)
            }
        }
    }
    
    @objc func sizeControlValueChanged() {
        
    }
    
    @objc func quantityValueChanged() {
        
    }

    @objc func colorControlValueChanged() {
        if let colorControl = self.colorControl {
            let structuredProduct = self.structuredProduct
            if let structuredColorVariant = structuredProduct.structuredColorVariant(forColor: colorControl.items.first?.selectedPickerItem){
                self.sizeControl?.items.first?.disabledPickerItems = structuredProduct.subtractingSizes(of: structuredColorVariant)
            }
        }
    }
    
    var selectedVariant: Variant? {
        if let color = self.colorControl?.items.first?.selectedPickerItem, let size = self.sizeControl?.items.first?.selectedPickerItem {
            return structuredProduct.variant(color: color, size: size)
        }
        
        return nil
    }
    
    var selectedQuantity: Int {
        if let item = self.quantityControl?.items.first?.selectedPickerItem, let quantity = Int(item) {
            return quantity
        }
        
        return 1
    }
}

extension ProductVariantsSelectorViewController {
    @IBAction func continueButtonPressed(_ sender:Any){
        self.delegate?.productVariantsSelectorViewControllerDidPressContinue(self)
    }
    
    @IBAction func cancelButtonPress(_ sender:Any){
        self.delegate?.productVariantsSelectorViewControllerDidPressCancel(self)
    }
}
