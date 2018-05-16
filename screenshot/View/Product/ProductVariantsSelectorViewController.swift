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
        
        var localized: String { // TODO: localize
            switch self {
            case .quantity:
                return "Quantity"
            case .color:
                return "Color"
            case .size:
                return "Size"
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

    init(product: Product) {
        structuredProduct = StructuredProduct(product)
        super.init(nibName: nil, bundle: nil)
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = "Edit Item" // TODO: localize
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
    
    // MARK: Interaction
    
    @objc fileprivate func segmentChanged(_ segmentedControl: UISegmentedControl) {
        guard let option = Options(rawValue: segmentedControl.selectedSegmentIndex) else {
            return
        }
        
        currentOption = option
        pickerView.reloadAllComponents()
    }
    
    // MARK: Datasource
    
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
}

extension ProductVariantsSelectorViewController: UIPickerViewDataSource {
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
}
