//
//  ProductsOptions.swift
//  screenshot
//
//  Created by Corey Werner on 11/21/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

class ProductsOptionsMask : NSObject {
    let rawValue: Int
    
    static let genderUnisex  = ProductsOptionsMask(rawValue: 1 << 0) // 1
    static let genderMale    = ProductsOptionsMask(rawValue: 1 << 1) // 2
    static let genderFemale  = ProductsOptionsMask(rawValue: 1 << 2) // 4
    
    static let sizeAdult     = ProductsOptionsMask(rawValue: 1 << 3) // 8
    static let sizeChild     = ProductsOptionsMask(rawValue: 1 << 4) // 16
    static let sizePlus      = ProductsOptionsMask(rawValue: 1 << 5) // 32
    
    init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    static func current() -> ProductsOptionsMask {
        var workingValue: Int
        let productsOptions = ProductsOptions.global
        switch productsOptions.currentGender {
        case .male:
            workingValue = ProductsOptionsMask.genderMale.rawValue
        case .female:
            workingValue = ProductsOptionsMask.genderFemale.rawValue
        default:
            workingValue = ProductsOptionsMask.genderUnisex.rawValue
        }
        
        switch productsOptions.currentSize {
        case .child:
            workingValue |= ProductsOptionsMask.sizeChild.rawValue
        case .adult:
            workingValue |= ProductsOptionsMask.sizeAdult.rawValue
        case .plus:
            workingValue |= ProductsOptionsMask.sizePlus.rawValue
        }
        
        return ProductsOptionsMask(rawValue: workingValue)
    }
}

class _ProductsOptionsMask : NSObject {
    static func current() -> Int {
        return ProductsOptionsMask.current().rawValue
    }
}

@objc protocol ProductsOptionsDelegate : NSObjectProtocol {
    func productsOptionsDidChange(_ productsOptions: ProductsOptions)
}

class ProductsOptions : NSObject {
    weak var delegate: ProductsOptionsDelegate?
    
    fileprivate(set) var gender: ProductsOptionsGender?
    fileprivate(set) var size: ProductsOptionsSize?
    fileprivate(set) var sale: ProductsOptionsSale?
    fileprivate(set) var sort: ProductsOptionsSort?
    
    static let global: ProductsOptions = {
        let options = ProductsOptions()
        options.gender = ProductsOptionsGender(intValue: ProductsOptions.value(forProductsOptionsKey: UserDefaultsKeys.productGender))
        options.size = ProductsOptionsSize(intValue: ProductsOptions.value(forProductsOptionsKey: UserDefaultsKeys.productSize))
        options.sale = ProductsOptionsSale(intValue: ProductsOptions.value(forProductsOptionsKey: UserDefaultsKeys.productSale))
        options.sort = ProductsOptionsSort(intValue: UserDefaults.standard.integer(forKey: UserDefaultsKeys.productSort))
        return options
    }()
    
    fileprivate let sortItems: [ProductsOptionsSort: ProductsOptionsSortItem] = [
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
        view.doneButton.addTarget(self, action: #selector(doneButtonAction), for: .touchUpInside)
        self.syncOptions(withView: view)
        return view
    }()
    
    fileprivate(set) var currentGender: ProductsOptionsGender {
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: UserDefaultsKeys.productGender)
        }
        get {
            return ProductsOptionsGender(intValue: ProductsOptions.value(forProductsOptionsKey: UserDefaultsKeys.productGender))
        }
    }
    
    fileprivate(set) var currentSize: ProductsOptionsSize {
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: UserDefaultsKeys.productSize)
        }
        get {
            return ProductsOptionsSize(intValue: ProductsOptions.value(forProductsOptionsKey: UserDefaultsKeys.productSize))
        }
    }
    
    fileprivate(set) var currentSale: ProductsOptionsSale {
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: UserDefaultsKeys.productSale)
        }
        get {
            return ProductsOptionsSale(intValue: ProductsOptions.value(forProductsOptionsKey: UserDefaultsKeys.productSale))
        }
    }
    
    fileprivate(set) var currentSort: ProductsOptionsSort {
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: UserDefaultsKeys.productSort)
        }
        get {
            return ProductsOptionsSort(intValue: UserDefaults.standard.integer(forKey: UserDefaultsKeys.productSort))
        }
    }
    
    func syncOptions() {
        syncOptions(withView: view)
    }
    
    private func syncOptions(withView view: ProductsOptionsView) {
        view.sortPickerView.selectRow(self.currentSort.rawValue, inComponent: 0, animated: false)
        view.genderControl.selectedSegmentIndex = self.currentGender.offsetValue
        view.sizeControl.selectedSegmentIndex = self.currentSize.offsetValue
        view.saleControl.selectedSegmentIndex = self.currentSale.offsetValue
    }
    
    @objc private func doneButtonAction() {
        currentGender = ProductsOptionsGender(offsetValue: view.genderControl.selectedSegmentIndex)
        currentSize = ProductsOptionsSize(offsetValue: view.sizeControl.selectedSegmentIndex)
        currentSale = ProductsOptionsSale(offsetValue: view.saleControl.selectedSegmentIndex)
        currentSort = ProductsOptionsSort(intValue: view.sortPickerView.selectedRow(inComponent: 0))
        UserDefaults.standard.synchronize()
        
        delegate?.productsOptionsDidChange(self)
    }
}

extension ProductsOptions {
    static func value(forProductsOptionsKey key: String) -> Int {
        let int = UserDefaults.standard.integer(forKey: key)
        
        guard int == 0 else {
            return int
        }
        
        switch key {
        case UserDefaultsKeys.productGender:
            return ProductsOptionsGender.default.rawValue
            
        case UserDefaultsKeys.productSize:
            return ProductsOptionsSize.default.rawValue
            
        case UserDefaultsKeys.productSale:
            return ProductsOptionsSale.default.rawValue
            
        default:
            return 1
        }
    }
    
    static func offsetValue(forProductsOptionsKey key: String) -> Int {
        return value(forProductsOptionsKey: key) - 1
    }
    
    // MARK: Objc
    
    func _currentGender() -> Int {
        return currentGender.rawValue
    }
    
    func _currentSize() -> Int {
        return currentSize.rawValue
    }
    
    func _currentSale() -> Int {
        return currentSale.rawValue
    }
    
    func _currentSort() -> Int {
        return currentSort.rawValue
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
        return sortItems[ProductsOptionsSort(intValue: row)]?.detailedTitle()
    }
}

class ProductsOptionsView : UIView {
    let genderControl = UISegmentedControl(items: [
        ProductsOptionsGender.female.stringValue,
        ProductsOptionsGender.male.stringValue,
        ProductsOptionsGender.unisex.stringValue
        ])
    let sizeControl = UISegmentedControl(items: [
        ProductsOptionsSize.child.stringValue,
        ProductsOptionsSize.adult.stringValue,
        ProductsOptionsSize.plus.stringValue
        ])
    let saleControl = UISegmentedControl(items: [
        ProductsOptionsSale.sale.stringValue,
        ProductsOptionsSale.all.stringValue
        ])
    let sortPickerView = UIPickerView()
    let doneButton = MainButton()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        layoutMargins = UIEdgeInsetsMake(.padding, .extendedPadding, .padding, .extendedPadding)
        
        let borderView = UIView()
        borderView.translatesAutoresizingMaskIntoConstraints = false
        borderView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        addSubview(borderView)
        borderView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        borderView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        borderView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        borderView.heightAnchor.constraint(equalToConstant: .halfPoint).isActive = true
        
        genderControl.translatesAutoresizingMaskIntoConstraints = false
        genderControl.tintColor = .crazeGreen
        addSubview(genderControl)
        genderControl.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        genderControl.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        genderControl.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        genderControl.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        genderControl.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
//        sizeControl.translatesAutoresizingMaskIntoConstraints = false
//        sizeControl.tintColor = .crazeGreen
//        addSubview(sizeControl)
//        sizeControl.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
//        sizeControl.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
//        sizeControl.topAnchor.constraint(equalTo: genderControl.bottomAnchor, constant: .padding).isActive = true
//        sizeControl.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
//        sizeControl.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        saleControl.translatesAutoresizingMaskIntoConstraints = false
        saleControl.tintColor = .crazeGreen
        addSubview(saleControl)
        saleControl.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        saleControl.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        saleControl.topAnchor.constraint(equalTo: genderControl.bottomAnchor, constant: .padding).isActive = true
        saleControl.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        saleControl.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        let sortLabel = UILabel()
        sortLabel.translatesAutoresizingMaskIntoConstraints = false
        sortLabel.text = "Sort by"
        sortLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        sortLabel.adjustsFontForContentSizeCategory = true
        addSubview(sortLabel)
        sortLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        sortLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        sortLabel.topAnchor.constraint(equalTo: saleControl.bottomAnchor, constant: .extendedPadding).isActive = true
        sortLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        sortLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        sortPickerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(sortPickerView)
        sortPickerView.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        sortPickerView.topAnchor.constraint(equalTo: sortLabel.bottomAnchor).isActive = true
        sortPickerView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        sortPickerView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        sortPickerView.heightAnchor.constraint(equalToConstant: 130).isActive = true
        
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.backgroundColor = .gray3
        doneButton.setTitle("Done", for: .normal)
        addSubview(doneButton)
        doneButton.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        doneButton.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        doneButton.topAnchor.constraint(equalTo: sortPickerView.bottomAnchor, constant: .padding).isActive = true
        doneButton.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        doneButton.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
        doneButton.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    }
    
    override var intrinsicContentSize: CGSize {
        return UILayoutFittingExpandedSize
    }
}

enum ProductsOptionsSort : Int, EnumIntDefaultProtocol {
    case similar
    case priceAsc
    case priceDes
    case brands
    
    static var `default`: ProductsOptionsSort {
        return .similar
    }
    
    init(intValue: Int) {
        self = ProductsOptionsSort(rawValue: intValue) ?? .default
    }
}

enum ProductsOptionsGender : Int, EnumIntDefaultProtocol, EnumIntOffsetProtocol {
    case female = 1
    case male
    case unisex
    
    static var `default`: ProductsOptionsGender {
        return .female
    }
    
    init(intValue: Int) {
        self = ProductsOptionsGender(rawValue: intValue) ?? .default
    }
    
    init(offsetValue: Int) {
        self.init(intValue: offsetValue + 1)
    }
    
    var offsetValue: Int {
        return self.rawValue - 1
    }
    
    var stringValue: String {
        var string: String
        
        switch self {
        case .female: string = "Female"
        case .male: string = "Male"
        case .unisex: string = "All"
        }
        
        return string
    }
}

enum ProductsOptionsSize : Int, EnumIntDefaultProtocol, EnumIntOffsetProtocol {
    case child = 1
    case adult
    case plus
    
    static var `default`: ProductsOptionsSize {
        return .adult
    }
    
    init(intValue: Int) {
        self = ProductsOptionsSize(rawValue: intValue) ?? .default
    }
    
    init(offsetValue: Int) {
        self.init(intValue: offsetValue + 1)
    }
    
    var offsetValue: Int {
        return self.rawValue - 1
    }
    
    var stringValue: String {
        var string: String
        
        switch self {
        case .child: string = "Child"
        case .adult: string = "Adult"
        case .plus: string = "Plus"
        }
        
        return string
    }
}

enum ProductsOptionsSale : Int, EnumIntDefaultProtocol, EnumIntOffsetProtocol {
    case sale = 1
    case all
    
    static var `default`: ProductsOptionsSale {
        return .all
    }
    
    init(intValue: Int) {
        self = ProductsOptionsSale(rawValue: intValue) ?? .default
    }
    
    init(offsetValue: Int) {
        self.init(intValue: offsetValue + 1)
    }
    
    var offsetValue: Int {
        return self.rawValue - 1
    }
    
    var stringValue: String {
        var string: String
        
        switch self {
        case .sale: string = "Sale"
        case .all: string = "All"
        }
        
        return string
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
