//
//  DiscoverGenderOptionViewController.swift
//  screenshot
//
//  Created by Jonathan Rose on 7/15/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class DiscoverGenderOptionViewController: UIViewController {

    var femaleButton = UIButton()
    var maleButton = UIButton()
    override func viewDidLoad() {
        super.viewDidLoad()

        femaleButton.setImage(UIImage.init(named: "woman"), for: .normal)
        femaleButton.contentEdgeInsets = UIEdgeInsetsMake(5.0, 10.0, 5.0, 10.0)
        femaleButton.layer.cornerRadius = 5.0
        femaleButton.layer.borderColor = UIColor.lightGray.cgColor
        femaleButton.layer.borderWidth = 1.0
        femaleButton.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(femaleButton)
        femaleButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: .padding).isActive = true
        femaleButton.topAnchor.constraint(equalTo: self.view.topAnchor, constant: .padding).isActive = true
        femaleButton.heightAnchor.constraint(equalTo: femaleButton.widthAnchor).isActive = true
        
        maleButton.setImage(UIImage.init(named: "man"), for: .normal)
        maleButton.contentEdgeInsets = UIEdgeInsetsMake(5.0, 10.0, 5.0, 10.0)
        maleButton.layer.cornerRadius = 5.0
        maleButton.layer.borderColor = UIColor.lightGray.cgColor
        maleButton.layer.borderWidth = 1.0
        maleButton.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(maleButton)
        maleButton.leadingAnchor.constraint(equalTo: femaleButton.trailingAnchor, constant: .padding).isActive = true
        maleButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -.padding).isActive = true
        maleButton.topAnchor.constraint(equalTo: self.view.topAnchor, constant: .padding).isActive = true
        maleButton.heightAnchor.constraint(equalTo: maleButton.widthAnchor).isActive = true
        maleButton.widthAnchor.constraint(equalTo: femaleButton.widthAnchor).isActive = true
        maleButton.heightAnchor.constraint(equalTo: femaleButton.heightAnchor).isActive = true

        maleButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant:-.padding).isActive = true
        femaleButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant:-.padding).isActive = true

        
        maleButton.addTarget(self, action: #selector(buttonPress(_:)), for: .touchUpInside)
        femaleButton.addTarget(self, action: #selector(buttonPress(_:)), for: .touchUpInside)
        syncViews()
    }
    
    func syncViews(){
        
        let gender:ProductsOptionsGender = {
            if let genderNumber = UserDefaults.standard.value(forKey: UserDefaultsKeys.productGender) as? NSNumber {
                return ProductsOptionsGender.init(intValue: genderNumber.intValue)
            }
            return .auto
        }()

        femaleButton.layer.borderColor = UIColor.lightGray.cgColor
        femaleButton.layer.borderWidth = 1.0
        maleButton.layer.borderColor = UIColor.lightGray.cgColor
        maleButton.layer.borderWidth = 1.0

        if gender == .male {
            maleButton.layer.borderColor = UIColor.red.cgColor
            maleButton.layer.borderWidth = 3.0
            
        }else if gender == .female {
            femaleButton.layer.borderColor = UIColor.red.cgColor
            femaleButton.layer.borderWidth = 3.0
        }
        
    }
    
    @objc func buttonPress(_ sender:Any){
        if let sender = sender as? UIButton {
            let gender:ProductsOptionsGender = {
                if let genderNumber = UserDefaults.standard.value(forKey: UserDefaultsKeys.productGender) as? NSNumber {
                    return ProductsOptionsGender.init(intValue: genderNumber.intValue)
                }
                return .auto
            }()
            
            var genderOfButton:ProductsOptionsGender?
            if sender == femaleButton {
                genderOfButton = .female
            }else if sender == maleButton{
                genderOfButton = .male
            }
            
            if let genderOfButton = genderOfButton {
                
                if gender == genderOfButton {
                    UserDefaults.standard.set(ProductsOptionsGender.auto.rawValue, forKey: UserDefaultsKeys.productGender)
                }else{
                    UserDefaults.standard.set(genderOfButton.rawValue, forKey: UserDefaultsKeys.productGender)
                }
                syncViews()
            }
            
           

        }
        
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        var size = self.view.systemLayoutSizeFitting(UILayoutFittingCompressedSize, withHorizontalFittingPriority: .defaultLow, verticalFittingPriority: .defaultHigh)
        let minWidth = UIScreen.main.bounds.size.width * 0.9
        if size.width < minWidth {
            size.width = minWidth
        }
        
        self.preferredContentSize = size
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    

}
