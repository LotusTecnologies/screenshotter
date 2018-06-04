//
//  ProductDetailViewController.swift
//  screenshot
//
//  Created by Jonathan Rose on 6/4/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import SDWebImage
import Hero
class ProductDetailViewController: UIViewController{

    var product:Product?
    
    var productImageView:UIImageView =  UIImageView()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.hero.isEnabled = true
        self.view.backgroundColor = .white
        self.title = product?.productTitle()
        if let imageURL = product?.imageURL {
            productImageView.sd_setImage(with: URL.init(string: imageURL), completed: nil)
        }
        productImageView.contentMode = .scaleAspectFit
        productImageView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(productImageView)
        
        productImageView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant:.padding).isActive = true
        productImageView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor, constant:.padding).isActive = true
        productImageView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.5).isActive = true
        productImageView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        productImageView.widthAnchor.constraint(equalToConstant: 100).isActive = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
