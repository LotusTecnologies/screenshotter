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
    let gender:ProductsOptionsGender = {
        if let genderNumber = UserDefaults.standard.value(forKey: UserDefaultsKeys.productGender) as? NSNumber {
            return ProductsOptionsGender.init(intValue: genderNumber.intValue)
        }
        return .auto
    }()
    var updatedGender:ProductsOptionsGender?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updatedGender = gender
        
        maleButton.setImage(UIImage.init(named: "man"), for: .normal)
        maleButton.imageView?.contentMode = .scaleAspectFit
        maleButton.contentEdgeInsets = UIEdgeInsetsMake(5.0, 10.0, 5.0, 10.0)
        maleButton.layer.cornerRadius = 5.0
        maleButton.layer.borderColor = UIColor.lightGray.cgColor
        maleButton.layer.borderWidth = 1.0
        maleButton.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(maleButton)
        
        femaleButton.setImage(UIImage.init(named: "woman"), for: .normal)
        femaleButton.imageView?.contentMode = .scaleAspectFit
        femaleButton.contentEdgeInsets = UIEdgeInsetsMake(5.0, 10.0, 5.0, 10.0)
        femaleButton.layer.cornerRadius = 5.0
        femaleButton.layer.borderColor = UIColor.lightGray.cgColor
        femaleButton.layer.borderWidth = 1.0
        femaleButton.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(femaleButton)
        
        
        
        maleButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: .padding).isActive = true
        femaleButton.leadingAnchor.constraint(equalTo: maleButton.trailingAnchor, constant: .padding).isActive = true
        femaleButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -.padding).isActive = true

        femaleButton.heightAnchor.constraint(equalTo: femaleButton.widthAnchor).isActive = true
        maleButton.heightAnchor.constraint(equalTo: maleButton.widthAnchor).isActive = true

        maleButton.widthAnchor.constraint(equalTo: femaleButton.widthAnchor).isActive = true
        maleButton.heightAnchor.constraint(equalTo: femaleButton.heightAnchor).isActive = true
        
        maleButton.topAnchor.constraint(equalTo: self.view.topAnchor, constant: .padding).isActive = true
        femaleButton.topAnchor.constraint(equalTo: self.view.topAnchor, constant: .padding).isActive = true


        

        func addLabel(text:String, belowView:UIView){
            let label = UILabel.init()
            label.text = text
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            label.numberOfLines = 2
            self.view.addSubview(label)
            label.topAnchor.constraint(equalTo: belowView.bottomAnchor, constant: 5.0).isActive = true
            label.centerXAnchor.constraint(equalTo: belowView.centerXAnchor).isActive = true
        }
        addLabel(text: "Man", belowView: maleButton)
        addLabel(text: "Woman", belowView: femaleButton)

        
        maleButton.addTarget(self, action: #selector(buttonPress(_:)), for: .touchUpInside)
        femaleButton.addTarget(self, action: #selector(buttonPress(_:)), for: .touchUpInside)
        syncViews()
    }
    
    func syncViews(){
        
       

        femaleButton.layer.borderColor = UIColor.lightGray.cgColor
        femaleButton.layer.borderWidth = 1.0
        maleButton.layer.borderColor = UIColor.lightGray.cgColor
        maleButton.layer.borderWidth = 1.0

        if updatedGender == .male {
            maleButton.layer.borderColor = UIColor.red.cgColor
            maleButton.layer.borderWidth = 3.0
        }else if updatedGender == .female {
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
                    self.updatedGender = .auto
                }else{
                    self.updatedGender = genderOfButton
                }
                syncViews()
            }
            
           

        }
        
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let width =  UIScreen.main.bounds.size.width * 0.9
        let itemSize = (width - .padding * 3) / 2
        let height = itemSize + .padding * 2 + .extendedPadding
        self.preferredContentSize = CGSize.init(width:width, height: height)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    

}
