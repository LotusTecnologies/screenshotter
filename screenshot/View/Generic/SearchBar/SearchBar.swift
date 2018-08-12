//
//  SearchBar.swift
//  Screenshop
//
//  Created by Corey Werner on 7/31/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class SearchBar: UISearchBar {
    var textField: UITextField?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        textField = value(forKey: "searchBarTextField") as? UITextField
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setShowsCancelButton(_ showsCancelButton: Bool, animated: Bool) {
        super.setShowsCancelButton(false, animated: false)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let textField = textField {
            let barButtonItemSpacing: CGFloat = 70
            
            var textFieldFrame = textField.frame
            textFieldFrame.size.width = UIScreen.main.bounds.width - (barButtonItemSpacing * 2)
            textFieldFrame.origin.x = barButtonItemSpacing - frame.origin.x
            textField.frame = textFieldFrame
        }
    }
}
