//
//  ProductsOptions.swift
//  screenshot
//
//  Created by Corey Werner on 11/21/17.
//  Copyright (c) 2017 crazeapp. All rights reserved.
//

import UIKit

class ProductsOptionsMask : NSObject {
    let rawValue: Int
    
    static let genderAuto   = ProductsOptionsMask(rawValue: 1 << 0) // 1
    static let genderMale   = ProductsOptionsMask(rawValue: 1 << 1) // 2
    static let genderFemale = ProductsOptionsMask(rawValue: 1 << 2) // 4
    
    static let sizeAdult    = ProductsOptionsMask(rawValue: 1 << 3) // 8
    static let sizeChild    = ProductsOptionsMask(rawValue: 1 << 4) // 16
    static let sizePlus     = ProductsOptionsMask(rawValue: 1 << 5) // 32
    
    // Category historical values. No longer used.
    static let categoryAuto      = ProductsOptionsMask(rawValue: 1 << 6) // 64
    static let categoryFashion   = ProductsOptionsMask(rawValue: 1 << 7) // 128
    static let categoryFurniture = ProductsOptionsMask(rawValue: 1 << 8) // 256
    
    static var global: ProductsOptionsMask {
        return ProductsOptionsMask(ProductsOptionsGender.globalValue, ProductsOptionsSize.globalValue)
    }
    
    init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    convenience init(_ gender: ProductsOptionsGender, _ size: ProductsOptionsSize) {
        var value: Int = 0
        
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

enum ProductsProvider {
    case syte
    case amazon
}

protocol ProductsOptionsDelegate : NSObjectProtocol {
    func productsOptionsDidComplete(_ productsOptions: ProductsOptions, withModelChange changed: Bool)
    func productsOptionsDidCancel(_ productsOptions: ProductsOptions)
}

class ProductsOptions : NSObject {
    let provider: ProductsProvider
    
    weak var delegate: ProductsOptionsDelegate?
    
    fileprivate(set) var gender = ProductsOptionsGender.globalValue
    fileprivate(set) var size = ProductsOptionsSize.globalValue
    fileprivate(set) var sale = ProductsOptionsSale.globalValue
    fileprivate(set) var sort = ProductsOptionsSort.globalValue
    
    init(provider: ProductsProvider = .syte) {
        self.provider = provider
    }
    
    private(set) lazy var viewController: ProductsOptionsViewController = {
        let viewController = ProductsOptionsViewController(provider: provider)
        viewController.dismissalControl.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)
        viewController.continueButton.addTarget(self, action: #selector(continueAction), for: .touchUpInside)
        self.syncOptions(with: viewController)
        return viewController
    }()
    
    func syncOptions(withMask mask: ProductsOptionsMask? = nil) {
        gender = mask?.gender ?? ProductsOptionsGender.globalValue
        size = mask?.size ?? ProductsOptionsSize.globalValue
        sale = ProductsOptionsSale.globalValue
        sort = ProductsOptionsSort.globalValue
        syncOptions(with: viewController)
    }
    
    private func syncOptions(with viewController: ProductsOptionsViewController) {
        viewController.genderControl.selectedSegmentIndex = gender.offsetValue
        viewController.sizeControl.selectedSegmentIndex = size.offsetValue
        viewController.sortControl.items.last?.title = sort.stringValue
        
        switch provider {
        case .syte:
            viewController.saleControl.selectedSegmentIndex = sale.offsetValue
        case .amazon:
            break
        }
    }
    
    @objc private func continueAction() {
        let previousMask = ProductsOptionsMask(gender, size)
        let previousSale = sale
        let previousSort = sort
        
        gender = ProductsOptionsGender(offsetValue: viewController.genderControl.selectedSegmentIndex)
        size = ProductsOptionsSize(offsetValue: viewController.sizeControl.selectedSegmentIndex)
        if let sortPickerView = viewController.sortPickerView {
            let selectedIndex = sortPickerView.selectedRow(inComponent: 0)
            sort = ProductsOptionsSort.options(provider)[selectedIndex]
        }
        
        if provider == .syte {
            sale = ProductsOptionsSale(offsetValue: viewController.saleControl.selectedSegmentIndex)
        }
        
        UserDefaults.standard.set(sale.rawValue, forKey: UserDefaultsKeys.productSale)
        UserDefaults.standard.set(sort.rawValue, forKey: UserDefaultsKeys.productSort)
        UserDefaults.standard.synchronize()
        
        let changed = previousMask.rawValue != ProductsOptionsMask(gender, size).rawValue
        
        delegate?.productsOptionsDidComplete(self, withModelChange: changed)
        
        if changed {
            let changeMap = [
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
        self.syncOptions()
        delegate?.productsOptionsDidCancel(self)
    }
}

class ProductsOptionsControls : NSObject {
    let provider: ProductsProvider
    
    var categoryControl: UISegmentedControl?
    var genderControl: UISegmentedControl?
    var sizeControl: UISegmentedControl?
    var saleControl: UISegmentedControl?
    var sortControl: UIControl?
    var sortPickerView: UIPickerView?
    
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
    
    init(provider: ProductsProvider) {
        self.provider = provider
    }
    
    func createGenderControl() -> UISegmentedControl {
        let control = SegmentedControl(items: ProductsOptionsGender.options.map({ $0.stringValue }))
        control.addTarget(self, action: #selector(syncGenderControl), for: .valueChanged)
        control.didUpdateSelectedIndex = {
            self.gender = ProductsOptionsGender(offsetValue: control.selectedSegmentIndex)
        }
        
        genderControl?.removeFromSuperview()
        genderControl = control
        
        return control
    }
    
    func createSizeControl() -> UISegmentedControl {
        let control = SegmentedControl(items: ProductsOptionsSize.options(provider).map({ $0.stringValue }))
        control.addTarget(self, action: #selector(syncSizeControl), for: .valueChanged)
        control.didUpdateSelectedIndex = {
            self.size = ProductsOptionsSize(offsetValue: control.selectedSegmentIndex)
        }
        
        sizeControl?.removeFromSuperview()
        sizeControl = control
        
        return control
    }
    
    func createSaleControl() -> UISegmentedControl {
        let control = MainSegmentedControl(items: ProductsOptionsSale.options.map({ $0.stringValue }))
        
        saleControl?.removeFromSuperview()
        saleControl = control
        
        return control
    }
    
    func createSortControl(pickerViewAnimation: (()->())? = nil) -> SegmentedDropDownControl {
        let segmentedTitleItem = SegmentedDropDownItem(titleItem: "products.options.sort.title".localized)
        segmentedTitleItem.widthRatio = 0.25
        
        let pickerItems = ProductsOptionsSort.options(provider).map{ $0.stringValue }
        let segmentedItem = SegmentedDropDownItem(pickerItems: pickerItems, selectedPickerItem: pickerItems.first)
        segmentedItem.isPickerViewInsertedInline = true
        segmentedItem.pickerViewAnimation = pickerViewAnimation
        
        let control = SegmentedDropDownControl()
        control.items = [segmentedTitleItem, segmentedItem]
        control.changeValueOnRowChange = true
        
        sortControl?.removeFromSuperview()
        sortControl = control
        sortPickerView = segmentedItem.pickerView
        
        return control
    }
    
    private var enabledControls: [UIControl : [Int : Bool]] {
        var enabledControls: [UIControl : [Int : Bool]] = [:]
        
        if let genderControl = genderControl, let sizeControl = sizeControl {
            enabledControls[genderControl] = [:]
            
            for i in 0 ..< genderControl.numberOfSegments {
                var isEnabled = true
                
                if i == ProductsOptionsGender.male.offsetValue {
                    isEnabled = ProductsOptionsSize(offsetValue: sizeControl.selectedSegmentIndex) != .plus
                }
                
                enabledControls[genderControl]?[i] = isEnabled
            }
            
            enabledControls[sizeControl] = [:]
            
            for i in 0 ..< sizeControl.numberOfSegments {
                var isEnabled = true
                
                if i == ProductsOptionsSize.plus.offsetValue {
                    isEnabled = ProductsOptionsGender(offsetValue: genderControl.selectedSegmentIndex) != .male
                }
                
                enabledControls[sizeControl]?[i] = isEnabled
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
    
    @objc private func syncGenderControl() {
        guard let genderControl = genderControl else {
            return
        }
        
        gender = ProductsOptionsGender(offsetValue: genderControl.selectedSegmentIndex)
        
        guard provider == .syte, let sizeControl = sizeControl else {
            return
        }
        
        let index = ProductsOptionsSize.plus.offsetValue
        let isEnabled = enabledControls[sizeControl]?[index] ?? true
        sizeControl.setEnabled(isEnabled, forSegmentAt: index)
    }
    
    @objc private func syncSizeControl() {
        guard let sizeControl = sizeControl else {
            return
        }
        
        size = ProductsOptionsSize(offsetValue: sizeControl.selectedSegmentIndex)
        
        guard provider == .syte, let genderControl = genderControl else {
            return
        }
        
        let index = ProductsOptionsGender.male.offsetValue
        let isEnabled = enabledControls[genderControl]?[index] ?? true
        genderControl.setEnabled(isEnabled, forSegmentAt: index)
    }
}

class ProductsOptionsViewController: UIViewController {
    let provider: ProductsProvider
    
    private let transitioning = ViewControllerTransitioningDelegate(presentation: .dimmed, transition: .modal)
    private let controls: ProductsOptionsControls
    
    fileprivate let dismissalControl = UIControl()
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
    private(set) lazy var sortControl: SegmentedDropDownControl = {
        return self.controls.createSortControl(pickerViewAnimation: { [weak self] in
            self?.view.layoutIfNeeded()
        })
    }()
    
    var sortPickerView: UIPickerView? {
        return self.controls.sortPickerView
    }

    let continueButton = MainButton()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(provider: ProductsProvider) {
        self.provider = provider
        controls = ProductsOptionsControls(provider: provider)
        
        super.init(nibName: nil, bundle: nil)
        
        transitioningDelegate = transitioning
        modalPresentationStyle = .custom
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dismissalControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dismissalControl)
        dismissalControl.setContentHuggingPriority(.defaultLow, for: .vertical)
        dismissalControl.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        dismissalControl.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        dismissalControl.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        let verticalPadding: CGFloat = .padding * 1.5
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .white
        containerView.layoutMargins = UIEdgeInsets(top: verticalPadding, left: .padding, bottom: verticalPadding, right: .padding)
        view.addSubview(containerView)
        containerView.topAnchor.constraint(equalTo: dismissalControl.bottomAnchor).isActive = true
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
        
        var genderControlTopView: UIView = sortControl
        
        if provider == .syte {
            genderControlTopView = saleControl
            
            saleControl.translatesAutoresizingMaskIntoConstraints = false
            saleControl.isExclusiveTouch = true
            saleControl.addTarget(self, action: #selector(optionsChangedAction), for: .valueChanged)
            containerView.addSubview(saleControl)
            saleControl.topAnchor.constraint(equalTo: sortControl.bottomAnchor, constant: .padding).isActive = true
            saleControl.leadingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.leadingAnchor).isActive = true
            saleControl.trailingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.trailingAnchor).isActive = true
        }
        
        genderControl.translatesAutoresizingMaskIntoConstraints = false
        genderControl.isExclusiveTouch = true
        genderControl.addTarget(self, action: #selector(optionsChangedAction), for: .valueChanged)
        containerView.addSubview(genderControl)
        genderControl.topAnchor.constraint(equalTo: genderControlTopView.bottomAnchor, constant: .padding).isActive = true
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
        continueButton.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor).isActive = true
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

enum ProductsOptionsGender : Int, EnumIntDefaultProtocol, EnumIntOffsetProtocol {
    case female = 1
    case male
    case auto
    
    static let `default` = ProductsOptionsGender.auto
    
    static var globalValue: ProductsOptionsGender {
        return .auto
    }
    
    static let options: [ProductsOptionsGender] = [
        .female,
        .male,
        .auto
    ]
    
    init?(stringValue: String) {
        if let option = ProductsOptionsGender.options.first(where: { $0.stringValue == stringValue }) {
            self = option
        }
        return nil
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
        switch self {
        case .female: return "products.options.gender.female".localized
        case .male: return "products.options.gender.male".localized
        case .auto: return "products.options.gender.auto".localized
        }
    }
    
    var analyticsStringValue: String {
        switch self {
        case .female: return "female"
        case .male: return "male"
        case .auto: return "auto"
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
    
    static let options: [ProductsOptionsSize] = [
        .child,
        .adult,
        .plus
    ]
    
    static func options(_ provider: ProductsProvider) -> [ProductsOptionsSize] {
        switch provider {
        case .syte: return [
            .child,
            .adult,
            .plus
            ]
        case .amazon: return [
            .child,
            .adult
            ]
        }
    }
    
    init?(stringValue: String) {
        if let option = ProductsOptionsSize.options.first(where: { $0.stringValue == stringValue }) {
            self = option
        }
        return nil
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
        switch self {
        case .child: return "products.options.size.child".localized
        case .adult: return "products.options.size.adult".localized
        case .plus: return "products.options.size.plus".localized
        }
    }
    
    var analyticsStringValue: String {
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
    
    static let options: [ProductsOptionsSale] = [
        .sale,
        .all
    ]
    
    init?(stringValue: String) {
        if let option = ProductsOptionsSale.options.first(where: { $0.stringValue == stringValue }) {
            self = option
        }
        return nil
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
        switch self {
        case .sale: return "products.options.sale.only".localized
        case .all: return "products.options.sale.all".localized
        }
    }
}

enum ProductsOptionsSort: Int, EnumIntDefaultProtocol, EnumIntOffsetProtocol {
    case similar = 1
    case priceAsc
    case priceDes
    // Syte Only
    case brands
    // Amazon Only
    case review
    case popularity
    
    static let `default` = ProductsOptionsSort.similar
    
    static var globalValue: ProductsOptionsSort {
        return ProductsOptionsSort(intValue: UserDefaults.standard.integer(forKey: UserDefaultsKeys.productSort))
    }
    
    static let options: [ProductsOptionsSort] = [
        .similar,
        .priceAsc,
        .priceDes,
        .brands,
        .review,
        .popularity
    ]
    
    static func options(_ provider: ProductsProvider) -> [ProductsOptionsSort] {
        switch provider {
        case .syte: return [
            .similar,
            .priceAsc,
            .priceDes,
            .brands
            ]
        case .amazon: return [
            .similar,
            .priceAsc,
            .priceDes,
            .review,
            .popularity
            ]
        }
    }
    
    init?(stringValue: String) {
        if let option = ProductsOptionsSort.options.first(where: { $0.stringValue == stringValue }) {
            self = option
        }
        return nil
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
        switch self {
        case .similar: return "products.options.sort.similar".localized
        case .priceAsc: return "products.options.sort.price_asc".localized
        case .priceDes: return "products.options.sort.price_des".localized
        case .brands: return "products.options.sort.brand".localized
        case .review: return "Reviews".localized
        case .popularity: return "Popularity".localized
        }
    }
    
    var amazonKey: String {
        switch self {
        case .similar: return "relevancerank"
        case .priceAsc: return "price"
        case .priceDes: return "-price"
        case .review: return "reviewrank"
        case .popularity: return "popularity-rank"
        default: return ""
        }
    }
}
