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
    
    static let genderAuto   = ProductsOptionsMask(rawValue: 1 << 0) // 1
    static let genderMale   = ProductsOptionsMask(rawValue: 1 << 1) // 2
    static let genderFemale = ProductsOptionsMask(rawValue: 1 << 2) // 4
    
    static let sizeAdult    = ProductsOptionsMask(rawValue: 1 << 3) // 8
    static let sizeChild    = ProductsOptionsMask(rawValue: 1 << 4) // 16
    static let sizePlus     = ProductsOptionsMask(rawValue: 1 << 5) // 32
    
    static var global: ProductsOptionsMask {
        return ProductsOptionsMask(ProductsOptionsGender.globalValue, ProductsOptionsSize.globalValue)
    }
    
    init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    convenience init(_ gender: ProductsOptionsGender, _ size: ProductsOptionsSize) {
        var value: Int
        
        switch gender {
        case .male:
            value = ProductsOptionsMask.genderMale.rawValue
        case .female:
            value = ProductsOptionsMask.genderFemale.rawValue
        default:
            value = ProductsOptionsMask.genderAuto.rawValue
        }
        
        switch size {
        case .child:
            value |= ProductsOptionsMask.sizeChild.rawValue
        case .plus:
            value |= ProductsOptionsMask.sizePlus.rawValue
        default:
            value |= ProductsOptionsMask.sizeAdult.rawValue
        }
        
        self.init(rawValue: value)
    }
    
    var gender: ProductsOptionsGender {
        if rawValue & ProductsOptionsMask.genderMale.rawValue > 0 {
            return .male
        } else if rawValue & ProductsOptionsMask.genderFemale.rawValue > 0 {
            return .female
        } else {
            return .auto
        }
    }
    
    var size: ProductsOptionsSize {
        if rawValue & ProductsOptionsMask.sizeChild.rawValue > 0 {
            return .child
        } else if rawValue & ProductsOptionsMask.sizePlus.rawValue > 0 {
            return .plus
        } else {
            return .adult
        }
    }
}

class _ProductsOptionsMask : NSObject {
    static func current() -> Int {
        return ProductsOptionsMask.global.rawValue
    }
}

@objc protocol ProductsOptionsDelegate : NSObjectProtocol {
    func productsOptionsDidComplete(_ productsOptions: ProductsOptions, withChange changed: Bool)
}

class ProductsOptions : NSObject {
    weak var delegate: ProductsOptionsDelegate?
    
    fileprivate(set) var gender = ProductsOptionsGender.globalValue
    fileprivate(set) var size = ProductsOptionsSize.globalValue
    fileprivate(set) var sale = ProductsOptionsSale.globalValue
    fileprivate(set) var sort = ProductsOptionsSort.globalValue
    
    fileprivate let sortItems: [ProductsOptionsSort] = [.similar, .priceAsc, .priceDes, .brands]
    
    private(set) lazy var view: ProductsOptionsView = {
        let view = ProductsOptionsView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.sortPickerView.dataSource = self
        view.sortPickerView.delegate = self
        view.doneButton.addTarget(self, action: #selector(doneButtonAction), for: .touchUpInside)
        self.syncOptions(withView: view)
        return view
    }()
    
    func syncOptions(withMask mask: ProductsOptionsMask? = nil) {
        gender = mask?.gender ?? ProductsOptionsGender.globalValue
        size = mask?.size ?? ProductsOptionsSize.globalValue
        sale = ProductsOptionsSale.globalValue
        sort = ProductsOptionsSort.globalValue
        
        syncOptions(withView: view)
    }
    
    private func syncOptions(withView view: ProductsOptionsView) {
        view.sortPickerView.selectRow(sort.offsetValue, inComponent: 0, animated: false)
        view.genderControl.selectedSegmentIndex = gender.offsetValue
        view.sizeControl.selectedSegmentIndex = size.offsetValue
        view.saleControl.selectedSegmentIndex = sale.offsetValue
    }
    
    @objc private func doneButtonAction() {
        let previousMask = ProductsOptionsMask(gender, size)
        let previousSale = sale
        let previousSort = sort
        
        gender = ProductsOptionsGender(offsetValue: view.genderControl.selectedSegmentIndex)
        size = ProductsOptionsSize(offsetValue: view.sizeControl.selectedSegmentIndex)
        sale = ProductsOptionsSale(offsetValue: view.saleControl.selectedSegmentIndex)
        sort = ProductsOptionsSort(offsetValue: view.sortPickerView.selectedRow(inComponent: 0))
        
        UserDefaults.standard.set(sale.rawValue, forKey: UserDefaultsKeys.productSale)
        UserDefaults.standard.set(sort.rawValue, forKey: UserDefaultsKeys.productSort)
        UserDefaults.standard.synchronize()
        
        let maskChanged = previousMask.rawValue != ProductsOptionsMask(gender, size).rawValue
        let saleChanged = previousSale.rawValue != sale.rawValue
        let sortChanged = previousSort.rawValue != sort.rawValue
        let changed = maskChanged || saleChanged || sortChanged
            
        delegate?.productsOptionsDidComplete(self, withChange: changed)
    }
}

extension ProductsOptions {
    
    // MARK: Objc
    
    func _gender() -> Int {
        return gender.rawValue
    }
    
    func _size() -> Int {
        return size.rawValue
    }
    
    func _sale() -> Int {
        return sale.rawValue
    }
    
    func _sort() -> Int {
        return sort.rawValue
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
        return sortItems[row].stringValue
    }
}

class ProductsOptionsView : UIView {
    let genderControl = UISegmentedControl(items: [
        ProductsOptionsGender.female.stringValue,
        ProductsOptionsGender.male.stringValue,
        ProductsOptionsGender.auto.stringValue
        ])
    let sizeControl = UISegmentedControl(items: [
        ProductsOptionsSize.child.stringValue,
        ProductsOptionsSize.adult.stringValue,
//        ProductsOptionsSize.plus.stringValue
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
        
        sizeControl.translatesAutoresizingMaskIntoConstraints = false
        sizeControl.tintColor = .crazeGreen
        addSubview(sizeControl)
        sizeControl.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        sizeControl.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        sizeControl.topAnchor.constraint(equalTo: genderControl.bottomAnchor, constant: .padding).isActive = true
        sizeControl.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        sizeControl.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        saleControl.translatesAutoresizingMaskIntoConstraints = false
        saleControl.tintColor = .crazeGreen
        addSubview(saleControl)
        saleControl.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        saleControl.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        saleControl.topAnchor.constraint(equalTo: sizeControl.bottomAnchor, constant: .padding).isActive = true
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Needed in iOS 10
        layoutMargins = UIEdgeInsets(top: .padding, left: .extendedPadding, bottom: .padding, right: .extendedPadding)
    }
    
    override var intrinsicContentSize: CGSize {
        return UILayoutFittingExpandedSize
    }
}

enum ProductsOptionsGender : Int, EnumIntDefaultProtocol, EnumIntOffsetProtocol {
    case female = 1
    case male
    case auto
    
    static let `default` = ProductsOptionsGender.female
    
    static var globalValue: ProductsOptionsGender {
        return ProductsOptionsGender(intValue: UserDefaults.standard.integer(forKey: UserDefaultsKeys.productGender))
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
        case .auto: string = "All"
        }
        
        return string
    }
}

class _ProductsOptionsGender : NSObject {
    static func toOffsetValue(_ value: Int) -> Int {
        return ProductsOptionsGender(offsetValue: value).rawValue
    }
    
    static func fromOffsetValue(_ value: Int) -> Int {
        return ProductsOptionsGender(intValue: value).offsetValue
    }
}

enum ProductsOptionsSize : Int, EnumIntDefaultProtocol, EnumIntOffsetProtocol {
    case child = 1
    case adult
    case plus
    
    static var `default` = ProductsOptionsSize.adult
    
    static var globalValue: ProductsOptionsSize {
        return ProductsOptionsSize(intValue: UserDefaults.standard.integer(forKey: UserDefaultsKeys.productSize))
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
    
    static var `default` = ProductsOptionsSale.all
    
    static var globalValue: ProductsOptionsSale {
        return ProductsOptionsSale(intValue: UserDefaults.standard.integer(forKey: UserDefaultsKeys.productSale))
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

enum ProductsOptionsSort : Int, EnumIntDefaultProtocol, EnumIntOffsetProtocol {
    case similar = 1
    case priceAsc
    case priceDes
    case brands
    
    static let `default` = ProductsOptionsSort.similar
    
    static var globalValue: ProductsOptionsSort {
        return ProductsOptionsSort(intValue: UserDefaults.standard.integer(forKey: UserDefaultsKeys.productSort))
    }
    
    init(intValue: Int) {
        self = ProductsOptionsSort(rawValue: intValue) ?? .default
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
        case .similar: string = "Similar"
        case .priceAsc: string = "Price (lowest first)"
        case .priceDes: string = "Price (highest first)"
        case .brands: string = "Brands"
        }
        
        return string
    }
}
