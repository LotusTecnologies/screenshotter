//
//  ProductVariantsSelectorViewController.swift
//  screenshot
//
//  Created by Corey Werner on 5/16/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

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
    
    fileprivate var currentOption: Options = .quantity
    
    fileprivate let pickerView = UIPickerView()
    
    // MARK: Life Cycle
    
    fileprivate let structuredProduct: StructuredProduct

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(product: Product, selectedVariant: Variant? = nil, selectedQuantity: Int = 1) {
        structuredProduct = StructuredProduct(product)
        super.init(nibName: nil, bundle: nil)
        
        if let color = selectedVariant?.color, let colorIndex = structuredProduct.colors?.index(of: color) {
            selectedRows[.color] = colorIndex
        }
        
        if let size = selectedVariant?.size, let sizeIndex = structuredProduct.sizes?.index(of: size) {
            selectedRows[.size] = sizeIndex
        }
        
        let indexFromZero = selectedQuantity - 1
        
        if quantityDataSource.count > indexFromZero {
            selectedRows[.quantity] = indexFromZero
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = "product.variants.edit".localized
        continueButton.setTitle("generic.done".localized, for: .normal)
        cancelButton.setTitle("generic.cancel".localized, for: .normal)
        
        var items = [Options.quantity.localized]
        
        if structuredProduct.colors != nil {
            items.append(Options.color.localized)
        }
        if structuredProduct.sizes != nil {
            items.append(Options.size.localized)
        }
        
        let segmentedControl = UISegmentedControl(items: items)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.tintColor = .crazeGreen
        segmentedControl.selectedSegmentIndex = currentOption.rawValue
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        view.addSubview(segmentedControl)
        segmentedControl.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor).isActive = true
        segmentedControl.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor).isActive = true
        segmentedControl.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor).isActive = true
        
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        pickerView.dataSource = self
        pickerView.delegate = self
        view.addSubview(pickerView)
        pickerView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: .padding).isActive = true
        pickerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        pickerView.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor).isActive = true
        pickerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        pickerView.heightAnchor.constraint(equalToConstant: 150).isActive = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        selectCurrentRow()
    }
    
    // MARK: Interaction
    
    @objc fileprivate func segmentChanged(_ segmentedControl: UISegmentedControl) {
        guard let option = Options(rawValue: segmentedControl.selectedSegmentIndex) else {
            return
        }
        
        currentOption = option
        pickerView.reloadAllComponents()
        selectCurrentRow()
    }
    
    // MARK: Datasource
    
    fileprivate var selectedRows: [Options: Int] = [:]
    fileprivate let quantityDataSource = (1...Constants.cartItemMaxQuantity).map { "\($0)" }
    
    fileprivate var currentDataSource: [String]? {
        switch currentOption {
        case .color:
            return structuredProduct.colors
        case .quantity:
            return quantityDataSource
        case .size:
            return structuredProduct.sizes
        }
    }
    
    var selectedVariant: Variant? {
        guard let colors = structuredProduct.colors,
            let colorIndex = selectedRows[.color],
            colors.count > colorIndex,
            let sizes = structuredProduct.sizes,
            let sizeIndex = selectedRows[.size],
            sizes.count > sizeIndex
            else {
                return nil
        }
        
        return structuredProduct.variant(color: colors[colorIndex], size: sizes[sizeIndex])
    }
    
    var selectedQuantity: Int {
        let quantityIndex = selectedRows[.quantity] ?? 0
        
        if quantityDataSource.count > quantityIndex, let quantity = Int(quantityDataSource[quantityIndex]) {
            return quantity
        }
        
        return 1
    }
}

extension ProductVariantsSelectorViewController: UIPickerViewDataSource {
    fileprivate func selectCurrentRow() {
        let selectedRow = selectedRows[currentOption] ?? 0
        pickerView.selectRow(selectedRow, inComponent: 0, animated: false)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return currentDataSource?.count ?? 0
    }
}

extension ProductVariantsSelectorViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if let dataSource = currentDataSource, dataSource.count > row {
            return dataSource[row]
        }
        
        return nil
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedRows[currentOption] = row
    }
}
