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
        var genderName:String

        var color:UIColor

        static func getFromFile() -> [TagCategory] {
            func parse(data:Data) -> [TagCategory]? {
                do {
                    var toReturn:[TagCategory] = []
                    if let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [[String:Any]] {
                        for dict in json {
                            if let displayName = dict["displayName"] as? String,
                                let filterName = dict["filterName"] as? String,
                                let genderName = dict["genderName"] as? String,
                                let colorString = dict["color"] as? String{
                                let color = UIColor.init(hex: colorString)
                                toReturn.append(TagCategory.init(displayName: displayName, filterName: filterName, genderName:genderName, color: color))
                            }
                        }
                        
                    }
                    return toReturn
                }catch{
                    return nil
                }
                
            }
            if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let dbURL = documentDirectory.appendingPathComponent("DiscoverFilterCategories.json")
                
                if let data = try? Data.init(contentsOf: dbURL),  let result =  parse(data: data), result.count > 0  {
                    return result
                }
            }
            if let bundleUrl = Bundle.main.url(forResource: "DiscoverFilterCategories", withExtension: "json"), let data = try? Data.init(contentsOf: bundleUrl), let result =  parse(data: data) {
                return result
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
            if t.genderName == "" && t.filterName == "" {
                return t
            }
        }
        
        if let t =  self.allTagCategories.first{
            return t
        }
        return TagCategory.init(displayName: "All", filterName: "", genderName: "", color: UIColor.init(hex: "E62A41"))
        
    }()
    func selectAllFilter(){
        if let all = self.allTagCategories.first(where: {$0.filterName == "" && $0.genderName == "" } ) {
            self.scrollView.setContentOffset(.zero, animated: true)
            self.selectedCategory = all
            self.buttons.forEach { $0.isSelected = (self.selectedCategory == $0.tagCategory)}
        }
        
    }
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
            if t == self.selectedCategory {
                b.isSelected = true
            }
            buttons.append(b)
            lastAnchor = b.trailingAnchor
            
        }
        
        buttons.last?.trailingAnchor.constraint(equalTo: containterView.trailingAnchor, constant:-.padding).isActive = true
        
       
     }
    func scrollToSelected(){
       if let b = self.buttons.first(where:{ $0.isSelected} ) {
        let visibleRect = b.frame
        let frame = self.bounds
        let x = visibleRect.origin.x + visibleRect.size.width/2.0 - frame.size.width/2.0
        let maxX = scrollView.contentSize.width - frame.width
        
        let centeredRect = CGRect.init(
            x: min(x, maxX),
            y: 0,
            width:  frame.size.width,
            height:  frame.size.height)

            scrollView.scrollRectToVisible(centeredRect, animated: false)
        }
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
