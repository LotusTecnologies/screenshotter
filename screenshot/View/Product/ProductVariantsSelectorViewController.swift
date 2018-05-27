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
        
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(container)
        container.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant:.padding).isActive = true
        container.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant:.extendedPadding).isActive = true
        container.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant:-.extendedPadding).isActive = true
        container.bottomAnchor.constraint(equalTo: self.continueButton.topAnchor).isActive = true
        
        let quantityContainer = UIView()
        quantityContainer.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(quantityContainer)
        quantityContainer.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
        quantityContainer.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        quantityContainer.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
        quantityContainer.heightAnchor.constraint(equalToConstant: 50).isActive = true

        let quantityLabel = UILabel()
        quantityLabel.translatesAutoresizingMaskIntoConstraints = false
        quantityLabel.text = Options.quantity.localized
        quantityContainer.addSubview(quantityLabel)
        quantityLabel.leadingAnchor.constraint(equalTo: quantityContainer.leadingAnchor).isActive = true
        quantityLabel.centerYAnchor.constraint(equalTo: quantityContainer.centerYAnchor).isActive = true
        quantityLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        quantityLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        let quantityControl = SegmentedDropDownControl()
        quantityControl.translatesAutoresizingMaskIntoConstraints = false
        let quantityRange = (1...Constants.cartItemMaxQuantity)
        quantityControl.items = [SegmentedDropDownItem(pickerItems: quantityRange.map { "\($0)" }, selectedPickerItem: "\(initialQuantity)")]
        quantityContainer.addSubview(quantityControl)
        quantityControl.heightAnchor.constraint(equalToConstant: 50)
        quantityControl.leadingAnchor.constraint(equalTo: quantityLabel.trailingAnchor, constant:.extendedPadding).isActive = true
        quantityControl.trailingAnchor.constraint(equalTo:quantityContainer.trailingAnchor).isActive = true
        quantityControl.centerYAnchor.constraint(equalTo: quantityContainer.centerYAnchor).isActive = true
        
        let colorContainer = UIView()
        colorContainer.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(colorContainer)
        colorContainer.topAnchor.constraint(equalTo: quantityContainer.bottomAnchor, constant:.padding).isActive = true
        colorContainer.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        colorContainer.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
        colorContainer.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        let colorLabel = UILabel()
        colorLabel.translatesAutoresizingMaskIntoConstraints = false
        colorLabel.text = Options.color.localized
        colorContainer.addSubview(colorLabel)
        colorLabel.leadingAnchor.constraint(equalTo: colorContainer.leadingAnchor).isActive = true
        colorLabel.centerYAnchor.constraint(equalTo: colorContainer.centerYAnchor).isActive = true
        colorLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        colorLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        let colorControl = SegmentedDropDownControl()
        colorControl.translatesAutoresizingMaskIntoConstraints = false
        if let items = structuredProduct.colors {
            colorControl.items = [SegmentedDropDownItem(pickerItems: items, selectedPickerItem: initialColor ?? structuredProduct.defaultColor)]
        }
        colorContainer.addSubview(colorControl)
        colorControl.heightAnchor.constraint(equalToConstant: 50)
        colorControl.leadingAnchor.constraint(equalTo: colorLabel.trailingAnchor, constant:.extendedPadding).isActive = true
        colorControl.trailingAnchor.constraint(equalTo:colorContainer.trailingAnchor).isActive = true
        colorControl.centerYAnchor.constraint(equalTo: colorContainer.centerYAnchor).isActive = true
        
        let sizeContainer = UIView()
        sizeContainer.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(sizeContainer)
        sizeContainer.topAnchor.constraint(equalTo: colorContainer.bottomAnchor, constant:.padding).isActive = true
        sizeContainer.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        sizeContainer.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
        sizeContainer.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        let sizeLabel = UILabel()
        sizeLabel.translatesAutoresizingMaskIntoConstraints = false
        sizeLabel.text = Options.size.localized
        sizeContainer.addSubview(sizeLabel)
        sizeLabel.leadingAnchor.constraint(equalTo: sizeContainer.leadingAnchor).isActive = true
        sizeLabel.centerYAnchor.constraint(equalTo: sizeContainer.centerYAnchor).isActive = true
        sizeLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        sizeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        let sizeControl = SegmentedDropDownControl()
        sizeControl.translatesAutoresizingMaskIntoConstraints = false
        if let items = structuredProduct.sizes {
            sizeControl.items = [SegmentedDropDownItem(pickerItems: items, selectedPickerItem: initialSize ?? items.first)]
        }
        sizeContainer.addSubview(sizeControl)
        sizeControl.heightAnchor.constraint(equalToConstant: 50)
        sizeControl.leadingAnchor.constraint(equalTo: sizeLabel.trailingAnchor, constant:.extendedPadding).isActive = true
        sizeControl.trailingAnchor.constraint(equalTo:sizeContainer.trailingAnchor).isActive = true
        sizeControl.centerYAnchor.constraint(equalTo: sizeContainer.centerYAnchor).isActive = true
        
        quantityLabel.trailingAnchor.constraint(greaterThanOrEqualTo: colorLabel.trailingAnchor).isActive = true
        quantityLabel.trailingAnchor.constraint(greaterThanOrEqualTo: sizeLabel.trailingAnchor).isActive = true
        colorLabel.trailingAnchor.constraint(greaterThanOrEqualTo: quantityLabel.trailingAnchor).isActive = true
        colorLabel.trailingAnchor.constraint(greaterThanOrEqualTo: sizeLabel.trailingAnchor).isActive = true
        sizeLabel.trailingAnchor.constraint(greaterThanOrEqualTo: quantityLabel.trailingAnchor).isActive = true
        sizeLabel.trailingAnchor.constraint(greaterThanOrEqualTo: colorLabel.trailingAnchor).isActive = true

        
        sizeContainer.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -.extendedPadding).isActive = true
        
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
