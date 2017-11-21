//
//  ProductsOptions.swift
//  screenshot
//
//  Created by Corey Werner on 11/21/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

enum ProductsOptionsSortType : Int {
    case similar
    case priceAsc
    case priceDes
    case brands
    
    init(intValue: Int) {
        self = ProductsOptionsSortType(rawValue: intValue) ?? .similar
    }
}

class ProductsOptions : NSObject {
    fileprivate(set) var currentSortType = ProductsOptionsSortType(intValue: UserDefaults.standard.integer(forKey: UserDefaultsKeys.productSort))
    
    fileprivate let sortItems: [ProductsOptionsSortType: ProductsOptionsSortItem] = [
        .similar: ProductsOptionsSortItem(title: "Similar"),
        .priceAsc: ProductsOptionsSortItem(title: "Price", detail: "(lowest first)"),
        .priceDes: ProductsOptionsSortItem(title: "Price", detail: "(highest first)"),
        .brands: ProductsOptionsSortItem(title: "Brands")
    ]
    
    private(set) lazy var view: ProductsOptionsView = {
        let view = ProductsOptionsView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.sortPickerView.dataSource = self
        view.sortPickerView.delegate = self
        view.sortPickerView.selectRow(self.currentSortType.rawValue, inComponent: 0, animated: false)
        return view
    }()
    
    // MARK: Objc
    
    func _currentSortType() -> Int {
        return currentSortType.rawValue
    }
}

extension ProductsOptions : UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return sortItems.count
    }
}

extension ProductsOptions : UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return sortItems[ProductsOptionsSortType(intValue: row)]?.detailedTitle()
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        currentSortType = ProductsOptionsSortType(intValue: row)
        UserDefaults.standard.set(row, forKey: UserDefaultsKeys.productSort)
        
        // TODO: delegate
//        [self reloadCollectionViewForIndex:[self.shoppablesToolbar selectedShoppableIndex]];
//        [self.navigationController.navigationBar endEditing:YES];
    }
}

class ProductsOptionsView : UIInputView {
    let genderControl = UISegmentedControl()
    let sortPickerView = UIPickerView()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect, inputViewStyle: UIInputViewStyle) {
        super.init(frame: frame, inputViewStyle: inputViewStyle)
        
        layoutMargins = UIEdgeInsetsMake(.extendedPadding, .extendedPadding, .extendedPadding, .extendedPadding)
        
        genderControl.translatesAutoresizingMaskIntoConstraints = false
        genderControl.backgroundColor = .orange
        genderControl.tintColor = .yellow
        genderControl.insertSegment(withTitle: "Female", at: 0, animated: false)
        genderControl.insertSegment(withTitle: "Male", at: 1, animated: false)
        genderControl.insertSegment(withTitle: "All", at: 2, animated: false)
        genderControl.selectedSegmentIndex = 2
        addSubview(genderControl)
        genderControl.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        genderControl.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        sortPickerView.translatesAutoresizingMaskIntoConstraints = false
        sortPickerView.backgroundColor = .green
        addSubview(sortPickerView)
        sortPickerView.topAnchor.constraint(equalTo: genderControl.bottomAnchor, constant: .padding).isActive = true
        sortPickerView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        sortPickerView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
        sortPickerView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    }
}

private struct ProductsOptionsSortItem {
    let title: String
    let detail: String?
    
    init(title: String) {
        self.init(title: title, detail: nil)
    }
    
    init(title: String, detail: String?) {
        self.title = title
        self.detail = detail
    }
    
    func detailedTitle() -> String {
        if let detail = detail, !detail.isEmpty {
            return "\(title) \(detail)"
            
        } else {
            return title
        }
    }
}
