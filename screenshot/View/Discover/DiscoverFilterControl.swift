//
//  DiscoverFilterControl.swift
//  Screenshop
//
//  Created by Jonathan Rose on 8/16/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit



class DiscoverFilterControl: UIControl {
    class DiscoverFilterButton: UIButton {
        init(tagCategory:TagCategory){
            self.tagCategory = tagCategory
            super.init(frame: .zero)
            self.color = tagCategory.color
            self.setTitle(tagCategory.displayName, for: .normal)
            syncColor()
            self.clipsToBounds = true
            self.layer.cornerRadius = DiscoverFilterControl.defaultHeight / 2.0
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func syncColor(){
            self.layer.borderWidth = 1.0
            self.layer.borderColor = color.cgColor
            self.setTitleColor(color, for: .normal)
            let whiteImage = UIImage.init(color: .white)
            self.setBackgroundImage(whiteImage, for: .normal)
            let lightGrayImage = UIImage.init(color: .lightGray)
            self.setTitleColor(color.darker(), for: .highlighted)
            self.setBackgroundImage(lightGrayImage, for: .highlighted)
            
            
            self.setTitleColor(.white, for: .selected)
            let colorImage = UIImage.init(color: color)
            self.setBackgroundImage(colorImage, for: .selected)
            let darkerColorImage = UIImage.init(color: color.darker())
            self.setBackgroundImage(darkerColorImage, for: [.selected, .highlighted])
            self.setTitleColor(.white, for: [.selected, .highlighted])

        }
        var color:UIColor = .black {
            didSet{
                syncColor()
            }
            
        }
        let tagCategory:TagCategory
    }
    
    static let defaultHeight:CGFloat = 36.0
    struct TagCategory : Equatable{
        var displayName:String
        var filterName:String
        var color:UIColor
        var isAll:Bool
        static func getFromFile() -> [TagCategory] {
            func parse(data:Data) -> [TagCategory] {
                var toReturn:[TagCategory] = []
                if let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [[String:Any]] {
                    if let json = json {
                        for dict in json {
                            if let displayName = dict["displayName"] as? String,
                                let filterName = dict["filterName"] as? String,
                                let colorString = dict["color"] as? String,
                                let isAll = dict["isAll"] as? Bool {
                                let color = UIColor.init(hex: colorString)
                                toReturn.append(TagCategory.init(displayName: displayName, filterName: filterName, color: color, isAll: isAll))
                            }
                        }
                    }
                    
                }
                return toReturn
            }
            if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let dbURL = documentDirectory.appendingPathComponent("DiscoverFilterCategories.json")
                
                if let data = try? Data.init(contentsOf: dbURL) {
                    return parse(data: data)
                }
            }
            if let bundleUrl = Bundle.main.url(forResource: "DiscoverFilterCategories", withExtension: "json"), let data = try? Data.init(contentsOf: bundleUrl) {
                return parse(data: data)
            }
            return []
        }
        public static func == (lhs: DiscoverFilterControl.TagCategory, rhs: DiscoverFilterControl.TagCategory) -> Bool {
            return lhs.filterName == rhs.filterName
        }

    }
    var allTagCategories:[TagCategory] = {
        return TagCategory.getFromFile()
    }()
    lazy var selectedCategory:TagCategory = {
        if let categoryString = UserDefaults.standard.string(forKey: UserDefaultsKeys.discoverCategoryFilter) {
            for t in self.allTagCategories {
                if t.filterName == categoryString {
                    return t
                }
            }
        }
        for t in self.allTagCategories {
            if t.isAll {
                return t
            }
        }
        
        if let t =  self.allTagCategories.first{
            return t
        }
        return TagCategory.init(displayName: "All", filterName: "", color: UIColor.init(hex: "E62A41"), isAll: true)
        
    }()
    private let scrollView = UIScrollView()
    private let containterView = UIView()
    
    private var buttons:[DiscoverFilterButton] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(scrollView)
        scrollView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        
        containterView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(containterView)
        containterView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        containterView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        containterView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        containterView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
        
        var lastAnchor = containterView.leadingAnchor
        for t in self.allTagCategories {
            let b = DiscoverFilterButton.init(tagCategory:t)
            b.translatesAutoresizingMaskIntoConstraints = false
            containterView.addSubview(b)
            b.leadingAnchor.constraint(equalTo: lastAnchor, constant:.padding).isActive = true
            b.topAnchor.constraint(equalTo: containterView.topAnchor).isActive = true
            b.bottomAnchor.constraint(equalTo: containterView.bottomAnchor).isActive = true
            b.contentEdgeInsets = .init(top: 2.0, left: .padding, bottom: 2.0, right: .padding)
            b.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 1.0, constant: 0.0).isActive = true
            b.addTarget(self, action: #selector(didPressButton(_:)), for: .touchUpInside)
            buttons.append(b)
            lastAnchor = b.trailingAnchor
            
        }
        
        buttons.last?.trailingAnchor.constraint(equalTo: containterView.trailingAnchor, constant:-.padding).isActive = true
     }
    @objc func didPressButton(_ sender:Any){
        if let button = sender as? DiscoverFilterButton {
            self.selectedCategory = button.tagCategory
            self.buttons.forEach { $0.isSelected = (self.selectedCategory == $0.tagCategory)}
            self.sendActions(for: .valueChanged)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
