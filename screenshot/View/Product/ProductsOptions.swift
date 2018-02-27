//
//  ProductsOptions.swift
//  screenshot
//
//  Created by Corey Werner on 11/21/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation
import UIKit

class ProductsOptionsMask : NSObject {
    let rawValue: Int
    
    static let genderAuto   = ProductsOptionsMask(rawValue: 1 << 0) // 1
    static let genderMale   = ProductsOptionsMask(rawValue: 1 << 1) // 2
    static let genderFemale = ProductsOptionsMask(rawValue: 1 << 2) // 4
    
    static let sizeAdult    = ProductsOptionsMask(rawValue: 1 << 3) // 8
    static let sizeChild    = ProductsOptionsMask(rawValue: 1 << 4) // 16
    static let sizePlus     = ProductsOptionsMask(rawValue: 1 << 5) // 32
    
    static let categoryAuto      = ProductsOptionsMask(rawValue: 1 << 6) // 64
    static let categoryFashion   = ProductsOptionsMask(rawValue: 1 << 7) // 128
    static let categoryFurniture = ProductsOptionsMask(rawValue: 1 << 8) // 256
    
    static var global: ProductsOptionsMask {
        return ProductsOptionsMask(ProductsOptionsCategory.globalValue, ProductsOptionsGender.globalValue, ProductsOptionsSize.globalValue)
    }
    
    init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    convenience init(_ category: ProductsOptionsCategory, _ gender: ProductsOptionsGender, _ size: ProductsOptionsSize) {
        var value: Int = 0
        
        switch category {
        case .fashion:
            value |= ProductsOptionsMask.categoryFashion.rawValue
        case .furniture:
            value |= ProductsOptionsMask.categoryFurniture.rawValue
        default:
            value |= ProductsOptionsMask.categoryAuto.rawValue
        }
        
        switch gender {
        case .male:
            value |= ProductsOptionsMask.genderMale.rawValue
        case .female:
            value |= ProductsOptionsMask.genderFemale.rawValue
        default:
            value |= ProductsOptionsMask.genderAuto.rawValue
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
    
    var category: ProductsOptionsCategory {
        if rawValue & ProductsOptionsMask.categoryFashion.rawValue > 0 {
            return .fashion
        } else if rawValue & ProductsOptionsMask.categoryFurniture.rawValue > 0 {
            return .furniture
        } else {
            return .auto
        }
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

protocol ProductsOptionsDelegate : NSObjectProtocol {
    func productsOptionsDidComplete(_ productsOptions: ProductsOptions, withChange changed: Bool)
}

class ProductsOptions : NSObject {
    weak var delegate: ProductsOptionsDelegate?
    
    fileprivate(set) var category = ProductsOptionsCategory.globalValue
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
        category = mask?.category ?? ProductsOptionsCategory.globalValue
        gender = mask?.gender ?? ProductsOptionsGender.globalValue
        size = mask?.size ?? ProductsOptionsSize.globalValue
        sale = ProductsOptionsSale.globalValue
        sort = ProductsOptionsSort.globalValue
        
        syncOptions(withView: view)
    }
    
    private func syncOptions(withView view: ProductsOptionsView) {
        view.categoryControl.selectedSegmentIndex = category.offsetValue
        view.genderControl.selectedSegmentIndex = gender.offsetValue
        view.sizeControl.selectedSegmentIndex = size.offsetValue
        view.saleControl.selectedSegmentIndex = sale.offsetValue
        view.sortPickerView.selectRow(sort.offsetValue, inComponent: 0, animated: false)
    }
    
    @objc private func doneButtonAction() {
        let previousMask = ProductsOptionsMask(category, gender, size)
        let previousSale = sale
        let previousSort = sort
        
        category = ProductsOptionsCategory(offsetValue: view.categoryControl.selectedSegmentIndex)
        gender = ProductsOptionsGender(offsetValue: view.genderControl.selectedSegmentIndex)
        size = ProductsOptionsSize(offsetValue: view.sizeControl.selectedSegmentIndex)
        sale = ProductsOptionsSale(offsetValue: view.saleControl.selectedSegmentIndex)
        sort = ProductsOptionsSort(offsetValue: view.sortPickerView.selectedRow(inComponent: 0))
        
        UserDefaults.standard.set(sale.rawValue, forKey: UserDefaultsKeys.productSale)
        UserDefaults.standard.set(sort.rawValue, forKey: UserDefaultsKeys.productSort)
        UserDefaults.standard.synchronize()
        
        let maskChanged = previousMask.rawValue != ProductsOptionsMask(category, gender, size).rawValue
        let saleChanged = previousSale.rawValue != sale.rawValue
        let sortChanged = previousSort.rawValue != sort.rawValue
        let changed = maskChanged || saleChanged || sortChanged
        
        delegate?.productsOptionsDidComplete(self, withChange: changed)
        
        if changed {
            let changeMap = [
                "Category": (new: category.stringValue, old: previousMask.category.stringValue),
                "Gender": (new: gender.stringValue, old: previousMask.gender.stringValue),
                "Size": (new: size.stringValue, old: previousMask.size.stringValue),
                "Sale": (new: sale.stringValue, old: previousSale.stringValue),
                "Sort": (new: sort.stringValue, old: previousSort.stringValue)
            ]
            
            for (name, value) in changeMap {
                if value.new != value.old {
                    AnalyticsTrackers.standard.track("Set \(name) Filter to \(value.new)")
                }
            }
        }
    }
}

extension ProductsOptions {
    // MARK: Objc
    
    func _category() -> Int {
        return category.rawValue
    }
    
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

class ProductsOptionsControls : NSObject {
    var categoryControl: UISegmentedControl?
    var genderControl: UISegmentedControl?
    var sizeControl: UISegmentedControl?
    var saleControl: UISegmentedControl?
    
    private var gender: ProductsOptionsGender?
    private var size: ProductsOptionsSize?
    
    private class SegmentedControl : UISegmentedControl {
        private var needsSelectedIndexUpdate = true
        var didUpdateSelectedIndex: (() -> ())?
        
        override func setEnabled(_ enabled: Bool, forSegmentAt segment: Int) {
            needsSelectedIndexUpdate = false
            super.setEnabled(enabled, forSegmentAt: segment)
            needsSelectedIndexUpdate = true
        }
        
        override var selectedSegmentIndex: Int {
            didSet {
                if needsSelectedIndexUpdate {
                    didUpdateSelectedIndex?()
                }
            }
        }
    }
    
    func createCategoryControl() -> UISegmentedControl {
        let control = UISegmentedControl(items: [
            ProductsOptionsCategory.fashion.stringValue,
            ProductsOptionsCategory.furniture.stringValue,
            ProductsOptionsCategory.auto.stringValue
            ])
        control.addTarget(self, action: #selector(syncCategoryControl), for: .valueChanged)
        
        categoryControl?.removeFromSuperview()
        categoryControl = control
        
        return control
    }
    
    func createGenderControl() -> UISegmentedControl {
        let control = SegmentedControl(items: [
            ProductsOptionsGender.female.stringValue,
            ProductsOptionsGender.male.stringValue,
            ProductsOptionsGender.auto.stringValue
            ])
        control.addTarget(self, action: #selector(syncGenderControl), for: .valueChanged)
        control.didUpdateSelectedIndex = {
            self.gender = ProductsOptionsGender(offsetValue: control.selectedSegmentIndex)
        }
        
        genderControl?.removeFromSuperview()
        genderControl = control
        
        return control
    }
    
    func createSizeControl() -> UISegmentedControl {
        let control = SegmentedControl(items: [
            ProductsOptionsSize.child.stringValue,
            ProductsOptionsSize.adult.stringValue,
            ProductsOptionsSize.plus.stringValue
            ])
        control.addTarget(self, action: #selector(syncSizeControl), for: .valueChanged)
        control.didUpdateSelectedIndex = {
            self.size = ProductsOptionsSize(offsetValue: control.selectedSegmentIndex)
        }
        
        sizeControl?.removeFromSuperview()
        sizeControl = control
        
        return control
    }
    
    func createSaleControl() -> UISegmentedControl {
        let control = UISegmentedControl(items: [
            ProductsOptionsSale.sale.stringValue,
            ProductsOptionsSale.all.stringValue
            ])
        
        saleControl?.removeFromSuperview()
        saleControl = control
        
        return control
    }
    
    private var enabledControls: [UIControl : [Int : Bool]] {
        var enabledControls: [UIControl : [Int : Bool]] = [:]
        
        if let genderControl = genderControl, let sizeControl = sizeControl {
            let isFashion: Bool
            
            if let categoryControl = categoryControl {
                isFashion = ProductsOptionsCategory(offsetValue: categoryControl.selectedSegmentIndex) != .furniture
                
            } else {
                isFashion = ProductsOptionsCategory.default != .furniture
            }
            
            enabledControls[genderControl] = [:]
            
            for i in 0 ..< genderControl.numberOfSegments {
                var isEnabled = true
                
                if i == ProductsOptionsGender.male.offsetValue {
                    isEnabled = ProductsOptionsSize(offsetValue: sizeControl.selectedSegmentIndex) != .plus
                }
                
                enabledControls[genderControl]?[i] = isFashion ? isEnabled : false
            }
            
            enabledControls[sizeControl] = [:]
            
            for i in 0 ..< sizeControl.numberOfSegments {
                var isEnabled = true
                
                if i == ProductsOptionsSize.plus.offsetValue {
                    isEnabled = ProductsOptionsGender(offsetValue: genderControl.selectedSegmentIndex) != .male
                }
                
                enabledControls[sizeControl]?[i] = isFashion ? isEnabled : false
            }
        }
        
        return enabledControls
    }
    
    func sync() {
        guard let genderControl = genderControl, let sizeControl = sizeControl else {
            return
        }
        
        let enabledControls = self.enabledControls
        
        for index in 0 ..< genderControl.numberOfSegments {
            let isEnabled = enabledControls[genderControl]?[index] ?? true
            genderControl.setEnabled(isEnabled, forSegmentAt: index)
        }
        
        for index in 0 ..< sizeControl.numberOfSegments {
            let isEnabled = enabledControls[sizeControl]?[index] ?? true
            sizeControl.setEnabled(isEnabled, forSegmentAt: index)
        }
    }
    
    @objc private func syncCategoryControl() {
        guard let categoryControl = categoryControl else {
            return
        }
        
        if ProductsOptionsCategory(offsetValue: categoryControl.selectedSegmentIndex) != .furniture {
            if let genderControl = genderControl, let gender = gender {
                genderControl.selectedSegmentIndex = gender.offsetValue
            }
            
            if let sizeControl = sizeControl, let size = size {
                sizeControl.selectedSegmentIndex = size.offsetValue
            }
        }
        
        sync()
    }
    
    @objc private func syncGenderControl() {
        guard let genderControl = genderControl, let sizeControl = sizeControl else {
            return
        }
        
        gender = ProductsOptionsGender(offsetValue: genderControl.selectedSegmentIndex)
        
        let index = ProductsOptionsSize.plus.offsetValue
        let isEnabled = enabledControls[sizeControl]?[index] ?? true
        sizeControl.setEnabled(isEnabled, forSegmentAt: index)
    }
    
    @objc private func syncSizeControl() {
        guard let genderControl = genderControl, let sizeControl = sizeControl else {
            return
        }
        
        size = ProductsOptionsSize(offsetValue: sizeControl.selectedSegmentIndex)
        
        let index = ProductsOptionsGender.male.offsetValue
        let isEnabled = enabledControls[genderControl]?[index] ?? true
        genderControl.setEnabled(isEnabled, forSegmentAt: index)
    }
}

class ProductsOptionsView : UIView {
    fileprivate let controls = ProductsOptionsControls()
    
    private(set) var categoryControl: UISegmentedControl!
    private(set) var genderControl: UISegmentedControl!
    private(set) var sizeControl: UISegmentedControl!
    private(set) var saleControl: UISegmentedControl!
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
        
        categoryControl = controls.createCategoryControl()
        categoryControl.translatesAutoresizingMaskIntoConstraints = false
        categoryControl.tintColor = .crazeGreen
        categoryControl.isExclusiveTouch = true
        addSubview(categoryControl)
        categoryControl.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        categoryControl.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        categoryControl.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        categoryControl.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        categoryControl.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        genderControl = controls.createGenderControl()
        genderControl.translatesAutoresizingMaskIntoConstraints = false
        genderControl.tintColor = .crazeGreen
        genderControl.isExclusiveTouch = true
        addSubview(genderControl)
        genderControl.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        genderControl.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        genderControl.topAnchor.constraint(equalTo: categoryControl.bottomAnchor, constant: .padding).isActive = true
        genderControl.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        genderControl.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        sizeControl = controls.createSizeControl()
        sizeControl.translatesAutoresizingMaskIntoConstraints = false
        sizeControl.tintColor = .crazeGreen
        sizeControl.isExclusiveTouch = true
        addSubview(sizeControl)
        sizeControl.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        sizeControl.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        sizeControl.topAnchor.constraint(equalTo: genderControl.bottomAnchor, constant: .padding).isActive = true
        sizeControl.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        sizeControl.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        saleControl = controls.createSaleControl()
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
        sortLabel.text = "products.options.sort.title".localized
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
        doneButton.setTitle("generic.done".localized, for: .normal)
        addSubview(doneButton)
        doneButton.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        doneButton.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        doneButton.topAnchor.constraint(equalTo: sortPickerView.bottomAnchor, constant: .padding).isActive = true
        doneButton.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        doneButton.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
        doneButton.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    }
    
    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        
        controls.sync()
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

enum ProductsOptionsCategory : Int, EnumIntDefaultProtocol, EnumIntOffsetProtocol {
    case fashion = 1
    case furniture
    case auto
    
    static let `default` = ProductsOptionsCategory.auto
    
    static var globalValue: ProductsOptionsCategory {
        return ProductsOptionsCategory(intValue: UserDefaults.standard.integer(forKey: UserDefaultsKeys.productCategory))
    }
    
    init(intValue: Int) {
        self = ProductsOptionsCategory(rawValue: intValue) ?? .default
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
        case .fashion: string = "products.options.category.fashion".localized
        case .furniture: string = "products.options.category.furniture".localized
        case .auto: string = "products.options.category.auto".localized
        }
        
        return string
    }
}

enum ProductsOptionsGender : Int, EnumIntDefaultProtocol, EnumIntOffsetProtocol {
    case female = 1
    case male
    case auto
    
    static let `default` = ProductsOptionsGender.auto
    
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
        case .female: string = "products.options.gender.female".localized
        case .male: string = "products.options.gender.male".localized
        case .auto: string = "products.options.gender.auto".localized
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
        case .child: string = "products.options.size.child".localized
        case .adult: string = "products.options.size.adult".localized
        case .plus: string = "products.options.size.plus".localized
        }
        
        return string
    }
}

class _ProductsOptionsSize : NSObject {
    static func toOffsetValue(_ value: Int) -> Int {
        return ProductsOptionsSize(offsetValue: value).rawValue
    }
    
    static func fromOffsetValue(_ value: Int) -> Int {
        return ProductsOptionsSize(intValue: value).offsetValue
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
        case .sale: string = "products.options.sale.only".localized
        case .all: string = "products.options.sale.all".localized
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
        case .similar: string = "products.options.sort.similar".localized
        case .priceAsc: string = "products.options.sort.price_asc".localized
        case .priceDes: string = "products.options.sort.price_des".localized
        case .brands: string = "products.options.sort.brand".localized
        }
        
        return string
    }
}
