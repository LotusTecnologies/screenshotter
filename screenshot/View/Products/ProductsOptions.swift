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

protocol ProductsOptionsDelegate : NSObjectProtocol {
    func productsOptionsDidComplete(_ productsOptions: ProductsOptions, withChange changed: Bool)
    func productsOptionsDidCancel(_ productsOptions: ProductsOptions)
}

class ProductsOptions : NSObject {
    weak var delegate: ProductsOptionsDelegate?
    
    fileprivate(set) var category = ProductsOptionsCategory.globalValue // TODO: remove
    fileprivate(set) var gender = ProductsOptionsGender.globalValue
    fileprivate(set) var size = ProductsOptionsSize.globalValue
    fileprivate(set) var sale = ProductsOptionsSale.globalValue
    fileprivate(set) var sort = ProductsOptionsSort.globalValue
    
    fileprivate let sortItems: [ProductsOptionsSort] = [.similar, .priceAsc, .priceDes, .brands]
    
    private(set) lazy var viewController: ProductsOptionsViewController = {
        let viewController = ProductsOptionsViewController()
        viewController.continueButton.addTarget(self, action: #selector(continueAction), for: .touchUpInside)
        self.syncOptions(with: viewController)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cancelAction))
        viewController.view.addGestureRecognizer(tapGesture)
        
        return viewController
    }()
    
    func syncOptions(withMask mask: ProductsOptionsMask? = nil) {
        category = mask?.category ?? ProductsOptionsCategory.globalValue
        gender = mask?.gender ?? ProductsOptionsGender.globalValue
        size = mask?.size ?? ProductsOptionsSize.globalValue
        sale = ProductsOptionsSale.globalValue
        sort = ProductsOptionsSort.globalValue
        syncOptions(with: viewController)
    }
    
    private func syncOptions(with viewController: ProductsOptionsViewController) {
        viewController.genderControl.selectedSegmentIndex = gender.offsetValue
        viewController.sizeControl.selectedSegmentIndex = size.offsetValue
        viewController.saleControl.selectedSegmentIndex = sale.offsetValue
//        viewController.sortControl. // TODO:
//        view.sortPickerView.selectRow(sort.offsetValue, inComponent: 0, animated: false)
    }
    
    @objc private func continueAction() {
        let previousMask = ProductsOptionsMask(category, gender, size)
        let previousSale = sale
        let previousSort = sort
        
//        category = ProductsOptionsCategory(offsetValue: viewController.categoryControl.selectedSegmentIndex)
        gender = ProductsOptionsGender(offsetValue: viewController.genderControl.selectedSegmentIndex)
        size = ProductsOptionsSize(offsetValue: viewController.sizeControl.selectedSegmentIndex)
        sale = ProductsOptionsSale(offsetValue: viewController.saleControl.selectedSegmentIndex)
//        sort = ProductsOptionsSort(offsetValue: viewController.sortPickerView.selectedRow(inComponent: 0))
        
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
                    Analytics.trackSetFiler(name: name, newValue: value.new)
                }
            }
        }
    }
    
    @objc private func cancelAction() {
        delegate?.productsOptionsDidCancel(self)
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
    var sortControl: UIControl?
    
    private var gender: ProductsOptionsGender?
    private var size: ProductsOptionsSize?
    
    private class SegmentedControl : MainSegmentedControl {
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
    
    func createCategoryControl() -> UISegmentedControl { // TODO: remove
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
        let control = MainSegmentedControl(items: [
            ProductsOptionsSale.sale.stringValue,
            ProductsOptionsSale.all.stringValue
            ])
        
        saleControl?.removeFromSuperview()
        saleControl = control
        
        return control
    }
    
    func createSortControl(pickerViewAnimation: (()->())? = nil) -> UIControl {
        let segmentedTitleItem = SegmentedDropDownItem(titleItem: "products.options.sort.title".localized)
        segmentedTitleItem.widthRatio = 0.25
        
        let pickerItems = [
            ProductsOptionsSort.similar.stringValue,
            ProductsOptionsSort.priceAsc.stringValue,
            ProductsOptionsSort.priceDes.stringValue,
            ProductsOptionsSort.brands.stringValue
        ]
        let segmentedItem = SegmentedDropDownItem(pickerItems: pickerItems, selectedPickerItem: pickerItems.first)
        segmentedItem.isPickerViewInsertedInline = true
        segmentedItem.pickerViewAnimation = pickerViewAnimation
        
        let control = SegmentedDropDownControl()
        control.items = [segmentedTitleItem, segmentedItem]
        control.changeValueOnRowChange = true
        
        sortControl?.removeFromSuperview()
        sortControl = control
        
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

class ProductsOptionsViewController: UIViewController {
    private let transitioning = ViewControllerTransitioningDelegate(presentation: .dimmed, transition: .modal)
    private let controls = ProductsOptionsControls()

    private let containerView = UIView()
    private let titleLabel = UILabel()
    private(set) lazy var genderControl: UISegmentedControl = {
        return self.controls.createGenderControl()
    }()
    private(set) lazy var sizeControl: UISegmentedControl = {
        return self.controls.createSizeControl()
    }()
    private(set) lazy var saleControl: UISegmentedControl = {
        return self.controls.createSaleControl()
    }()
    private(set) lazy var sortControl: UIControl = {
        return self.controls.createSortControl(pickerViewAnimation: { [weak self] in
            self?.view.layoutIfNeeded()
        })
    }()
    let sortPickerView = UIPickerView()
    
    let continueButton = MainButton()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        transitioningDelegate = transitioning
        modalPresentationStyle = .custom
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let verticalPadding: CGFloat = .padding * 1.5
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .white
        containerView.layoutMargins = UIEdgeInsets(top: verticalPadding, left: .padding, bottom: verticalPadding, right: .padding)
        view.addSubview(containerView)
        containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .gray1
        titleLabel.text = "products.options.title".localized
        titleLabel.textAlignment = .center
        titleLabel.font = .screenshopFont(.quicksandBold, size: 16)
        containerView.addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: containerView.layoutMarginsGuide.topAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.layoutMarginsGuide.leadingAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.layoutMarginsGuide.trailingAnchor).isActive = true
        titleLabel.centerXAnchor.constraint(equalTo: containerView.layoutMarginsGuide.centerXAnchor).isActive = true
        
        sortControl.translatesAutoresizingMaskIntoConstraints = false
        sortControl.isExclusiveTouch = true
        sortControl.addTarget(self, action: #selector(optionsChangedAction), for: .valueChanged)
        containerView.addSubview(sortControl)
        sortControl.topAnchor.constraint(equalTo: titleLabel.lastBaselineAnchor, constant: verticalPadding).isActive = true
        sortControl.leadingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.leadingAnchor).isActive = true
        sortControl.trailingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        saleControl.translatesAutoresizingMaskIntoConstraints = false
        saleControl.isExclusiveTouch = true
        saleControl.addTarget(self, action: #selector(optionsChangedAction), for: .valueChanged)
        containerView.addSubview(saleControl)
        saleControl.topAnchor.constraint(equalTo: sortControl.bottomAnchor, constant: .padding).isActive = true
        saleControl.leadingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.leadingAnchor).isActive = true
        saleControl.trailingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        genderControl.translatesAutoresizingMaskIntoConstraints = false
        genderControl.isExclusiveTouch = true
        genderControl.addTarget(self, action: #selector(optionsChangedAction), for: .valueChanged)
        containerView.addSubview(genderControl)
        genderControl.topAnchor.constraint(equalTo: saleControl.bottomAnchor, constant: .padding).isActive = true
        genderControl.leadingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.leadingAnchor).isActive = true
        genderControl.trailingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        sizeControl.translatesAutoresizingMaskIntoConstraints = false
        sizeControl.isExclusiveTouch = true
        sizeControl.addTarget(self, action: #selector(optionsChangedAction), for: .valueChanged)
        containerView.addSubview(sizeControl)
        sizeControl.topAnchor.constraint(equalTo: genderControl.bottomAnchor, constant: .padding).isActive = true
        sizeControl.leadingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.leadingAnchor).isActive = true
        sizeControl.trailingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.backgroundColor = .crazeGreen
        continueButton.setTitle("generic.close".localized, for: .normal)
        continueButton.layer.cornerRadius = 0
        continueButton.layer.shadowOpacity = 0
        containerView.addSubview(continueButton)
        continueButton.topAnchor.constraint(equalTo: sizeControl.bottomAnchor, constant: verticalPadding).isActive = true
        continueButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        continueButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        continueButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        controls.sync()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        continueButton.setTitle("generic.close".localized, for: .normal)
    }
    
    @objc private func optionsChangedAction() {
        continueButton.setTitle("generic.save".localized, for: .normal)
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
    var analyticsStringValue:String {
        switch self {
        case .fashion: return "fashion";
        case .furniture: return "furniture";
        case .auto: return "auto";
        }
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
    var analyticsStringValue:String {
        switch self {
        case .female: return "female";
        case .male: return "male";
        case .auto: return "auto";
        }
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
    var analyticsStringValue:String {
        switch self {
        case .child: return "child"
        case .adult: return "adult"
        case .plus: return "plus"
        }
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
