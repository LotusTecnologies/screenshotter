//
//  ErrorNotRetryableCollectionViewCell.swift
//  screenshot
//
//  Created by Jonathan Rose on 5/9/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class ErrorNotRetryableCollectionViewCell: UICollectionViewCell {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .orange
    }
}
