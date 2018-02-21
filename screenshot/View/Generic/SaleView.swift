//
//  SaleView.swift
//  screenshot
//
//  Created by Corey Werner on 2/18/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import UIKit

class SaleView: UIImageView {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init() {
        self.init(frame: .zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let padding: CGFloat = 6
        let resizableImageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 4)
        
        image = UIImage(named: "ProductSaleBanner")?.resizableImage(withCapInsets: resizableImageInsets)
        layoutMargins = UIEdgeInsets(top: 0, left: padding, bottom: 0, right: padding + resizableImageInsets.right)
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 10)
        label.textAlignment = .center
        label.text = "generic.sale".localized
        addSubview(label)
        label.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        label.topAnchor.constraint(equalTo: topAnchor).isActive = true
        label.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        label.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    }
}
